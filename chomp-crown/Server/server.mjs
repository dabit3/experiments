import http from 'node:http';
import { randomBytes } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';
import { Game, makePlayer } from './game.mjs';

export function createServer({ port = 8873, host = '0.0.0.0', logger = console.log, telemetry = process.env.TRACE === '1' } = {}) {
  const rooms = new Map();
  const server = http.createServer((req, res) => {
    res.writeHead(req.url === '/health' ? 200 : 404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(req.url === '/health' ? { ok: true, rooms: rooms.size } : { error: 'not found' }));
  });
  const wss = new WebSocketServer({ server, maxPayload: 4096 });
  const send = (ws, data) => { if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(data)); };
  const broadcast = game => {
    for (const ws of wss.clients) {
      if (ws.game === game) send(ws, { ...game.snapshot(), you: ws.playerId });
    }
  };
  wss.on('connection', ws => {
    ws.alive = true;
    ws.on('pong', () => { ws.alive = true; });
    ws.on('error', () => {});
    ws.on('message', raw => {
      try {
        const message = JSON.parse(raw.toString());
        if (!message || typeof message !== 'object') return;
        if (message.type === 'join') {
          if (ws.game) return send(ws, { type: 'error', message: 'Already in a room. Leave first.' });
          if (typeof message.playerId !== 'string' || !/^[a-zA-Z0-9-]{8,64}$/.test(message.playerId)) {
            return send(ws, { type: 'error', message: 'Invalid guest identity.' });
          }
          const code = String(message.code || '').toUpperCase().trim();
          let game = rooms.get(code);
          if (message.create) {
            if (rooms.size >= 100) return send(ws, { type: 'error', message: 'Server is full.' });
            let generated;
            do { generated = randomBytes(3).toString('hex').slice(0, 4).toUpperCase(); } while (rooms.has(generated));
            game = new Game(generated);
            rooms.set(generated, game);
          }
          if (!game) return send(ws, { type: 'error', message: 'Room not found. Check the four-character code.' });
          const existing = game.players.find(p => p.id === message.playerId);
          if (existing && message.token !== existing.token) {
            return send(ws, { type: 'error', message: 'Guest recovery token does not match.' });
          }
          if (!existing && game.phase !== 'lobby') return send(ws, { type: 'error', message: 'Match in progress.' });
          if (!existing && game.players.length >= 4) return send(ws, { type: 'error', message: 'Room is full (four players).' });
          let player = existing;
          if (player) {
            for (const peer of wss.clients) {
              if (peer !== ws && peer.game === game && peer.playerId === player.id) {
                peer.game = null; peer.close(1000, 'Reconnected elsewhere');
              }
            }
            player.connected = true;
            delete player.disconnectedAt;
          } else {
            const name = String(message.name || 'Guest').replace(/[^\p{L}\p{N} _-]/gu, '').trim().slice(0, 12) || 'Guest';
            player = makePlayer(message.playerId, name, game.players.length);
            Object.defineProperty(player, 'token', { value: randomBytes(24).toString('hex'), enumerable: false });
            game.players.push(player);
          }
          ws.game = game; ws.playerId = player.id;
          send(ws, { type: 'joined', code: game.code, you: player.id, token: player.token, lastSeq: player.lastSeq });
          logger(JSON.stringify({ event: existing ? 'rejoin' : 'join', room: game.code, player: player.id, name: player.name }));
          broadcast(game);
        } else if (ws.game) {
          if (message.type === 'ready') ws.game.ready(ws.playerId);
          if (message.type === 'input') ws.game.input(ws.playerId, message.seq, message.direction);
          if (message.type === 'leave') {
            const game = ws.game;
            const player = game.players.find(p => p.id === ws.playerId);
            if (game.phase === 'lobby') game.players = game.players.filter(p => p !== player);
            else { player.connected = false; player.disconnectedAt = Date.now() - 30_000; }
            ws.game = null;
            ws.close(1000, 'Left room');
          }
          if (message.type === 'ping') send(ws, { type: 'pong', time: message.time });
        }
      } catch { send(ws, { type: 'error', message: 'Invalid message.' }); }
    });
    ws.on('close', () => {
      const p = ws.game?.players.find(player => player.id === ws.playerId);
      if (p) { p.connected = false; p.disconnectedAt = Date.now(); }
    });
  });
  const tick = setInterval(() => {
    for (const [code, game] of rooms) {
      const expired = game.players.filter(p => !p.connected && Date.now() - p.disconnectedAt >= 30_000);
      if (expired.length) {
        if (game.phase === 'lobby') game.players = game.players.filter(p => !expired.includes(p));
        else {
          for (const p of expired) { p.alive = false; p.connected = true; }
          if (['playing', 'countdown', 'roundOver'].includes(game.phase)) {
            game.phase = 'playing';
            const winner = game.players.find(p => !expired.includes(p) && p.connected);
            if (winner) { winner.crowns = 1; game.endRound(winner, 'disconnect forfeit'); }
          }
          game.players = game.players.filter(p => !expired.includes(p));
        }
      }
      if (!game.players.length) { rooms.delete(code); continue; }
      const before = game.eventId;
      game.step();
      if (telemetry && game.tick % 30 === 0) {
        logger(JSON.stringify({ event: 'telemetry', room: code, tick: game.tick,
          phase: game.phase, round: game.round, winnerId: game.winnerId,
          players: game.players.map(p => ({ id: p.id, name: p.name, x: p.x, y: p.y,
            score: p.score, crowns: p.crowns, alive: p.alive, power: p.power,
            connected: p.connected, lastSeq: p.lastSeq })) }));
      }
      for (const event of game.events.filter(e => e.id > before && e.kind !== 'pellet')) {
        logger(JSON.stringify({ room: code, ...event }));
      }
      if (game.tick % 2 === 0) broadcast(game);
    }
  }, 1000 / 30);
  const heartbeat = setInterval(() => {
    for (const ws of wss.clients) {
      if (!ws.alive) { ws.terminate(); continue; }
      ws.alive = false; ws.ping();
    }
  }, 10_000);
  server.listen(port, host);
  return { server, rooms, close: async () => {
    clearInterval(tick); clearInterval(heartbeat);
    for (const ws of wss.clients) ws.terminate();
    await new Promise(resolve => wss.close(resolve));
    await new Promise(resolve => server.close(resolve));
  } };
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.PORT || 8873);
  createServer({ port });
  console.log(`Chomp Crown listening on ws://0.0.0.0:${port}`);
}
