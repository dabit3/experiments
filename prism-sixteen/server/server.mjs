import http from 'node:http';
import crypto from 'node:crypto';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { newPerformance, hit, sweep, publicPlayer } from './game.mjs';

const catalog = JSON.parse(fs.readFileSync(new URL('../Resources/catalog.json', import.meta.url)));
const roomPattern = /^[A-Z0-9]{4,6}$/;

export function startServer({ port = 43116, now = () => Date.now() / 1000,
  startDelay = 4, logger = console.log } = {}) {
  const rooms = new Map();
  const server = http.createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ app: 'Prism Sixteen', protocol: 1, rooms: rooms.size }));
  });
  const wss = new WebSocketServer({ server, maxPayload: 4096 });
  const send = (socket, data) => {
    if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(data));
  };
  const log = (event, detail = {}) => logger(JSON.stringify({ event, at: now(), ...detail }));
  function state(room) {
    return {
      type: 'state', serverTime: now(),
      room: {
        code: room.code, hostID: room.hostID, phase: room.phase, songID: room.songID,
        difficulty: room.difficulty, round: room.round, startAt: room.startAt,
        players: [...room.players.values()].map(publicPlayer),
        results: room.results,
      },
    };
  }
  const broadcast = room => {
    const message = state(room);
    for (const p of room.players.values()) if (p.connected) send(p.socket, message);
  };
  const chartFor = room => catalog.find(s => s.id === room.songID).charts[room.difficulty];
  function begin(room) {
    room.phase = 'playing';
    room.round++;
    room.results = [];
    room.startAt = now() + startDelay;
    for (const p of room.players.values()) {
      p.performance = newPerformance();
      p.ready = false;
    }
    log('start', { code: room.code, round: room.round, startAt: room.startAt,
      song: room.songID, difficulty: room.difficulty, players: [...room.players.keys()] });
    broadcast(room);
  }
  wss.on('connection', socket => {
    let room;
    let player;
    let messageCount = 0;
    let windowAt = now();
    socket.on('error', () => {});
    socket.on('message', raw => {
      if (now() - windowAt > 1) { windowAt = now(); messageCount = 0; }
      if (++messageCount > 120) return socket.close(1008, 'Rate limit');
      let msg;
      try { msg = JSON.parse(raw.toString()); } catch { return send(socket, { type: 'error', message: 'Invalid JSON' }); }
      if (!msg || typeof msg !== 'object') return;
      const error = message => send(socket, { type: 'error', message });
      if (msg.type === 'ping') {
        if (Number.isFinite(msg.sent)) send(socket, { type: 'pong', sent: msg.sent, serverTime: now() });
        return;
      }
      if (msg.type === 'create' || msg.type === 'join') {
        if (player) return error('Already in a room');
        if (typeof msg.playerID !== 'string' || msg.playerID.length > 64 || msg.playerID.length < 8) return error('Invalid player ID');
        const name = String(msg.name || '').trim().slice(0, 16);
        if (!name) return error('Enter a guest name');
        let code = String(msg.code || '').toUpperCase().trim();
        if (msg.type === 'create') {
          if (rooms.size >= 100) return error('Server room limit reached');
          if (!code) do { code = crypto.randomBytes(3).toString('hex').toUpperCase(); } while (rooms.has(code));
          if (!roomPattern.test(code)) return error('Room codes use 4–6 letters or numbers');
          if (rooms.has(code)) return error('Room already exists. Join it instead.');
          room = { code, hostID: msg.playerID, players: new Map(), phase: 'lobby',
            songID: 'refraction', difficulty: 'ADVANCED', startAt: 0, round: 0, results: [], touched: now() };
          rooms.set(code, room);
        } else {
          room = rooms.get(code);
          if (!room) return error('Room not found');
        }
        const previous = room.players.get(msg.playerID);
        if (previous) {
          if (msg.token !== previous.token) return error('Rejoin token does not match');
          if (previous.connected) previous.socket.close(1000, 'Replaced by reconnect');
          player = previous;
          player.socket = socket;
          player.connected = true;
          player.ready = false;
        } else {
          if (room.players.size >= 2) return error('Room is full (two players)');
          if (room.phase !== 'lobby') return error('Match already in progress');
          player = { id: msg.playerID, name, token: crypto.randomUUID(), socket,
            connected: true, ready: false, performance: newPerformance() };
          room.players.set(player.id, player);
        }
        room.touched = now();
        send(socket, { type: 'welcome', id: player.id, token: player.token, code: room.code,
          lastSequence: player.performance.seq });
        log('join', { code: room.code, player: player.id, name: player.name, rejoin: !!previous });
        broadcast(room);
        return;
      }
      if (!player || !room) return error('Join a room first');
      room.touched = now();
      if (msg.type === 'select') {
        if (room.phase === 'playing' || room.hostID !== player.id) return error('Only the host can select before a match');
        if (!catalog.some(s => s.id === msg.songID) || !['BASIC', 'ADVANCED', 'EXTREME'].includes(msg.difficulty)) return error('Unknown chart');
        room.songID = msg.songID;
        room.difficulty = msg.difficulty;
        for (const p of room.players.values()) p.ready = false;
        broadcast(room);
      } else if (msg.type === 'ready') {
        if (room.phase === 'playing') return;
        player.ready = msg.ready === true;
        if (room.players.size === 2 && [...room.players.values()].every(p => p.ready && p.connected)) begin(room);
        else broadcast(room);
      } else if (msg.type === 'tap') {
        if (room.phase !== 'playing' || msg.round !== room.round || !player.connected) return;
        const judgment = hit(player, chartFor(room), room.startAt, msg, now());
        if (judgment) {
          send(socket, { type: 'judgment', ...judgment });
          log('hit', { code: room.code, round: room.round, player: player.id, ...judgment });
        }
      } else if (msg.type === 'leave') {
        socket.close(1000, 'Left room');
        if (room.phase !== 'playing') {
          room.players.delete(player.id);
          if (room.hostID === player.id) room.hostID = [...room.players.keys()][0] || '';
          if (room.players.size === 0) rooms.delete(room.code);
          else broadcast(room);
        }
      }
    });
    socket.on('close', () => {
      if (!player || !room || player.socket !== socket) return;
      player.connected = false;
      player.ready = false;
      room.touched = now();
      log('disconnect', { code: room.code, player: player.id });
      broadcast(room);
    });
  });
  const interval = setInterval(() => {
    for (const room of rooms.values()) {
      if (room.phase === 'playing') {
        const song = catalog.find(s => s.id === room.songID);
        const final = now() >= room.startAt + song.duration;
        for (const p of room.players.values()) sweep(p, chartFor(room), room.startAt, now(), final);
        if (final) {
          room.phase = 'results';
          room.results = structuredClone([...room.players.values()].map(publicPlayer));
          log('result', { code: room.code, round: room.round,
            players: room.results });
        }
        broadcast(room);
      }
      if ([...room.players.values()].every(p => !p.connected) && now() - room.touched > 120) {
        rooms.delete(room.code);
      }
    }
  }, 50);
  server.listen(port, '0.0.0.0', () => log('listening', { port: server.address().port }));
  return { server, rooms, close: async () => {
    clearInterval(interval);
    for (const client of wss.clients) client.terminate();
    await new Promise(resolve => wss.close(resolve));
    await new Promise(resolve => server.close(resolve));
  } };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  startServer({ port: Number(process.env.PORT || 43116) });
}
