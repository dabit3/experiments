import { createServer } from 'node:http';
import { randomBytes } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { SONGS, chartFor, newPlayer, resetPlayer, applyHit, advanceRoom, publicRoom } from './game.mjs';

export function createFestivalServer({ port = 8786, host = '0.0.0.0', logger = console.log } = {}) {
  const rooms = new Map();
  const sockets = new Map();
  const http = createServer((request, response) => {
    if (request.url === '/health') {
      response.writeHead(200, { 'Content-Type': 'application/json' });
      response.end(JSON.stringify({ ok: true, game: 'Festival Don', rooms: rooms.size }));
    } else { response.writeHead(404); response.end(); }
  });
  const wss = new WebSocketServer({ server: http, maxPayload: 4096 });
  const send = (socket, data) => { if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(data)); };
  const broadcast = room => {
    const state = { type: 'state', now: Date.now(), room: publicRoom(room) };
    room.players.forEach(player => { const socket = sockets.get(player.id); if (socket) send(socket, state); });
  };
  const log = (event, detail) => logger(JSON.stringify({ time: Date.now(), event, ...detail }));

  function detach(socket, explicit = false) {
    const room = rooms.get(socket.roomCode);
    const player = room?.players.find(item => item.id === socket.playerID);
    if (!room || !player || sockets.get(player.id) !== socket) return;
    sockets.delete(player.id);
    player.connected = false;
    player.ready = false;
    room.touched = Date.now();
    if (explicit && room.phase === 'lobby') room.players = room.players.filter(item => item.id !== player.id);
    socket.roomCode = undefined;
    socket.playerID = undefined;
    log('disconnect', { room: room.code, player: player.id });
    if (!room.players.length) rooms.delete(room.code); else broadcast(room);
  }

  wss.on('connection', socket => {
    socket.alive = true;
    socket.on('pong', () => { socket.alive = true; });
    socket.windowStart = Date.now();
    socket.messages = 0;
    socket.on('message', buffer => {
      const now = Date.now();
      if (now - socket.windowStart > 1000) { socket.windowStart = now; socket.messages = 0; }
      if (++socket.messages > 100) { socket.close(1008, 'Rate limit'); return; }
      let message;
      try { message = JSON.parse(buffer.toString()); } catch { send(socket, { type: 'error', message: 'Invalid JSON' }); return; }
      if (!message || typeof message !== 'object') return;
      const error = text => send(socket, { type: 'error', message: text });
      if (message.type === 'ping') { send(socket, { type: 'pong', sent: message.sent, now }); return; }
      if (message.type === 'hello') { send(socket, { type: 'catalog', songs: SONGS, now }); return; }
      if (message.type === 'leave') { detach(socket, true); send(socket, { type: 'left' }); return; }
      if (message.type === 'create' || message.type === 'join') {
        if (socket.playerID) { error('Leave your current room first.'); return; }
        let room;
        let player;
        if (message.type === 'create') {
          if (rooms.size >= 100) { error('The festival is full. Try again soon.'); return; }
          let code;
          do { code = randomBytes(3).toString('hex').toUpperCase(); } while (rooms.has(code));
          room = { code, players: [], phase: 'lobby', song: 'lantern', difficulty: 'festival', startAt: 0, round: 0, winner: '', touched: now };
          rooms.set(code, room);
        } else {
          room = rooms.get(String(message.code).toUpperCase());
          if (!room) { error('Room not found. Check the six-character code.'); return; }
          player = room.players.find(item => item.token === message.token && message.token);
          if (!player && (room.players.length >= 2 || room.phase !== 'lobby')) { error('This room already has two drummers.'); return; }
        }
        if (!player) { player = newPlayer(message.name); room.players.push(player); }
        const oldSocket = sockets.get(player.id);
        sockets.set(player.id, socket);
        oldSocket?.close(1000, 'Rejoined');
        player.connected = true;
        socket.playerID = player.id;
        socket.roomCode = room.code;
        room.touched = now;
        send(socket, { type: 'joined', id: player.id, token: player.token, room: publicRoom(room), chart: chartFor(room.song, room.difficulty) });
        broadcast(room);
        log('join', { room: room.code, player: player.id, name: player.name, resumed: Boolean(message.token) });
        return;
      }
      const room = rooms.get(socket.roomCode);
      const player = room?.players.find(item => item.id === socket.playerID);
      if (!room || !player) { error('Join a room first.'); return; }
      room.touched = now;
      if (message.type === 'select') {
        if (room.phase !== 'lobby' || player.id !== room.players[0].id) { error('Only the host can select in the lobby.'); return; }
        if (!SONGS.some(song => song.id === message.song) || !['easy', 'festival'].includes(message.difficulty)) return;
        room.song = message.song;
        room.difficulty = message.difficulty;
        room.players.forEach(item => { item.ready = false; });
        room.players.forEach(item => send(sockets.get(item.id) ?? socket, { type: 'chart', chart: chartFor(room.song, room.difficulty) }));
      } else if (message.type === 'ready') {
        if (!['lobby', 'results'].includes(room.phase)) return;
        player.ready = message.ready === true;
        log('ready', { room: room.code, player: player.id, ready: player.ready });
        if (room.players.length === 2 && room.players.every(item => item.ready && item.connected)) {
          room.players.forEach(resetPlayer);
          room.chart = chartFor(room.song, room.difficulty);
          room.startAt = now + 5000;
          room.round++;
          room.winner = '';
          room.phase = 'playing';
          log('start', { room: room.code, round: room.round, startAt: room.startAt, song: room.song });
        }
      } else if (message.type === 'songs') {
        if (room.phase === 'results' && player.id === room.players[0].id) {
          room.phase = 'lobby'; room.players.forEach(item => { item.ready = false; });
        }
      } else if (message.type === 'hit') {
        if (applyHit(room, player, message, now)) {
          log('hit', { room: room.code, round: room.round, player: player.id, seq: message.seq, kind: message.kind,
            hand: message.hand, judgment: player.judgment, score: player.score, delta: player.delta, at: message.at });
        }
      }
      broadcast(room);
    });
    socket.on('close', () => detach(socket));
    socket.on('error', () => detach(socket));
  });
  const tick = setInterval(() => {
    const now = Date.now();
    for (const room of rooms.values()) {
      const phase = room.phase;
      advanceRoom(room, now);
      if (phase !== room.phase) log('result', { room: room.code, round: room.round, winner: room.winner,
        players: room.players.map(({ id, score, good, ok, bad, rolls, bigHits }) => ({ id, score, good, ok, bad, rolls, bigHits })) });
      if (room.phase === 'playing' || phase !== room.phase) broadcast(room);
      if (room.players.every(player => !player.connected) && now - room.touched > 120000) rooms.delete(room.code);
    }
  }, 50);
  const heartbeat = setInterval(() => {
    for (const socket of wss.clients) {
      if (!socket.alive) { socket.terminate(); continue; }
      socket.alive = false; socket.ping();
    }
  }, 10000);
  return {
    http, rooms,
    listen: () => new Promise(resolve => http.listen(port, host, () => resolve(http.address()))),
    close: () => new Promise(resolve => { clearInterval(tick); clearInterval(heartbeat); wss.clients.forEach(socket => socket.terminate()); wss.close(() => http.close(resolve)); }),
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const server = createFestivalServer({ port: Number(process.env.PORT || 8786) });
  const address = await server.listen();
  console.log(`Festival Don server listening on ${address.port}`);
}
