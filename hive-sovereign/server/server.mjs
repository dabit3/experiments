import http from 'node:http';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { createGame, step, snapshot, DT } from './game.mjs';

const idle = () => ({ move: 0, jump: false, action: false, dive: false });

export function createServer({ port = 8789, host = '0.0.0.0', log = console.log } = {}) {
  const rooms = new Map();
  const send = (ws, value) => {
    if (ws.readyState === WebSocket.OPEN && ws.bufferedAmount < 256_000) ws.send(JSON.stringify(value));
  };
  const peersView = room => room.peers.map(p => ({
    id: p.id, name: p.name, team: p.team, connected: p.connected,
    ready: p.ready, slot: p.slot, seq: p.seq, inputs: p.inputs,
  }));
  const view = room => ({
    room: room.code, phase: room.game?.phase === 'result' ? 'result' : room.phase,
    countdown: Math.ceil(room.countdown), paused: room.peers.some(p => !p.connected),
    peers: peersView(room), game: room.game ? snapshot(room.game) : null,
    match: room.match,
  });
  const server = http.createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    if (req.url === '/health') {
      res.end(JSON.stringify({ ok: true, game: 'Hive Sovereign', rooms: rooms.size }));
    } else if (/^\/rooms\/[A-Z0-9]{4,6}$/.test(req.url ?? '')) {
      const room = rooms.get(req.url.split('/').at(-1));
      res.statusCode = room ? 200 : 404;
      res.end(JSON.stringify(room ? view(room) : { error: 'Room not found' }));
    } else { res.statusCode = 404; res.end('{}'); }
  });
  const wss = new WebSocketServer({ server, maxPayload: 8192 });
  function broadcast(room) {
    for (const p of room.peers) {
      if (p.connected) send(p.ws, { type: 'state', you: p.id, ...view(room) });
    }
  }
  function start(room) {
    room.game = createGame();
    room.phase = 'countdown'; room.countdown = 3; room.match++;
    for (const p of room.peers) {
      p.ready = false; p.slot = 1;
      room.game.units.find(u => u.id === `${p.team}-1`).human = true;
    }
    log(JSON.stringify({ event: 'match', room: room.code, match: room.match, peers: room.peers.map(p => p.id) }));
  }
  wss.on('connection', ws => {
    let peer, room;
    let rateStart = Date.now(), messages = 0;
    const timeout = setTimeout(() => { if (!peer) ws.close(1008, 'Join required'); }, 5000);
    const error = message => send(ws, { type: 'error', message });
    ws.on('message', data => {
      if (Date.now() - rateStart > 1000) { rateStart = Date.now(); messages = 0; }
      if (++messages > 90) { ws.close(1008, 'Input rate exceeded'); return; }
      let msg;
      try { msg = JSON.parse(data.toString()); } catch { error('Invalid JSON'); return; }
      if (!msg || typeof msg !== 'object') { error('Invalid message'); return; }
      if (msg.type === 'hello' && !peer) {
        if (typeof msg.id !== 'string' || !/^[a-zA-Z0-9-]{8,64}$/.test(msg.id)) { error('Invalid guest ID'); return; }
        if (typeof msg.name !== 'string' || !msg.name.trim() || msg.name.length > 18) { error('Use a guest name of 1–18 characters'); return; }
        if (msg.create) {
          if (rooms.size >= 64) { error('Server room limit reached'); return; }
          let code;
          do { code = crypto.randomBytes(3).toString('hex').slice(0, 5).toUpperCase(); } while (rooms.has(code));
          room = { code, peers: [], phase: 'lobby', countdown: 0, game: null, match: 0, broadcasts: 0, touched: Date.now() };
          rooms.set(code, room);
        } else {
          room = rooms.get(String(msg.room ?? '').toUpperCase());
          if (!room) { error('Room not found. Check the room code.'); return; }
        }
        const existing = room.peers.find(p => p.id === msg.id);
        if (existing) {
          if (msg.token !== existing.token) { error('Invalid reconnect token'); return; }
          const old = existing.ws;
          peer = existing; peer.ws = ws; peer.connected = true; peer.lastInput = Date.now();
          peer.seq = -1;
          if (old !== ws) old.close(1000, 'Reconnected');
        } else {
          if (room.peers.length >= 2) { error('Room full: two captains maximum'); return; }
          if (room.phase !== 'lobby') { error('Match already started'); return; }
          peer = {
            id: msg.id, name: msg.name.trim(), token: crypto.randomBytes(24).toString('hex'),
            team: room.peers.length, slot: 1, connected: true, ready: false,
            seq: -1, inputs: 0, lastInput: Date.now(), ws,
          };
          room.peers.push(peer);
        }
        room.touched = Date.now();
        clearTimeout(timeout);
        send(ws, { type: 'welcome', room: room.code, id: peer.id, token: peer.token, team: peer.team });
        log(JSON.stringify({ event: 'join', room: room.code, id: peer.id, team: peer.team }));
        broadcast(room);
        return;
      }
      if (!peer || !room || peer.ws !== ws) { error('Join a room first'); return; }
      if (msg.type === 'ready' && (room.phase === 'lobby' || room.game?.phase === 'result')) {
        peer.ready = true;
        if (room.peers.length === 2 && room.peers.every(p => p.ready && p.connected)) start(room);
        broadcast(room);
      } else if (msg.type === 'input' && room.phase === 'playing' && room.game?.phase === 'playing') {
        if (!Number.isSafeInteger(msg.seq) || msg.seq <= peer.seq || !Number.isFinite(msg.move) ||
            Math.abs(msg.move) > 1 || !['jump', 'action', 'dive'].every(k => typeof msg[k] === 'boolean')) return;
        peer.seq = msg.seq; peer.inputs++; peer.lastInput = Date.now();
        const unit = room.game.units.find(u => u.id === `${peer.team}-${peer.slot}`);
        unit.input = { move: msg.move, jump: msg.jump, action: msg.action, dive: msg.dive };
      } else if (msg.type === 'switch' && room.game && Number.isInteger(msg.slot) && msg.slot >= 0 && msg.slot < 5) {
        const previous = room.game.units.find(u => u.id === `${peer.team}-${peer.slot}`);
        previous.human = false; previous.input = idle();
        peer.slot = msg.slot;
        const next = room.game.units.find(u => u.id === `${peer.team}-${peer.slot}`);
        next.human = true; next.input = idle();
        broadcast(room);
      } else if (msg.type === 'order' && room.game && ['economy', 'snail', 'military'].includes(msg.order)) {
        room.game.orders[peer.team] = msg.order;
      } else if (msg.type === 'ping') {
        send(ws, { type: 'pong', sent: msg.sent, tick: room.game?.tick ?? 0 });
      }
    });
    ws.on('error', () => {});
    ws.on('close', () => {
      clearTimeout(timeout);
      if (!peer || peer.ws !== ws) return;
      peer.connected = false; peer.ready = false;
      room.touched = Date.now();
      if (room.game) room.game.units.find(u => u.id === `${peer.team}-${peer.slot}`).input = idle();
      log(JSON.stringify({ event: 'disconnect', room: room.code, id: peer.id }));
      broadcast(room);
    });
  });
  const timer = setInterval(() => {
    for (const [code, room] of rooms) {
      if (room.peers.every(p => !p.connected) && Date.now() - room.touched > 120_000) {
        rooms.delete(code); continue;
      }
      if (room.peers.length === 2 && room.peers.every(p => p.connected)) {
        if (room.phase === 'countdown') {
          room.countdown -= DT;
          if (room.countdown <= 0) { room.phase = 'playing'; room.countdown = 0; }
        } else if (room.phase === 'playing' && room.game?.phase === 'playing') {
          for (const p of room.peers) {
            if (Date.now() - p.lastInput > 500) room.game.units.find(u => u.id === `${p.team}-${p.slot}`).input = idle();
          }
          step(room.game);
          if (room.game.phase === 'result') log(JSON.stringify({
            event: 'result', room: code, match: room.match, winner: room.game.winner,
            victory: room.game.victory, tick: room.game.tick, score: room.game.score,
          }));
        }
      }
      room.broadcasts++;
      if (room.broadcasts % 2 === 0) broadcast(room);
    }
  }, 1000 / 30);
  return {
    server, rooms,
    listen: () => new Promise(resolve => server.listen(port, host, () => {
      log(`Hive Sovereign listening on ${host}:${server.address().port}`);
      resolve(server.address().port);
    })),
    close: () => new Promise(resolve => {
      clearInterval(timer);
      for (const ws of wss.clients) ws.terminate();
      wss.close(() => server.close(resolve));
    }),
  };
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const app = createServer({ port: Number(process.env.PORT ?? 8789) });
  await app.listen();
}
