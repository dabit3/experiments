import { createServer } from 'node:http';
import { randomBytes } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { Match, makePeer, validRoster } from './engine.mjs';

export function startServer(port = 8767, host = '0.0.0.0', logger = console.log) {
  const rooms = new Map();
  const connections = new Map();
  const http = createServer((request, response) => {
    response.writeHead(request.url === '/health' ? 200 : 404, { 'Content-Type': 'application/json' });
    response.end(JSON.stringify(request.url === '/health' ? { game: 'Crown Clash', rooms: rooms.size } : { error: 'Not found' }));
  });
  const server = new WebSocketServer({ server: http, maxPayload: 4096, perMessageDeflate: false });
  const log = (value) => logger(JSON.stringify({ time: new Date().toISOString(), ...value }));
  const send = (socket, value) => {
    if (socket.readyState === WebSocket.OPEN && socket.bufferedAmount < 1024 * 1024) socket.send(JSON.stringify(value));
  };
  server.on('connection', (socket) => {
    let binding;
    let count = 0;
    let bucket = Date.now();
    socket.on('message', (raw) => {
      if (Date.now() - bucket > 1000) { bucket = Date.now(); count = 0; }
      if (++count > 150) { socket.close(1008, 'Input rate exceeded'); return; }
      let data;
      try { data = JSON.parse(raw.toString()); } catch { send(socket, { type: 'error', message: 'Invalid JSON' }); return; }
      if (!data || typeof data !== 'object') return;
      if (data.type === 'hello') {
        if (binding) return;
        if (typeof data.id !== 'string' || !/^[\w-]{3,80}$/.test(data.id)) return;
        let code = typeof data.code === 'string' ? data.code.toUpperCase().trim() : '';
        if (data.create && !code) code = randomBytes(3).toString('hex').toUpperCase();
        if (!/^[A-Z0-9]{4,8}$/.test(code)) { send(socket, { type: 'error', message: 'Use a 4–8 character room code' }); return; }
        let room = rooms.get(code);
        if (!room && data.create) {
          if (rooms.size >= 32) { send(socket, { type: 'error', message: 'Server is full' }); return; }
          room = { game: new Match(code, log), tokens: new Map(), lastActive: Date.now() };
          rooms.set(code, room);
        }
        if (!room) { send(socket, { type: 'error', message: 'Room not found. Ask your friend to host first.' }); return; }
        let peer = room.game.peers.find((player) => player.id === data.id);
        if (peer) {
          if (room.tokens.get(peer.id) !== data.token) { send(socket, { type: 'error', message: 'Invalid resume token' }); return; }
          const previous = connections.get(`${code}:${peer.id}`);
          if (previous) previous.close(1000, 'Replaced by reconnect');
          peer.connected = true;
          peer.queue = [];
          peer.held = { move: 0, guard: false, crouch: false, run: false };
          room.game.event('reconnected', { player: peer.id });
        } else {
          if (!validRoster(data.roster)) { send(socket, { type: 'error', message: 'Select three different fighters' }); return; }
          const name = String(data.name || 'Guest').replace(/[^\p{L}\p{N} _-]/gu, '').slice(0, 16) || 'Guest';
          peer = makePeer(data.id, name, data.roster);
          if (!room.game.join(peer)) { send(socket, { type: 'error', message: 'Room is full (two guests maximum)' }); return; }
          room.tokens.set(peer.id, randomBytes(20).toString('hex'));
        }
        binding = { room, peer, code };
        connections.set(`${code}:${peer.id}`, socket);
        room.lastActive = Date.now();
        send(socket, { type: 'welcome', id: peer.id, token: room.tokens.get(peer.id), code, ack: peer.ack });
        send(socket, room.game.snapshot());
      } else if (binding) {
        const { room, peer } = binding;
        if (data.type === 'input') room.game.input(peer, data);
        if (data.type === 'ready') room.game.ready(peer, data.roster);
        if (data.type === 'rematch') room.game.rematch(peer);
        if (data.type === 'ping') send(socket, { type: 'pong', sent: data.sent });
      }
    });
    socket.on('close', () => {
      if (!binding) return;
      const { room, peer, code } = binding;
      if (connections.get(`${code}:${peer.id}`) !== socket) return;
      connections.delete(`${code}:${peer.id}`);
      peer.connected = false;
      peer.queue = [];
      peer.held = { move: 0, guard: false, crouch: false, run: false };
      room.lastActive = Date.now();
      room.game.event('disconnected', { player: peer.id });
    });
    socket.on('error', () => {});
  });
  const timer = setInterval(() => {
    for (const [code, room] of rooms) {
      room.game.step();
      if (room.game.tick % 2 === 0) {
        const snapshot = room.game.snapshot();
        for (const peer of room.game.peers) {
          const socket = connections.get(`${code}:${peer.id}`);
          if (socket) send(socket, snapshot);
        }
      }
      if (!room.game.peers.some((peer) => peer.connected) && Date.now() - room.lastActive > 60_000) rooms.delete(code);
    }
  }, 1000 / 60);
  http.listen(port, host, () => log({ kind: 'listening', port: http.address().port, host }));
  return {
    http, rooms,
    close: async () => {
      clearInterval(timer);
      for (const socket of server.clients) socket.terminate();
      await new Promise((resolve) => server.close(resolve));
      await new Promise((resolve) => http.close(resolve));
    },
  };
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  startServer(Number(process.env.PORT || 8767));
}
