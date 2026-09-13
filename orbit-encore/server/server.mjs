import http from 'node:http';
import { randomBytes } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { charts } from './charts.mjs';
import { createPerformance, advance, input, publicPerformance } from './engine.mjs';

export function createServer({ port = 8788, log = console.log, now = Date.now } = {}) {
  const rooms = new Map();
  const httpServer = http.createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ app: 'Orbit Encore', rooms: rooms.size, status: 'ok' }));
  });
  const wss = new WebSocketServer({ server: httpServer, maxPayload: 4096 });
  const send = (ws, data) => { if (ws?.readyState === WebSocket.OPEN) ws.send(JSON.stringify(data)); };
  const state = room => ({
    type: 'state', room: room.code, phase: room.phase, songID: room.chart.id,
    startAt: room.startAt, serverTime: now(), matchID: room.matchID,
    players: room.players.map(p => ({ id: p.id, name: p.name, ready: p.ready,
      connected: p.ws?.readyState === WebSocket.OPEN, ...publicPerformance(p.performance) })),
  });
  const broadcast = room => room.players.forEach(p => send(p.ws, state(room)));
  const audit = (event, data) => log(JSON.stringify({ event, at: now(), ...data }));
  wss.on('connection', ws => {
    let currentRoom;
    let currentPlayer;
    let messages = 0;
    let intervalStart = now();
    ws.on('message', raw => {
      if (now() - intervalStart > 1000) { messages = 0; intervalStart = now(); }
      if (++messages > 240) return ws.close(1008, 'Input rate exceeded');
      let message;
      try { message = JSON.parse(raw.toString()); } catch { return send(ws, { type: 'error', message: 'Invalid JSON' }); }
      if (!message || typeof message !== 'object') return;
      const fail = text => send(ws, { type: 'error', message: text });
      if (message.type === 'ping') return send(ws, { type: 'pong', sentAt: message.sentAt, serverTime: now() });
      if (message.type === 'join') {
        if (currentRoom) return fail('Already in a room');
        const code = String(message.room ?? '').trim().toUpperCase();
        let room = code ? rooms.get(code) : undefined;
        if (code && !room) return fail('Room not found. Check the six-letter code.');
        if (!room) {
          if (rooms.size >= 100) return fail('Server is full');
          let newCode;
          do { newCode = randomBytes(3).toString('hex').toUpperCase(); } while (rooms.has(newCode));
          room = { code: newCode, chart: charts[0], phase: 'lobby', startAt: 0,
            matchID: 0, players: [], touchedAt: now() };
          rooms.set(room.code, room);
        }
        let player = room.players.find(p => p.token === message.token && typeof message.token === 'string');
        if (player) {
          if (player.ws?.readyState === WebSocket.OPEN) return fail('Guest already connected');
          player.ws = ws;
        } else {
          if (room.players.length >= 2) return fail('Room is full (two players)');
          if (room.phase !== 'lobby') return fail('Match already started');
          player = { id: randomBytes(8).toString('hex'), token: randomBytes(24).toString('hex'),
            name: String(message.name ?? 'Guest').trim().slice(0, 18) || 'Guest',
            ws, ready: false, performance: createPerformance(room.chart) };
          room.players.push(player);
        }
        currentRoom = room;
        currentPlayer = player;
        room.touchedAt = now();
        send(ws, { type: 'joined', id: player.id, token: player.token, room: room.code, charts });
        audit('join', { room: room.code, player: player.id, name: player.name });
        broadcast(room);
        return;
      }
      if (!currentRoom || !currentPlayer) return fail('Join a room first');
      const room = currentRoom;
      room.touchedAt = now();
      if (message.type === 'select') {
        if (room.players[0] !== currentPlayer || room.phase !== 'lobby') return fail('Only host can select in lobby');
        const chart = charts.find(c => c.id === message.songID);
        if (!chart) return fail('Unknown song');
        room.chart = chart;
        room.players.forEach(p => { p.ready = false; p.performance = createPerformance(chart); });
      } else if (message.type === 'ready') {
        if (room.phase !== 'lobby') return;
        currentPlayer.ready = message.ready === true;
        if (room.players.length === 2 && room.players.every(p => p.ready && p.ws?.readyState === WebSocket.OPEN)) {
          room.phase = 'playing';
          room.matchID++;
          room.startAt = now() + 5000;
          room.players.forEach(p => { p.performance = createPerformance(room.chart); });
          audit('start', { room: room.code, matchID: room.matchID, startAt: room.startAt, songID: room.chart.id });
        }
      } else if (message.type === 'input') {
        if (room.phase !== 'playing' || message.matchID !== room.matchID) return;
        const wall = now();
        if (!Number.isFinite(message.at) || Math.abs(message.at - wall) > 300) return;
        const time = (message.at - room.startAt) / 1000;
        if (time < 0 || time > room.chart.duration + 1) return;
        const previous = currentPlayer.performance.judged;
        input(currentPlayer.performance, room.chart, message, time);
        if (currentPlayer.performance.judged > previous) {
          audit('judgment', { room: room.code, matchID: room.matchID, player: currentPlayer.id,
            score: currentPlayer.performance.score, judgment: currentPlayer.performance.lastJudgment });
        }
        return;
      } else if (message.type === 'rematch') {
        if (room.phase !== 'results') return;
        currentPlayer.ready = true;
        if (room.players.length === 2 && room.players.every(p => p.ready && p.ws?.readyState === WebSocket.OPEN)) {
          room.phase = 'lobby';
          room.players.forEach(p => { p.ready = false; p.performance = createPerformance(room.chart); });
          audit('rematch', { room: room.code, matchID: room.matchID });
        }
      } else if (message.type === 'leave') {
        if (room.phase === 'playing') {
          currentPlayer.ws = null;
          ws.close();
          return;
        }
        room.players = room.players.filter(p => p !== currentPlayer);
        currentRoom = null;
        currentPlayer = null;
        if (!room.players.length) rooms.delete(room.code);
        send(ws, { type: 'left' });
      }
      broadcast(room);
    });
    ws.on('close', () => {
      if (currentPlayer?.ws === ws) {
        currentPlayer.ws = null;
        currentPlayer.ready = false;
        currentPlayer.performance.touches.clear();
        audit('disconnect', { room: currentRoom.code, player: currentPlayer.id });
        broadcast(currentRoom);
      }
    });
    ws.on('error', () => {});
  });
  const timer = setInterval(() => {
    for (const room of rooms.values()) {
      if (room.phase === 'playing') {
        const time = (now() - room.startAt) / 1000;
        // Keep a 300 ms admission buffer so normal network delay does not preempt timestamped inputs.
        room.players.forEach(p => advance(p.performance, room.chart, time - 0.30));
        if (time > room.chart.duration + 0.5) {
          room.phase = 'results';
          room.players.forEach(p => { p.ready = false; });
          audit('results', { room: room.code, matchID: room.matchID, players: state(room).players });
        }
        broadcast(room);
      }
      if (room.players.every(p => p.ws?.readyState !== WebSocket.OPEN) && now() - room.touchedAt > 120000) {
        rooms.delete(room.code);
      }
    }
  }, 33);
  httpServer.listen(port, '0.0.0.0');
  return { rooms, httpServer, wss, close: () => {
    clearInterval(timer);
    for (const client of wss.clients) client.terminate();
    wss.close();
    return new Promise(resolve => httpServer.close(resolve));
  } };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.PORT ?? 8788);
  createServer({ port });
  console.log(`Orbit Encore listening on ws://0.0.0.0:${port}`);
}
