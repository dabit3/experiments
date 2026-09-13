import http from 'node:http';
import { randomBytes, randomUUID } from 'node:crypto';
import { appendFileSync } from 'node:fs';
import { WebSocketServer, WebSocket } from 'ws';
import { Game } from './game.mjs';

export function startServer(port = Number(process.env.PORT || 8791), host = '0.0.0.0') {
  const rooms = new Map();
  const clients = new Map();
  const send = (ws, data) => {
    if (ws.readyState === WebSocket.OPEN && ws.bufferedAmount < 1024 * 1024) ws.send(JSON.stringify(data));
  };
  const server = http.createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    if (req.url === '/health') return res.end(JSON.stringify({ ok: true, game: 'Voxel Vanguard', rooms: rooms.size }));
    const match = /^\/rooms\/([A-Z0-9]{4,8})$/.exec(req.url);
    if (match && rooms.has(match[1])) return res.end(JSON.stringify(rooms.get(match[1]).game.snapshot()));
    res.writeHead(404); res.end('{"error":"not found"}');
  });
  const wss = new WebSocketServer({ server, maxPayload: 2048 });
  wss.on('connection', ws => {
    let session = null;
    let count = 0;
    let countAt = Date.now();
    ws.isAlive = true;
    ws.on('pong', () => { ws.isAlive = true; });
    ws.on('message', raw => {
      if (Date.now() - countAt > 1000) { count = 0; countAt = Date.now(); }
      if (++count > 100) return ws.close(1008, 'Input rate exceeded');
      let msg;
      try { msg = JSON.parse(raw.toString()); } catch { return send(ws, { type: 'error', message: 'Malformed JSON' }); }
      if (!msg || typeof msg !== 'object') return;
      if (msg.type === 'hello' && !session) {
        const name = typeof msg.name === 'string' && msg.name.trim() ? msg.name.trim().slice(0, 16) : 'Guest';
        const code = String(msg.code || '').toUpperCase();
        if (msg.resume) {
          const prior = clients.get(msg.resume);
          if (!prior || !rooms.has(prior.code)) return send(ws, { type: 'error', message: 'Session expired. Join a new expedition.' });
          prior.ws?.close(1000, 'Rejoined elsewhere');
          session = prior; session.ws = ws; session.player.connected = true;
          session.player.input = { x: 0, z: 0 };
          send(ws, { type: 'welcome', id: session.player.id, token: msg.resume, code: prior.code, seq: session.player.seq });
        } else {
          if (msg.create) {
            const generated = code || randomBytes(3).toString('hex').toUpperCase();
            if (!/^[A-Z0-9]{4,8}$/.test(generated)) return send(ws, { type: 'error', message: 'Use a 4–8 letter or digit room code.' });
            if (rooms.has(generated)) return send(ws, { type: 'error', message: 'Room already exists. Choose Join.' });
            if (rooms.size >= 64) return send(ws, { type: 'error', message: 'Server is full.' });
            rooms.set(generated, { game: new Game(generated), touched: Date.now() });
            msg.code = generated;
          }
          const selected = String(msg.code || '').toUpperCase();
          const room = rooms.get(selected);
          if (!room) return send(ws, { type: 'error', message: 'Room not found. Ask your friend for the code.' });
          const player = room.game.add(randomUUID(), name);
          if (!player) return send(ws, { type: 'error', message: 'Room is full or already in a match.' });
          const token = randomBytes(24).toString('hex');
          session = { code: selected, player, ws, token };
          clients.set(token, session);
          send(ws, { type: 'welcome', id: player.id, token, code: selected, seq: player.seq });
        }
        return;
      }
      if (!session) return;
      const game = rooms.get(session.code)?.game;
      if (!game) return;
      if (msg.type === 'ready') game.ready(session.player.id);
      if (msg.type === 'input') game.input(session.player.id, msg);
      if (msg.type === 'leave') {
        if (game.phase === 'playing') { game.phase = 'defeat'; game.objective = 'A hero left the expedition'; }
        game.players = game.players.filter(p => p.id !== session.player.id);
        clients.delete(session.token); session = null; ws.close();
      }
    });
    ws.on('close', () => {
      if (session && session.ws === ws) {
        session.player.connected = false;
        session.player.input = { x: 0, z: 0 };
        session.ws = null;
      }
    });
    ws.on('error', () => {});
  });
  const timer = setInterval(() => {
    for (const [code, room] of rooms) {
      room.game.update();
      const state = room.game.snapshot();
      const connected = room.game.players.some(p => p.connected);
      if (connected) room.touched = Date.now();
      for (const session of clients.values()) if (session.code === code && session.ws) send(session.ws, state);
      if (process.env.LOG_PATH && room.game.tick % 4 === 0) {
        appendFileSync(process.env.LOG_PATH, `${JSON.stringify({ at: Date.now(), ...state })}\n`);
      }
      if (Date.now() - room.touched > 120000) {
        rooms.delete(code);
        for (const [token, session] of clients) if (session.code === code) clients.delete(token);
      }
    }
  }, 50);
  const heartbeat = setInterval(() => {
    for (const ws of wss.clients) {
      if (!ws.isAlive) { ws.terminate(); continue; }
      ws.isAlive = false; ws.ping();
    }
  }, 5000);
  server.listen(port, host);
  return {
    server, rooms,
    close: () => {
      clearInterval(timer); clearInterval(heartbeat);
      for (const ws of wss.clients) ws.terminate();
      wss.close(); server.close();
    },
  };
}
if (process.argv[1]?.endsWith('/server.mjs')) {
  const service = startServer();
  service.server.on('listening', () => console.log(`Voxel Vanguard ws://0.0.0.0:${service.server.address().port}`));
}
