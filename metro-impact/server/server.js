import http from 'node:http';
import { randomBytes, randomUUID, timingSafeEqual } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { CHARACTERS, fighter, input, makeMatch, neutral, snapshot, step } from './combat.js';

export function createServer({ port = 8743, host = '0.0.0.0', log = console.log } = {}) {
  const rooms = new Map(), peers = new Map();
  const server = http.createServer((req, res) => {
    if (req.url !== '/health') { res.writeHead(404); res.end(); return; }
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ ok: true, rooms: rooms.size, game: 'Metro Impact' }));
  });
  const wss = new WebSocketServer({ server, maxPayload: 4096 });
  const audit = (event, data = {}) => log(JSON.stringify({ at: Date.now(), event, ...data }));
  const send = (ws, data) => { if (ws.readyState === WebSocket.OPEN && ws.bufferedAmount < 128 * 1024) ws.send(JSON.stringify(data)); };
  wss.on('connection', ws => {
    let session = null, count = 0, windowStart = Date.now();
    ws.isAlive = true;
    ws.on('pong', () => { ws.isAlive = true; });
    ws.on('message', raw => {
      if (Date.now() - windowStart > 1000) { windowStart = Date.now(); count = 0; }
      if (++count > 150) { ws.close(1008, 'Input rate exceeded'); return; }
      let msg;
      try { msg = JSON.parse(raw); } catch { send(ws, { type: 'error', message: 'Invalid JSON' }); return; }
      if (!msg || typeof msg !== 'object') return;
      if (msg.type === 'ping') { send(ws, { type: 'pong', sent: msg.sent, time: Date.now() }); return; }
      if (!session) {
        if (msg.type !== 'hello') return;
        const code = typeof msg.room === 'string' ? msg.room.trim().toUpperCase() : '';
        if (code && !/^[A-Z0-9]{4,8}$/.test(code)) { send(ws, { type: 'error', message: 'Use a 4–8 letter/number room code' }); return; }
        const existing = peers.get(msg.playerID);
        if (existing && typeof msg.token === 'string' && /^[a-f0-9]{48}$/.test(msg.token) &&
            timingSafeEqual(Buffer.from(msg.token), Buffer.from(existing.token)) && existing.room.code === code) {
          const old = existing.ws; existing.ws = ws; existing.player.connected = true;
          existing.disconnectedAt = null; session = existing; if (old !== ws) old.close();
          send(ws, { type: 'welcome', playerID: existing.player.id, token: existing.token, room: code, seq: existing.player.seq });
          audit('rejoin', { code, player: existing.player.id }); return;
        }
        if (msg.playerID || msg.token) { send(ws, { type: 'error', message: 'Session expired. Leave and join again.' }); return; }
        if (!Object.hasOwn(CHARACTERS, msg.character)) { send(ws, { type: 'error', message: 'Select a fighter' }); return; }
        const name = typeof msg.name === 'string' ? msg.name.trim().slice(0, 16) : '';
        if (!name) { send(ws, { type: 'error', message: 'Enter a guest name' }); return; }
        let room = rooms.get(code);
        if (msg.create) {
          if (room) { send(ws, { type: 'error', message: 'Room already exists. Choose JOIN.' }); return; }
          if (rooms.size >= 128) { send(ws, { type: 'error', message: 'Server is full' }); return; }
          const newCode = code || randomBytes(3).toString('hex').toUpperCase();
          room = makeMatch(newCode); room.lastActive = Date.now(); rooms.set(newCode, room);
        }
        if (!room) { send(ws, { type: 'error', message: 'Room not found. Check its code.' }); return; }
        if (room.players.length >= 2) { send(ws, { type: 'error', message: 'Room is full' }); return; }
        if (room.phase !== 'waiting') { send(ws, { type: 'error', message: 'Match already started' }); return; }
        const p = fighter(randomUUID(), name, msg.character, room.players.length);
        room.players.push(p);
        session = { player: p, room, token: randomBytes(24).toString('hex'), ws, disconnectedAt: null };
        peers.set(p.id, session);
        send(ws, { type: 'welcome', playerID: p.id, token: session.token, room: room.code, seq: p.seq });
        audit('join', { code: room.code, player: p.id, name, character: p.character });
      } else {
        const { room, player } = session;
        if (session.ws !== ws) return;
        if (msg.type === 'input') input(room, player, msg);
        if (msg.type === 'ready' && room.phase === 'waiting') {
          player.ready = msg.ready === true; audit('ready', { code: room.code, player: player.id, ready: player.ready });
        }
        if (msg.type === 'rematch' && room.phase === 'matchOver') {
          player.rematch = true; audit('rematchVote', { code: room.code, player: player.id });
        }
        if (msg.type === 'leave') {
          if (room.phase === 'waiting') {
            room.players = room.players.filter(p => p !== player);
            room.players.forEach((p, i) => { p.slot = i; p.x = i ? 690 : 270; });
            peers.delete(player.id);
          } else {
            const other = room.players.find(p => p !== player);
            if (other) { room.winner = other.id; room.phase = 'matchOver'; other.wins = 2; }
          }
          ws.close(1000, 'Left room');
        }
      }
    });
    ws.on('close', () => {
      if (session && session.ws === ws) {
        session.player.connected = false; session.player.input = neutral();
        session.disconnectedAt = Date.now();
        audit('disconnect', { code: session.room.code, player: session.player.id });
      }
    });
    ws.on('error', () => {});
  });
  const timer = setInterval(() => {
    for (const room of rooms.values()) {
      const previous = room.phase, oldMatch = room.match;
      step(room);
      if (room.players.some(p => p.connected)) room.lastActive = Date.now();
      if (room.phase !== previous || room.match !== oldMatch) {
        audit('phase', { code: room.code, phase: room.phase, round: room.round, match: room.match,
          winner: room.winner, players: room.players.map(p => ({ id: p.id, hp: p.hp, hits: p.hits, blocks: p.blocks, actions: p.actions, wins: p.wins, damage: p.damageDealt })) });
      }
      if (room.tick % 2 === 0) {
        const state = snapshot(room);
        for (const p of room.players) { const peer = peers.get(p.id); if (peer) send(peer.ws, state); }
      }
      if (Date.now() - room.lastActive > 10 * 60_000) {
        room.players.forEach(p => peers.delete(p.id)); rooms.delete(room.code);
      }
    }
  }, 1000 / 60);
  const heartbeat = setInterval(() => {
    for (const ws of wss.clients) { if (!ws.isAlive) ws.terminate(); else { ws.isAlive = false; ws.ping(); } }
  }, 10_000);
  return {
    rooms, server,
    listen: () => new Promise(resolve => server.listen(port, host, () => { audit('listening', { port: server.address().port }); resolve(server.address().port); })),
    close: () => new Promise(resolve => {
      clearInterval(timer); clearInterval(heartbeat); wss.clients.forEach(ws => ws.terminate()); wss.close(() => server.close(resolve));
    }),
  };
}
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const app = createServer({ port: Number(process.env.PORT || 8743) });
  await app.listen();
  process.on('SIGINT', async () => { await app.close(); process.exit(0); });
}
