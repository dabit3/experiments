import { createServer } from 'node:http';
import { randomBytes } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { Arena, fighter } from './combat.mjs';

export function createGameServer({ port = 8787, host = '0.0.0.0', log = console.log } = {}) {
  const rooms = new Map();
  const identities = new Map();
  const http = createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ game: 'Nova Brawl', protocol: 1, rooms: rooms.size }));
  });
  const wss = new WebSocketServer({ server: http, maxPayload: 4096 });
  const send = (ws, msg) => { if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(msg)); };
  const error = (ws, message) => send(ws, { type: 'error', message });
  const audit = e => log(JSON.stringify({ at: Date.now(), ...e }));
  wss.on('connection', ws => {
    ws.alive = true;
    ws.on('pong', () => { ws.alive = true; });
    let identity;
    let windowAt = Date.now(), messages = 0;
    const joinTimeout = setTimeout(() => { if (!identity) ws.close(1008, 'Join required'); }, 10000);
    ws.on('message', raw => {
      if (Date.now() - windowAt > 1000) { messages = 0; windowAt = Date.now(); }
      if (++messages > 90) { ws.close(1008, 'Rate limit'); return; }
      let msg;
      try { msg = JSON.parse(raw.toString()); } catch { error(ws, 'Invalid JSON'); return; }
      if (!msg || typeof msg !== 'object' || Array.isArray(msg)) return;
      if (msg.type === 'join') {
        if (identity) return;
        const code = typeof msg.code === 'string' ? msg.code.toUpperCase().trim() : '';
        const name = typeof msg.name === 'string' ? msg.name.trim().slice(0, 16) : '';
        if (!/^[A-Z0-9]{4,8}$/.test(code) || !name) { error(ws, 'Use a 4–8 letter/number room and a guest name.'); return; }
        const existing = typeof msg.token === 'string' ? identities.get(msg.token) : null;
        if (existing && existing.room.code === code && rooms.get(code) === existing.room) {
          identity = existing;
          if (identity.ws && identity.ws !== ws) identity.ws.close(1000, 'Reconnected elsewhere');
          identity.ws = ws;
          identity.disconnectedAt = 0;
          const p = identity.room.players.find(p => p.id === identity.id);
          p.connected = true;
          p.seq = -1;
          p.inputAt = identity.room.tick;
          identity.room.event('rejoin', { player: p.id });
        } else {
          if (!rooms.has(code)) {
            if (msg.create !== true) { error(ws, 'Room not found. Ask your friend for their code.'); return; }
            if (rooms.size >= 64) { error(ws, 'Server full. Try later.'); return; }
            rooms.set(code, new Arena(code, audit));
          } else if (msg.create === true) {
            error(ws, 'Room already exists. Use Join room.'); return;
          }
          const room = rooms.get(code);
          if (room.players.length >= 2) { error(ws, 'Room is full (2 players).'); return; }
          const id = randomBytes(8).toString('hex');
          const token = randomBytes(24).toString('hex');
          identity = { id, token, room, ws, disconnectedAt: 0 };
          identities.set(token, identity);
          const slot = [0, 1].find(slot => !room.players.some(p => p.slot === slot));
          room.players.push(fighter(id, name, slot));
          room.event('join', { player: id, name });
        }
        clearTimeout(joinTimeout);
        send(ws, { type: 'welcome', id: identity.id, token: identity.token, code });
        send(ws, identity.room.snapshot());
      } else if (identity) {
        const p = identity.room.players.find(p => p.id === identity.id);
        if (!p || identity.ws !== ws) return;
        if (msg.type === 'input') identity.room.input(p, msg);
        if (msg.type === 'ready') identity.room.ready(p);
        if (msg.type === 'ping') send(ws, { type: 'pong', client: msg.client, server: Date.now() });
      }
    });
    ws.on('error', () => {});
    ws.on('close', () => {
      clearTimeout(joinTimeout);
      if (identity && identity.ws === ws) {
        identity.ws = null;
        identity.disconnectedAt = Date.now();
        const p = identity.room.players.find(p => p.id === identity.id);
        if (p) { p.connected = false; p.ready = false; }
        identity.room.event('disconnect', { player: identity.id });
      }
    });
  });
  const interval = setInterval(() => {
    for (const room of rooms.values()) {
      room.step();
      if (room.tick % 2 === 0) {
        const state = room.snapshot();
        for (const identity of identities.values()) if (identity.room === room && identity.ws) send(identity.ws, state);
      }
      if (room.tick % 90 === 0 && room.phase === 'playing') {
        audit({ type: 'checkpoint', room: room.code, round: room.round, tick: room.tick,
          players: room.players.map(p => ({ id: p.id, hp: p.hp, energy: p.energy, pos: p.pos, hits: p.hits, mode: p.mode })) });
      }
    }
    for (const [token, identity] of identities) {
      if (identity.disconnectedAt && Date.now() - identity.disconnectedAt > 30000) {
        const room = identity.room;
        if (['playing', 'countdown'].includes(room.phase)) {
          room.finish(room.players.find(p => p.id !== identity.id)?.id || '', 'DISCONNECT');
        }
        room.players = room.players.filter(p => p.id !== identity.id);
        identities.delete(token);
        if (!room.players.length) rooms.delete(room.code);
      }
    }
  }, 1000 / 30);
  const heartbeat = setInterval(() => {
    for (const ws of wss.clients) {
      if (!ws.alive) ws.terminate();
      else { ws.alive = false; ws.ping(); }
    }
  }, 10000);
  return {
    rooms, http,
    start: () => new Promise(resolve => http.listen(port, host, () => resolve(http.address()))),
    close: () => new Promise(resolve => {
      clearInterval(interval); clearInterval(heartbeat);
      for (const ws of wss.clients) ws.terminate();
      wss.close(() => http.close(resolve));
    })
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const server = createGameServer({ port: Number(process.env.PORT || 8787) });
  const address = await server.start();
  console.log(JSON.stringify({ type: 'listening', ...address, game: 'Nova Brawl' }));
  for (const signal of ['SIGTERM', 'SIGINT']) process.on(signal, async () => { await server.close(); process.exit(0); });
}
