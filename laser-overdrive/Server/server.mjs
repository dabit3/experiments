import { createServer } from 'node:http';
import { readFileSync, appendFileSync } from 'node:fs';
import { randomBytes } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { DuelEngine } from './engine.mjs';

const chart = JSON.parse(readFileSync(new URL('../Resources/chart.json', import.meta.url)));

export function createDuelServer({ port = 8769, startDelay = 4000, logFile } = {}) {
  const engine = new DuelEngine(chart);
  const rooms = new Map();
  const http = createServer((request, response) => {
    response.setHeader('Content-Type', 'application/json');
    if (request.url === '/health') {
      response.end(JSON.stringify({ ok: true, game: 'Laser Overdrive', chart: chart.id, rooms: rooms.size }));
    } else { response.statusCode = 404; response.end('{}'); }
  });
  const wss = new WebSocketServer({ server: http, maxPayload: 4096 });
  const log = (event, values) => {
    const line = JSON.stringify({ at: Date.now(), event, ...values });
    console.log(line);
    if (logFile) appendFileSync(logFile, `${line}\n`);
  };
  const send = (socket, data) => {
    if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(data));
  };
  function state(room) {
    return {
      type: 'state', code: room.code, phase: room.phase, epoch: room.epoch,
      serverNow: Date.now(), startAt: room.startAt, duration: chart.duration,
      players: [...room.players.values()].map(player => engine.snapshot(player)),
    };
  }
  const broadcast = room => {
    const snapshot = state(room);
    for (const player of room.players.values()) if (player.socket) send(player.socket, snapshot);
  };
  wss.on('connection', socket => {
    let room, player;
    let packets = 0;
    let rateStart = Date.now();
    socket.on('error', () => {});
    socket.on('message', raw => {
      if (Date.now() - rateStart > 1000) { packets = 0; rateStart = Date.now(); }
      if (++packets > 180) return socket.close(1008, 'Input rate exceeded');
      let message;
      try { message = JSON.parse(raw.toString()); } catch { return send(socket, { type: 'error', message: 'Invalid JSON' }); }
      if (!message || typeof message !== 'object') return;
      if (message.type === 'ping') return send(socket, { type: 'pong', sent: message.sent, serverNow: Date.now() });
      if (message.type === 'hello' && !player) {
        if (typeof message.id !== 'string' || !/^[\w-]{8,80}$/.test(message.id) ||
            typeof message.token !== 'string' || !/^[\w-]{16,100}$/.test(message.token) ||
            typeof message.name !== 'string' || !message.name.trim() ||
            message.chart !== chart.id) return send(socket, { type: 'error', message: 'Invalid guest or chart version' });
        const code = String(message.code || '').toUpperCase().trim();
        if (code && !/^[A-Z0-9]{4,6}$/.test(code)) return send(socket, { type: 'error', message: 'Use a 4–6 character room code' });
        room = rooms.get(code);
        if (!room && code && !message.create) return send(socket, { type: 'error', message: 'Room not found. Ask the host for its code.' });
        if (!room) {
          if (rooms.size >= 100) return send(socket, { type: 'error', message: 'Server room limit reached' });
          let newCode = code;
          while (!newCode || rooms.has(newCode)) newCode = randomBytes(3).toString('hex').toUpperCase();
          room = { code: newCode, phase: 'lobby', players: new Map(), startAt: 0, epoch: 0, touched: Date.now() };
          rooms.set(newCode, room);
        }
        const existing = room.players.get(message.id);
        if (existing) {
          if (existing.token !== message.token) return send(socket, { type: 'error', message: 'Guest token mismatch' });
          if (existing.socket && existing.socket !== socket) existing.socket.close(1000, 'Rejoined');
          player = existing;
        } else {
          if (room.players.size >= 2 || room.phase === 'playing') return send(socket, { type: 'error', message: 'Room full or match in progress' });
          player = engine.player(message.id, message.name.trim().slice(0, 18));
          player.token = message.token;
          room.players.set(player.id, player);
        }
        player.socket = socket;
        player.connected = true;
        room.touched = Date.now();
        send(socket, { type: 'joined', id: player.id, code: room.code, chart: chart.id, nextSeq: player.seq + 1 });
        log('joined', { room: room.code, id: player.id, name: player.name, epoch: room.epoch });
        return broadcast(room);
      }
      if (!player || !room || player.socket !== socket) return;
      player = room.players.get(player.id);
      if (!player) return;
      room.touched = Date.now();
      if (message.type === 'ready' && room.phase !== 'playing') {
        player.ready = !player.ready;
        log('ready', { room: room.code, id: player.id, ready: player.ready });
        if (room.players.size === 2 && [...room.players.values()].every(p => p.ready && p.connected)) {
          room.epoch++;
          room.startAt = Date.now() + startDelay;
          room.phase = 'playing';
          for (const [id, previous] of room.players) {
            const next = engine.player(id, previous.name);
            Object.assign(next, { token: previous.token, socket: previous.socket, ready: true });
            room.players.set(id, next);
            // Connection closure reads current object on the next message.
          }
          player = room.players.get(player.id);
          log('start', { room: room.code, epoch: room.epoch, startAt: room.startAt, ids: [...room.players.keys()] });
        }
        broadcast(room);
      } else if (message.type === 'input' && room.phase === 'playing' && message.epoch === room.epoch) {
        player = room.players.get(player.id);
        const now = (Date.now() - room.startAt) / 1000;
        if (engine.input(player, message, now) && (player.inputCount % 120 === 0 || message.source === 'touch')) {
          log('input', { room: room.code, epoch: room.epoch, id: player.id, source: message.source,
            kind: message.kind, lane: message.lane, color: message.color, time: message.time,
            score: player.score, inputs: player.inputCount });
        }
      } else if (message.type === 'leave') {
        room.players.get(player.id).socket = undefined;
        room.players.get(player.id).connected = false;
        if (room.phase !== 'playing') room.players.delete(player.id);
        socket.close();
        broadcast(room);
      }
    });
    socket.on('close', () => {
      if (!room || !player) return;
      const current = room.players.get(player.id);
      if (current?.socket === socket) {
        current.connected = false;
        current.ready = false;
        current.socket = undefined;
        current.disconnectedAt = Date.now();
        log('disconnected', { room: room.code, id: player.id });
        broadcast(room);
      }
    });
  });
  const timer = setInterval(() => {
    for (const [code, room] of rooms) {
      if (room.phase === 'playing') {
        const time = (Date.now() - room.startAt) / 1000;
        for (const player of room.players.values()) engine.advance(player, time);
        if (time > chart.duration + 0.2) {
          room.phase = 'results';
          for (const player of room.players.values()) player.ready = false;
          log('result', { room: code, epoch: room.epoch, players: state(room).players });
        }
      } else {
        for (const [id, player] of room.players) {
          if (!player.connected && Date.now() - player.disconnectedAt > 60000) room.players.delete(id);
        }
      }
      broadcast(room);
      if (Date.now() - room.touched > 600000 && ![...room.players.values()].some(p => p.connected)) rooms.delete(code);
    }
  }, 50);
  http.listen(port, '0.0.0.0');
  return {
    http, wss, rooms,
    close: async () => {
      clearInterval(timer);
      for (const socket of wss.clients) socket.terminate();
      await new Promise(resolve => wss.close(resolve));
      await new Promise(resolve => http.close(resolve));
    },
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.PORT || 8769);
  createDuelServer({ port, logFile: process.env.EVENT_LOG });
  console.log(`Laser Overdrive listening on ws://0.0.0.0:${port}`);
}
