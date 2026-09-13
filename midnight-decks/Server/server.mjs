import http from 'node:http';
import fs from 'node:fs';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { freshStats, processInput, expireNotes, winner, NETWORK_GRACE } from './game.mjs';

const chart = JSON.parse(fs.readFileSync(new URL('../Resources/chart.json', import.meta.url)));
export function createServer({ port = 8317, host = '0.0.0.0', log = console.log, startDelay = 3500 } = {}) {
  const rooms = new Map();
  const server = http.createServer((req, res) => {
    if (req.url === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ name: 'Midnight Decks', rooms: rooms.size, chart: chart.id }));
    } else { res.writeHead(404); res.end(); }
  });
  const wss = new WebSocketServer({ server, maxPayload: 8192 });
  const emit = (socket, data) => {
    if (socket?.readyState === WebSocket.OPEN) socket.send(JSON.stringify(data));
  };
  const audit = (type, data) => log(JSON.stringify({ at: Date.now(), type, ...data }));
  const snapshot = room => ({
    room: room.code, phase: room.phase, startAt: room.startAt, round: room.round,
    winner: room.winner,
    players: room.players.map(p => ({
      id: p.id, name: p.name, online: p.socket?.readyState === WebSocket.OPEN,
      ready: p.ready, seq: p.seq, stats: p.stats,
    })),
  });
  const broadcast = room => {
    const state = snapshot(room);
    for (const p of room.players) emit(p.socket, { type: 'state', state, you: p.id, serverTime: Date.now() });
  };
  const start = room => {
    room.round++;
    room.phase = 'playing';
    room.startAt = Date.now() + startDelay;
    room.winner = '';
    for (const p of room.players) { p.stats = freshStats(chart.notes); p.ready = false; }
    audit('start', { room: room.code, round: room.round, startAt: room.startAt, peers: room.players.map(p => p.id) });
  };
  wss.on('connection', socket => {
    let currentRoom, player;
    let count = 0, countAt = Date.now();
    socket.on('message', raw => {
      if (Date.now() - countAt > 1000) { count = 0; countAt = Date.now(); }
      if (++count > 150) { socket.close(1008, 'Rate limit'); return; }
      try {
        const m = JSON.parse(raw);
        if (!m || typeof m !== 'object') throw Error('Invalid message');
        if (m.type === 'ping') {
          if (!Number.isFinite(m.sent)) throw Error('Invalid clock probe');
          emit(socket, { type: 'pong', sent: m.sent, serverTime: Date.now() }); return;
        }
        if (m.type === 'join') {
          if (player) throw Error('Already joined');
          if (typeof m.name !== 'string' || !m.name.trim() || m.name.length > 20) throw Error('Use a guest name of 1–20 characters');
          const code = String(m.room || '').toUpperCase();
          if (code && !/^[A-Z0-9]{4,6}$/.test(code)) throw Error('Room code needs 4–6 letters or digits');
          if (m.create && !rooms.has(code)) {
            if (rooms.size >= 100) throw Error('Server full');
            const newCode = code || crypto.randomBytes(3).toString('hex').toUpperCase();
            currentRoom = { code: newCode, players: [], phase: 'lobby', round: 0, startAt: 0, winner: '', touched: Date.now() };
            rooms.set(newCode, currentRoom);
          } else {
            if (m.create) throw Error('Room already exists; join it instead');
            currentRoom = rooms.get(code);
          }
          if (!currentRoom) throw Error('Room not found');
          player = currentRoom.players.find(p => typeof m.token === 'string' && m.token === p.token);
          if (player) {
            if (player.socket?.readyState === WebSocket.OPEN) player.socket.close(4001, 'Rejoined elsewhere');
            player.socket = socket;
          } else {
            if (currentRoom.players.length >= 2) throw Error('Room has two DJs');
            if (currentRoom.phase === 'playing') throw Error('Song already playing');
            player = {
              id: crypto.randomUUID(), token: crypto.randomBytes(24).toString('hex'), name: m.name.trim(),
              socket, ready: false, seq: 0, stats: freshStats(chart.notes),
            };
            currentRoom.players.push(player);
          }
          currentRoom.touched = Date.now();
          emit(socket, { type: 'joined', you: player.id, token: player.token, chart, state: snapshot(currentRoom), serverTime: Date.now() });
          audit('join', { room: currentRoom.code, id: player.id, name: player.name });
          broadcast(currentRoom); return;
        }
        if (!player || !currentRoom) throw Error('Join a room first');
        if (m.type === 'ready' && currentRoom.phase !== 'playing') {
          player.ready = !player.ready;
          if (currentRoom.players.length === 2 && currentRoom.players.every(p => p.ready && p.socket?.readyState === WebSocket.OPEN)) start(currentRoom);
          broadcast(currentRoom);
        } else if (m.type === 'input' && currentRoom.phase === 'playing') {
          if (!Number.isSafeInteger(m.seq) || m.seq <= player.seq) return;
          player.seq = m.seq;
          const songTime = Date.now() - currentRoom.startAt;
          if (!Number.isFinite(m.time) || Math.abs(m.time - songTime) > NETWORK_GRACE || songTime < -100) return;
          if (processInput(player.stats, chart, m)) {
            audit('judgment', { room: currentRoom.code, round: currentRoom.round, id: player.id, seq: m.seq, time: m.time, ...player.stats.last, score: player.stats.score });
          }
        } else if (m.type === 'leave') {
          socket.close(1000, 'Left room');
        }
      } catch (error) { emit(socket, { type: 'error', message: error.message }); }
    });
    socket.on('close', () => {
      if (player?.socket === socket) {
        player.socket = null; player.ready = false;
        currentRoom.touched = Date.now();
        audit('disconnect', { room: currentRoom.code, id: player.id });
        broadcast(currentRoom);
      }
    });
    socket.on('error', () => {});
  });
  const timer = setInterval(() => {
    for (const [code, room] of rooms) {
      if (room.phase === 'playing') {
        const t = Date.now() - room.startAt;
        for (const p of room.players) expireNotes(p.stats, chart, t);
        if (t >= chart.duration) {
          room.phase = 'result'; room.winner = winner(room.players); room.touched = Date.now();
          audit('result', { room: code, round: room.round, winner: room.winner, players: room.players.map(p => ({ id: p.id, score: p.stats.score, counts: p.stats.counts, gauge: p.stats.gauge })) });
        }
        broadcast(room);
      }
      if (room.players.every(p => !p.socket) && Date.now() - room.touched > 120000) rooms.delete(code);
    }
  }, 50);
  server.listen(port, host);
  return { server, rooms, wss, close: async () => {
    clearInterval(timer);
    for (const client of wss.clients) client.terminate();
    await new Promise(resolve => wss.close(resolve));
    await new Promise(resolve => server.close(resolve));
  } };
}
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.PORT || 8317);
  createServer({ port });
  console.log(`Midnight Decks listening on ${port}`);
}
