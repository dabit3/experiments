import { WebSocketServer, WebSocket } from 'ws';
import { createServer } from 'node:http';
import { randomBytes, randomUUID } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { room, fighter, ready, input, step, snapshot, RATE } from './engine.mjs';

export function startServer(port = 8794, host = '0.0.0.0') {
  const rooms = new Map();
  const server = createServer((req, res) => {
    if (req.url === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ ok: true, game: 'Midnight Channel', rooms: rooms.size }));
    } else { res.writeHead(404); res.end(); }
  });
  const wss = new WebSocketServer({ server, maxPayload: 4096 });
  const send = (ws, obj) => { if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(obj)); };
  wss.on('connection', ws => {
    let current, player, count = 0, windowStart = Date.now();
    ws.on('message', raw => {
      if (Date.now() - windowStart > 1000) { count = 0; windowStart = Date.now(); }
      if (++count > 150) { ws.close(1008, 'Rate limit'); return; }
      try {
        const msg = JSON.parse(raw.toString());
        if (!msg || typeof msg !== 'object') return;
        if (msg.type === 'join' && !player) {
          const code = String(msg.code ?? '').trim().toUpperCase();
          if (!/^[A-Z0-9]{4,8}$/.test(code)) { send(ws, { type: 'error', message: 'Use a room code of 4–8 letters or digits.' }); return; }
          current = rooms.get(code);
          if (!current) {
            if (rooms.size >= 100) { send(ws, { type: 'error', message: 'Server is full.' }); return; }
            current = room(code);
            current.peers = new Map();
            rooms.set(code, current);
          }
          const resumed = current.fighters.find(p => p.resumeToken === msg.token && p.id === msg.playerID);
          if (resumed) {
            const previous = current.peers.get(resumed.id);
            player = resumed;
            current.peers.set(player.id, ws);
            if (previous && previous !== ws) previous.close(1000, 'Rejoined');
            player.connected = true;
            player.disconnectedAt = 0;
            player.axis = 0;
            player.guard = false;
          } else {
            if (current.fighters.length >= 2) { send(ws, { type: 'error', message: 'Room has two fighters. Choose another code.' }); return; }
            player = fighter(randomUUID(), String(msg.name ?? 'Guest').trim().slice(0, 16) || 'Guest', current.fighters.length);
            player.resumeToken = randomBytes(24).toString('hex');
            current.fighters.push(player);
            current.peers.set(player.id, ws);
          }
          current.lastActive = Date.now();
          send(ws, { type: 'welcome', playerID: player.id, token: player.resumeToken, slot: player.slot, lastSeq: player.lastSeq });
          console.log(JSON.stringify({ event: 'join', room: code, player: player.id, name: player.name, resumed: !!resumed }));
          send(ws, publicState(current));
        } else if (player && current.peers.get(player.id) === ws) {
          if (msg.type === 'ready') ready(current, player);
          else if (msg.type === 'input') input(current, player, msg);
          else if (msg.type === 'ping') send(ws, { type: 'pong', sent: msg.sent, now: Date.now() });
          current.lastActive = Date.now();
        }
      } catch { send(ws, { type: 'error', message: 'Invalid protocol message.' }); }
    });
    ws.on('close', () => {
      if (player && current.peers.get(player.id) === ws) {
        player.connected = false; player.axis = 0; player.guard = false; player.queue = [];
        player.disconnectedAt = Date.now();
        current.lastActive = Date.now();
        console.log(JSON.stringify({ event: 'disconnect', room: current.code, player: player.id }));
      }
    });
    ws.on('error', () => {});
  });
  function publicState(r) {
    const state = snapshot(r);
    for (const p of state.fighters) delete p.resumeToken;
    return state;
  }
  const timer = setInterval(() => {
    for (const [code, r] of rooms) {
      const previousEvent = r.eventID;
      step(r);
      if (r.eventID !== previousEvent) {
        for (const e of r.events.filter(e => e.id > previousEvent)) console.log(JSON.stringify({ room: code, ...e }));
      }
      if (r.tick % 2 === 0 || r.fighters.some(p => !p.connected)) {
        const state = publicState(r);
        for (const ws of r.peers.values()) {
          if (ws.bufferedAmount < 128 * 1024) send(ws, state);
        }
      }
      if (r.fighters.every(p => !p.connected) && Date.now() - r.lastActive > 120000) rooms.delete(code);
      else if (r.fighters.some(p => !p.connected && Date.now() - p.disconnectedAt > 120000)) {
        for (const ws of r.peers.values()) { send(ws, { type: 'error', message: 'Peer left. Use a new room code.' }); ws.close(); }
        rooms.delete(code);
      }
    }
  }, 1000 / RATE);
  server.listen(port, host, () => console.log(`Midnight Channel listening on ${host}:${server.address().port}`));
  return { server, rooms, close: async () => {
    clearInterval(timer);
    for (const ws of wss.clients) ws.terminate();
    await new Promise(resolve => wss.close(resolve));
    await new Promise(resolve => server.close(resolve));
  } };
}
if (process.argv[1] === fileURLToPath(import.meta.url)) startServer(Number(process.env.PORT || 8794));
