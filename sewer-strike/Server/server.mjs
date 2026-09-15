import { createServer } from 'node:http';
import { randomBytes, randomUUID } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { Game } from './game.mjs';

export function startServer({ port = 8767, host = '0.0.0.0', log = console.log } = {}) {
  const rooms = new Map();
  const sessions = new Map();
  const send = (socket, data) => {
    if (socket.readyState === WebSocket.OPEN && socket.bufferedAmount < 1_000_000) socket.send(JSON.stringify(data));
  };
  const server = createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    if (req.url === '/health') return res.end(JSON.stringify({ ok: true, game: 'Sewer Strike', rooms: rooms.size }));
    const code = /^\/rooms\/([A-Z0-9]{4,6})$/.exec(req.url)?.[1];
    if (code && rooms.has(code)) return res.end(JSON.stringify(rooms.get(code).game.snapshot()));
    res.writeHead(404); res.end('{"error":"Not found"}');
  });
  const wss = new WebSocketServer({ server, maxPayload: 4096 });
  wss.on('connection', socket => {
    let session;
    let packets = 0;
    let windowStart = Date.now();
    socket.on('message', data => {
      if (Date.now() - windowStart > 1000) { packets = 0; windowStart = Date.now(); }
      if (++packets > 90) { socket.close(1008, 'Input rate exceeded'); return; }
      let m;
      try { m = JSON.parse(data.toString()); } catch { send(socket, { type: 'error', message: 'Invalid JSON' }); return; }
      if (!m || typeof m !== 'object') return;
      try {
        if (m.type === 'hello' && !session) {
          const resumed = typeof m.token === 'string' ? sessions.get(m.token) : undefined;
          if (resumed && rooms.has(resumed.code)) {
            if (resumed.socket && resumed.socket !== socket) resumed.socket.close(1000, 'Replaced by reconnect');
            session = resumed;
            session.socket = socket;
            const p = rooms.get(session.code).game.reconnect(session.id);
            send(socket, { type: 'welcome', id: p.id, token: m.token, code: session.code, resumed: true });
            log(JSON.stringify({ event: 'reconnect', code: session.code, id: session.id }));
          } else {
            let code = typeof m.code === 'string' ? m.code.toUpperCase().trim() : '';
            if (m.create) {
              if (rooms.size >= 64) throw new Error('Server room limit reached');
              if (!code) do { code = randomBytes(3).toString('hex').toUpperCase(); } while (rooms.has(code));
              if (!/^[A-Z0-9]{4,6}$/.test(code)) throw new Error('Use a 4–6 letter/number room code');
              if (rooms.has(code)) throw new Error('Room already exists; choose Join');
              rooms.set(code, { game: new Game(code), lastActive: Date.now(), eventID: 0 });
            }
            const room = rooms.get(code);
            if (!room) throw new Error('Room not found — check the code and server');
            const id = randomUUID(), token = randomBytes(24).toString('hex');
            const p = room.game.addPlayer(id, m.name, m.hero);
            session = { id, code, socket };
            sessions.set(token, session);
            send(socket, { type: 'welcome', id: p.id, token, code, resumed: false });
            log(JSON.stringify({ event: 'join', code, id, hero: p.hero, name: p.name }));
          }
        } else if (session) {
          const game = rooms.get(session.code)?.game;
          if (!game) return;
          if (m.type === 'input') game.input(session.id, m);
          if (m.type === 'ready') game.ready(session.id);
          if (m.type === 'rematch') game.voteRematch(session.id);
          if (m.type === 'ping') send(socket, { type: 'pong', client: m.client, tick: game.tick });
        }
      } catch (error) {
        send(socket, { type: 'error', message: error.message });
      }
    });
    socket.on('error', () => {});
    socket.on('close', () => {
      if (session && session.socket === socket) {
        rooms.get(session.code)?.game.disconnect(session.id);
        session.socket = null;
        log(JSON.stringify({ event: 'disconnect', code: session.code, id: session.id }));
      }
    });
  });
  const interval = setInterval(() => {
    for (const [code, room] of rooms) {
      room.game.update();
      const state = room.game.snapshot();
      for (const s of sessions.values()) if (s.code === code && s.socket) send(s.socket, state);
      for (const event of state.events.filter(e => e.id > room.eventID)) {
        log(JSON.stringify({ event: 'game', code, ...event }));
        room.eventID = event.id;
      }
      if (room.game.players.some(p => p.connected)) room.lastActive = Date.now();
      if (Date.now() - room.lastActive > 10 * 60_000) {
        rooms.delete(code);
        for (const [token, s] of sessions) if (s.code === code) sessions.delete(token);
      }
    }
  }, 1000 / 30);
  server.listen(port, host, () => log(JSON.stringify({ event: 'listening', port: server.address().port })));
  return {
    server, rooms,
    close: async () => {
      clearInterval(interval);
      for (const client of wss.clients) client.terminate();
      await new Promise(resolve => wss.close(resolve));
      await new Promise(resolve => server.close(resolve));
    },
  };
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  startServer({ port: Number(process.env.PORT || 8767) });
}
