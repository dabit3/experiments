import http from 'node:http';
import fs from 'node:fs';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { newPlayer, units, advance, input, publicPlayer } from './engine.mjs';

export const charts = JSON.parse(fs.readFileSync(new URL('../Assets/charts.json', import.meta.url)));
export function startServer(port = 8769, host = '0.0.0.0') {
  const rooms = new Map();
  const peers = new Map();
  const server = http.createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ app: 'Skyline Pulse', rooms: rooms.size, protocol: 1 }));
  });
  const wss = new WebSocketServer({ server, maxPayload: 4096 });
  const send = (ws, value) => { if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(value)); };
  const snapshot = (room) => ({
    type: 'state', room: room.code, phase: room.phase, song: room.song, startAt: room.startAt,
    round: room.round, host: room.host, now: Date.now(),
    players: [...room.players.values()].map(publicPlayer),
  });
  const broadcast = (room) => {
    const state = snapshot(room);
    for (const p of room.players.values()) if (p.ws) send(p.ws, state);
  };
  const fail = (ws, message) => send(ws, { type: 'error', message });
  const log = (type, data) => console.log(JSON.stringify({ type, at: Date.now(), ...data }));
  const begin = (room) => {
    room.phase = 'playing'; room.round++; room.startAt = Date.now() + 4000;
    room.queue = []; room.units = units(charts.find((s) => s.id === room.song));
    for (const [id, previous] of room.players) {
      const player = { ...newPlayer(id, previous.name), ws: previous.ws, token: previous.token };
      room.players.set(id, player);
    }
    log('start', { room: room.code, round: room.round, song: room.song, startAt: room.startAt });
  };
  wss.on('connection', (ws) => {
    let peer = null;
    let recent = [];
    ws.on('message', (raw) => {
      let m;
      try { m = JSON.parse(raw.toString()); } catch { return fail(ws, 'Invalid JSON'); }
      if (!m || typeof m !== 'object') return;
      const now = Date.now();
      recent = recent.filter((t) => now - t < 1000);
      if (recent.length > 300) return fail(ws, 'Input rate exceeded');
      recent.push(now);
      if (m.type === 'ping') return send(ws, { type: 'pong', sent: m.sent, now });
      if (m.type === 'join') {
        if (peer) return fail(ws, 'Already joined');
        if (typeof m.name !== 'string' || !m.name.trim() || m.name.length > 20) return fail(ws, 'Guest name must be 1–20 characters');
        let room = rooms.get(String(m.room || '').toUpperCase());
        if (m.create) {
          if (rooms.size >= 100) return fail(ws, 'Server room limit reached');
          const code = crypto.randomBytes(3).toString('hex').toUpperCase();
          room = { code, host: '', song: 'neon', phase: 'lobby', startAt: 0, round: 0, players: new Map(), queue: [], touched: now };
          rooms.set(code, room);
        }
        if (!room) return fail(ws, 'Room not found');
        let player = [...room.players.values()].find((p) => p.token === m.token && typeof m.token === 'string');
        if (!player) {
          if (room.players.size >= 2) return fail(ws, 'Room is full');
          if (room.phase === 'playing') return fail(ws, 'Match already started');
          const id = crypto.randomUUID();
          player = { ...newPlayer(id, m.name.trim()), token: crypto.randomBytes(24).toString('hex'), ws };
          room.players.set(id, player);
          if (!room.host) room.host = id;
        } else {
          if (player.ws && player.connected) player.ws.close(4000, 'Rejoined');
          player.ws = ws; player.connected = true; player.pointers.clear();
        }
        peer = { room, id: player.id }; peers.set(ws, peer); room.touched = now;
        send(ws, { type: 'joined', id: player.id, token: player.token, room: room.code });
        broadcast(room);
        log('join', { room: room.code, id: player.id, name: player.name });
        return;
      }
      if (!peer) return fail(ws, 'Join a room first');
      const { room, id } = peer;
      const player = room.players.get(id);
      room.touched = now;
      if (m.type === 'song' && room.phase !== 'playing') {
        if (id !== room.host) return fail(ws, 'Only host can select a song');
        if (!charts.some((s) => s.id === m.song)) return fail(ws, 'Unknown song');
        room.song = m.song;
        for (const p of room.players.values()) p.ready = false;
      } else if (m.type === 'ready' && room.phase !== 'playing') {
        player.ready = m.ready === true;
        if (room.players.size === 2 && [...room.players.values()].every((p) => p.ready && p.connected)) begin(room);
      } else if (m.type === 'input' && room.phase === 'playing') {
        if (!Number.isInteger(m.seq) || m.seq <= player.seq || !Number.isFinite(m.at)
          || Math.abs(now - m.at) > 350 || !Number.isFinite(m.x) || m.x < 0 || m.x > 16
          || !Number.isFinite(m.y) || m.y < 0 || m.y > 1
          || !['down', 'move', 'up'].includes(m.action) || typeof m.pointer !== 'string' || m.pointer.length > 48) return;
        player.seq = m.seq;
        if (player.pointers.size >= 10 && !player.pointers.has(m.pointer)) return;
        room.queue.push({ id, time: (m.at - room.startAt) / 1000, x: m.x, y: m.y, action: m.action, pointer: m.pointer });
        return;
      } else if (m.type === 'leave') {
        player.connected = false; player.ws = null; player.pointers.clear();
        peer = null; peers.delete(ws);
        if (room.phase !== 'playing') {
          room.players.delete(id);
          if (room.host === id) room.host = room.players.keys().next().value || '';
        }
      }
      broadcast(room);
    });
    ws.on('close', () => {
      const stored = peers.get(ws);
      if (stored) {
        const player = stored.room.players.get(stored.id);
        if (player?.ws === ws) { player.connected = false; player.ready = false; player.ws = null; player.pointers.clear(); broadcast(stored.room); }
      }
      peers.delete(ws);
    });
    ws.on('error', () => {});
  });
  let ticks = 0;
  const timer = setInterval(() => {
    const now = Date.now();
    for (const room of rooms.values()) {
      if (room.phase === 'playing') {
        const time = (now - room.startAt - 180) / 1000;
        room.queue.sort((a, b) => a.time - b.time);
        while (room.queue.length && room.queue[0].time <= time) {
          const event = room.queue.shift();
          const player = room.players.get(event.id);
          advance(player, room.units, event.time);
          input(player, room.units, event);
        }
        for (const p of room.players.values()) advance(p, room.units, time);
        const chart = charts.find((s) => s.id === room.song);
        if (time > chart.duration) {
          room.phase = 'results';
          for (const p of room.players.values()) { p.ready = false; p.pointers.clear(); }
          log('results', snapshot(room));
          broadcast(room);
        } else if (ticks % 3 === 0) broadcast(room);
      }
      if ([...room.players.values()].every((p) => !p.connected) && now - room.touched > 120000) rooms.delete(room.code);
    }
    ticks++;
  }, 1000 / 60);
  server.listen(port, host, () => log('listening', { port: server.address().port }));
  return { server, wss, rooms, close: async () => {
    clearInterval(timer);
    for (const ws of wss.clients) ws.terminate();
    await new Promise((resolve) => wss.close(resolve));
    await new Promise((resolve) => server.close(resolve));
  } };
}
if (process.argv[1] === fileURLToPath(import.meta.url)) startServer(Number(process.env.PORT || 8769));
