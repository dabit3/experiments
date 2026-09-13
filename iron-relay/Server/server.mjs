import http from 'node:http';
import { randomBytes, randomUUID } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { Game, player } from './game.mjs';

export function startServer(port = 8769, host = '0.0.0.0') {
  const rooms = new Map();
  const sockets = new Map();
  const server = http.createServer((req, res) => {
    if (req.url !== '/health') { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ name: 'Iron Relay', rooms: rooms.size, protocol: 1 }));
  });
  const wss = new WebSocketServer({ server, maxPayload: 8192 });
  const send = (ws, body) => {
    if (ws.readyState === WebSocket.OPEN && ws.bufferedAmount < 256_000) ws.send(JSON.stringify(body));
  };
  wss.on('connection', ws => {
    let session;
    let quota = 0;
    let quotaAt = Date.now();
    const error = message => send(ws, { type: 'error', message });
    ws.on('message', raw => {
      if (Date.now() - quotaAt > 1000) { quota = 0; quotaAt = Date.now(); }
      if (++quota > 100) { ws.close(1008, 'Input rate exceeded'); return; }
      let data;
      try { data = JSON.parse(raw.toString()); } catch { error('Invalid JSON'); return; }
      if (!data || typeof data !== 'object' || Array.isArray(data)) return;
      if (data.type === 'join' && !session) {
        const code = String(data.code ?? '').trim().toUpperCase();
        const name = String(data.name ?? '').trim().slice(0, 16);
        if (!/^[A-Z0-9]{4,8}$/.test(code) || !name) { error('Use a name and a 4–8 letter/number room code.'); return; }
        let room = rooms.get(code);
        if (!room) {
          if (rooms.size >= 32) { error('Server full. Try again later.'); return; }
          room = { game: new Game(code), tokens: new Map(), touched: Date.now(), absent: new Map() };
          rooms.set(code, room);
        }
        let p = room.game.players.find(peer => room.tokens.get(peer.id) === data.token);
        if (p) {
          const old = sockets.get(p.id);
          if (old) { error('This guest is already connected.'); return; }
          p.online = true;
          room.absent.delete(p.id);
        } else {
          if (room.game.players.length >= 2) { error('Room full. Choose another code.'); return; }
          const team = Array.isArray(data.team) && data.team.length === 2 &&
            data.team.every(v => Number.isInteger(v) && v >= 0 && v < 4) &&
            data.team[0] !== data.team[1] ? data.team : [0, 1];
          p = player(randomUUID(), name, team);
          room.game.players.push(p);
          room.tokens.set(p.id, randomBytes(24).toString('hex'));
        }
        session = { room, p };
        sockets.set(p.id, ws);
        send(ws, { type: 'welcome', id: p.id, token: room.tokens.get(p.id), code, seq: p.seq });
        room.game.event('join', p.id);
        console.log(JSON.stringify({ event: 'join', room: code, id: p.id, name: p.name }));
      } else if (session) {
        const { room, p } = session;
        if (data.type === 'input') room.game.input(p, data);
        if (data.type === 'ready') room.game.ready(p);
        if (data.type === 'rematch') room.game.rematch(p);
        if (data.type === 'ping') send(ws, { type: 'pong', sent: data.sent });
      }
    });
    ws.on('error', () => {});
    ws.on('close', () => {
      if (!session) return;
      const { room, p } = session;
      if (sockets.get(p.id) !== ws) return;
      sockets.delete(p.id);
      p.online = false;
      p.vx = 0; p.vz = 0; p.guard = false;
      room.absent.set(p.id, Date.now());
      room.game.event('disconnect', p.id);
    });
  });
  const interval = setInterval(() => {
    for (const [code, room] of rooms) {
      room.game.step();
      if (room.game.tick % 3 === 0) {
        const state = room.game.snapshot();
        room.game.players.forEach(p => {
          const ws = sockets.get(p.id);
          if (ws) send(ws, state);
        });
      }
      const connected = room.game.players.filter(p => p.online);
      if (connected.length) room.touched = Date.now();
      if (Date.now() - room.touched > 120_000) rooms.delete(code);
      for (const [id, since] of room.absent) {
        if (Date.now() - since < 60_000) continue;
        if (room.game.phase === 'lobby') {
          room.game.players = room.game.players.filter(p => p.id !== id);
          room.tokens.delete(id);
        } else if (room.game.phase !== 'result' && connected.length === 1) {
          room.game.phase = 'result';
          room.game.winner = connected[0].id;
          room.game.event('forfeit', connected[0].id, id);
        }
        room.absent.delete(id);
      }
    }
  }, 1000 / 60);
  server.listen(port, host, () => console.log(`Iron Relay WebSocket arena on ${host}:${server.address().port}`));
  return { server, rooms, async close() {
    clearInterval(interval);
    for (const ws of wss.clients) ws.terminate();
    await new Promise(resolve => wss.close(resolve));
    await new Promise(resolve => server.close(resolve));
  } };
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  startServer(Number(process.env.PORT ?? 8769), process.env.HOST ?? '0.0.0.0');
}
