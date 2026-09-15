import { WebSocketServer, WebSocket } from 'ws';
import { createServer } from 'node:http';
import { randomBytes, randomUUID } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { room, fighter, input, step, resetRound, snapshot } from './combat.mjs';

export function startServer(port = 8787, host = '0.0.0.0') {
  const rooms = new Map();
  const peers = new Map();
  const server = createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ game: 'Rift Requiem', protocol: 1, rooms: rooms.size }));
  });
  const wss = new WebSocketServer({ server, maxPayload: 4096 });
  const send = (ws, data) => {
    if (ws.readyState === WebSocket.OPEN && ws.bufferedAmount < 256000) ws.send(JSON.stringify(data));
  };
  const fail = (ws, message) => send(ws, { type: 'error', message });

  wss.on('connection', ws => {
    let peer = null;
    let budget = 0;
    const reset = setInterval(() => { budget = 0; }, 1000);
    ws.on('message', raw => {
      if (++budget > 120) return ws.close(1008, 'Input rate exceeded');
      let msg;
      try { msg = JSON.parse(raw.toString()); } catch { return fail(ws, 'Invalid JSON'); }
      if (!msg || typeof msg !== 'object') return fail(ws, 'Invalid message');
      if (msg.type === 'ping') return send(ws, { type: 'pong', time: msg.time });
      if (msg.type === 'join' && !peer) {
        if (typeof msg.token === 'string' && peers.has(msg.token)) {
          peer = peers.get(msg.token);
          if (!rooms.has(peer.room.code)) { peer = null; return fail(ws, 'Room expired'); }
          if (peer.ws?.readyState === WebSocket.OPEN) {
            peer = null; return fail(ws, 'This guest is already connected');
          }
          peer.ws = ws;
          peer.player.connected = true;
          peer.player.move = 0; peer.player.guard = false; peer.player.queue = [];
          peer.room.paused = peer.room.players.some(p => !p.connected);
        } else {
          const code = String(msg.code || '').toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 6);
          if (code && !rooms.has(code)) return fail(ws, 'Room not found. Check the code.');
          let game = rooms.get(code);
          if (!game) {
            if (rooms.size >= 100) return fail(ws, 'Server full');
            let newCode;
            do { newCode = randomBytes(3).toString('hex').toUpperCase(); } while (rooms.has(newCode));
            game = room(newCode);
            rooms.set(newCode, game);
          }
          if (game.players.length >= 2) return fail(ws, 'Room is full (two duelists)');
          const player = fighter(randomUUID(), String(msg.name || 'Guest').slice(0, 16),
            msg.style === 'vesper' ? 'vesper' : 'rook', game.players.length);
          game.players.push(player);
          peer = { room: game, player, token: randomBytes(24).toString('hex'), ws, disconnected: 0 };
          peers.set(peer.token, peer);
        }
        send(ws, { type: 'welcome', id: peer.player.id, token: peer.token, code: peer.room.code, seq: peer.player.seq });
        send(ws, snapshot(peer.room));
        return;
      }
      if (!peer) return fail(ws, 'Join a room first');
      const { room: game, player } = peer;
      if (msg.type === 'ready' && game.phase === 'lobby') {
        player.ready = true;
        if (game.players.length === 2 && game.players.every(p => p.ready && p.connected)) resetRound(game);
      } else if (msg.type === 'input') input(game, player, msg);
      else if (msg.type === 'rematch' && game.phase === 'result') {
        player.rematch = true;
        if (game.players.every(p => p.rematch && p.connected)) {
          for (const p of game.players) p.wins = 0;
          game.round = 1; game.winner = ''; game.matches++;
          resetRound(game);
        }
      } else if (msg.type === 'leave') {
        ws.close(1000, 'Left room');
      }
    });
    ws.on('close', () => {
      clearInterval(reset);
      if (!peer || peer.ws !== ws) return;
      peer.player.connected = false;
      peer.player.move = 0; peer.player.guard = false;
      peer.disconnected = Date.now();
      peer.room.paused = true;
    });
    ws.on('error', () => {});
  });
  const timer = setInterval(() => {
    for (const game of rooms.values()) {
      step(game);
      if (game.tick % 2 === 0) {
        const state = snapshot(game);
        for (const peer of peers.values()) if (peer.room === game) send(peer.ws, state);
      }
    }
    for (const [token, peer] of peers) {
      if (!peer.player.connected && Date.now() - peer.disconnected > 30000) {
        peers.delete(token);
        const game = peer.room;
        const remaining = game.players.find(p => p.id !== peer.player.id && p.connected);
        if (remaining && game.phase !== 'lobby') {
          game.phase = 'result'; game.winner = remaining.id; game.paused = false;
        } else if (remaining) {
          game.players = [remaining]; remaining.slot = 0; remaining.ready = false;
          game.paused = false;
        }
        if (!remaining) rooms.delete(game.code);
      }
    }
  }, 1000 / 60);
  server.listen(port, host);
  return {
    server, rooms,
    close: async () => {
      clearInterval(timer);
      for (const ws of wss.clients) ws.terminate();
      await new Promise(resolve => wss.close(resolve));
      await new Promise(resolve => server.close(resolve));
    }
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.PORT || 8787);
  startServer(port);
  console.log(`Rift Requiem protocol v1 listening on ${port}`);
}
