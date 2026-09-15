import { createServer } from 'node:http';
import { randomBytes, randomUUID } from 'node:crypto';
import { appendFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { createRoom, player, validTeam, input, advance, TICK_MS } from './engine.mjs';

export function serve({ port = 8793, host = '0.0.0.0', logPath = process.env.TITAN_LOG } = {}) {
  const rooms = new Map();
  const sessions = new Map();
  const http = createServer((req, res) => {
    res.writeHead(req.url === '/health' ? 200 : 404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(req.url === '/health' ? { game: 'Titan Uprising', rooms: rooms.size } : { error: 'Not found' }));
  });
  const wss = new WebSocketServer({ server: http, maxPayload: 2048, perMessageDeflate: false });
  const log = data => { if (logPath) appendFileSync(logPath, JSON.stringify({ wallTime: Date.now(), ...data }) + '\n'); };
  const send = (ws, data) => { if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(data)); };
  const error = (ws, message) => send(ws, { type: 'error', message });
  const broadcast = room => {
    const data = { type: 'state', ...room };
    for (const session of sessions.values()) if (session.room === room) send(session.ws, data);
  };
  const disconnect = (session, ws) => {
    if (session.ws !== ws) return;
    const p = session.room.players.find(p => p.id === session.id);
    if (p) { p.connected = false; p.blocking = false; }
    session.disconnectedAt = Date.now();
    log({ type: 'disconnect', room: session.room.code, player: session.id });
    broadcast(session.room);
  };
  wss.on('connection', ws => {
    let session;
    let count = 0;
    let windowAt = Date.now();
    const joinDeadline = setTimeout(() => { if (!session) ws.close(1008, 'Join timeout'); }, 10000);
    ws.on('message', raw => {
      if (Date.now() - windowAt >= 1000) { windowAt = Date.now(); count = 0; }
      if (++count > 60) { error(ws, 'Input rate limit'); return; }
      let msg;
      try { msg = JSON.parse(raw.toString()); } catch { error(ws, 'Invalid JSON'); return; }
      if (!msg || typeof msg !== 'object') { error(ws, 'Invalid message'); return; }
      if (msg.type === 'ping') { send(ws, { type: 'pong', clientTime: msg.clientTime }); return; }
      if (!session) {
        if (msg.type === 'resume') {
          const existing = sessions.get(msg.token);
          if (!existing) { error(ws, 'Room expired. Return to lobby.'); return; }
          session = existing;
          if (session.ws.readyState === WebSocket.OPEN) session.ws.close(1000, 'Resumed elsewhere');
          session.ws = ws;
          session.disconnectedAt = 0;
          const p = session.room.players.find(p => p.id === session.id);
          p.connected = true;
          send(ws, { type: 'welcome', id: session.id, token: msg.token, code: session.room.code, lastSeq: p.lastSeq });
          log({ type: 'resume', room: session.room.code, player: session.id });
          broadcast(session.room);
          return;
        }
        if (!['create', 'join'].includes(msg.type)) { error(ws, 'Join first'); return; }
        if (!validTeam(msg.team)) { error(ws, 'Select three different heroes'); return; }
        const name = typeof msg.name === 'string' ? msg.name.trim().slice(0, 18) : '';
        if (!name) { error(ws, 'Guest name required'); return; }
        let room;
        if (msg.type === 'create') {
          if (rooms.size >= 100) { error(ws, 'Server room limit reached'); return; }
          let code;
          do { code = randomBytes(3).toString('hex').toUpperCase(); } while (rooms.has(code));
          room = createRoom(code);
          rooms.set(code, room);
        } else {
          room = rooms.get(String(msg.code).trim().toUpperCase());
          if (!room) { error(ws, 'Room not found'); return; }
          if (room.players.length >= 2) { error(ws, 'Room full'); return; }
          if (room.phase !== 'lobby') { error(ws, 'Match already started'); return; }
        }
        const id = randomUUID();
        const token = randomBytes(24).toString('hex');
        room.players.push(player(id, name, msg.team));
        session = { id, token, room, ws, disconnectedAt: 0 };
        sessions.set(token, session);
        send(ws, { type: 'welcome', id, token, code: room.code, lastSeq: 0 });
        log({ type: 'join', room: room.code, player: id, name, team: msg.team });
        broadcast(room);
      } else if (msg.type === 'input') {
        const p = session.room.players.find(p => p.id === session.id);
        const previousEvent = session.room.eventID;
        const accepted = input(session.room, p, msg);
        log({ type: 'input', room: session.room.code, player: p.id, seq: msg.seq, action: msg.action, accepted });
        for (const e of session.room.events.filter(e => e.id > previousEvent)) log({ room: session.room.code, ...e });
        broadcast(session.room);
      } else if (msg.type === 'leave') {
        sessions.delete(session.token);
        if (session.room.phase === 'lobby') session.room.players = session.room.players.filter(p => p.id !== session.id);
        else {
          const p = session.room.players.find(p => p.id === session.id);
          p.connected = false;
          session.room.phase = 'result';
          session.room.winner = session.room.players.find(p => p.id !== session.id)?.id ?? 'draw';
        }
        broadcast(session.room);
        ws.close();
      }
    });
    ws.on('close', () => { clearTimeout(joinDeadline); if (session) disconnect(session, ws); });
    ws.on('error', () => {});
  });
  const timer = setInterval(() => {
    for (const room of rooms.values()) {
      const previousEvent = room.eventID;
      advance(room);
      for (const e of room.events.filter(e => e.id > previousEvent)) log({ room: room.code, ...e });
      if (room.phase !== 'lobby') broadcast(room);
    }
    for (const [token, session] of sessions) {
      if (session.disconnectedAt && Date.now() - session.disconnectedAt > 60000) {
        const room = session.room;
        sessions.delete(token);
        if (room.phase === 'lobby') room.players = room.players.filter(p => p.id !== session.id);
        else if (room.phase !== 'result') {
          room.phase = 'result';
          room.winner = room.players.find(p => p.connected)?.id ?? 'draw';
        }
        broadcast(room);
      }
    }
    for (const [code, room] of rooms) if (![...sessions.values()].some(s => s.room === room)) rooms.delete(code);
  }, TICK_MS);
  http.listen(port, host);
  return { http, rooms, close: async () => {
    clearInterval(timer);
    for (const client of wss.clients) client.terminate();
    await new Promise(resolve => wss.close(resolve));
    await new Promise(resolve => http.close(resolve));
  } };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.PORT || 8793);
  serve({ port });
  console.log(`Titan Uprising authoritative server on ws://0.0.0.0:${port}`);
}
