import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { WebSocket } from 'ws';
import { startServer, charts } from './server.mjs';

async function connect(url) {
  const ws = new WebSocket(url);
  const messages = [];
  ws.on('message', (raw) => messages.push(JSON.parse(raw)));
  await once(ws, 'open');
  return { ws, messages, send: (message) => ws.send(JSON.stringify(message)) };
}

async function receive(peer, predicate) {
  const deadline = Date.now() + 1000;
  while (Date.now() < deadline) {
    const found = peer.messages.find(predicate);
    if (found) return found;
    await new Promise((resolve) => setTimeout(resolve, 5));
  }
  assert.fail('Both peers must receive the terminal snapshot without another input');
}

for (const phase of [0, 1, 2]) {
  test(`terminal state reaches both sockets at broadcast cadence phase ${phase}`, async (t) => {
    t.mock.timers.enable({ apis: ['setInterval'] });
    const running = startServer(0, '127.0.0.1');
    await once(running.server, 'listening');
    try {
      const url = `ws://127.0.0.1:${running.server.address().port}`;
      const a = await connect(url);
      const b = await connect(url);
      a.send({ type: 'join', create: true, name: 'Aria' });
      const joined = await receive(a, (m) => m.type === 'joined');
      b.send({ type: 'join', room: joined.room, name: 'Nova' });
      await receive(b, (m) => m.type === 'joined');
      a.send({ type: 'ready', ready: true });
      b.send({ type: 'ready', ready: true });
      await receive(a, (m) => m.phase === 'playing');
      await receive(b, (m) => m.phase === 'playing');
      for (let i = 0; i < phase; i++) t.mock.timers.tick(17);
      const room = running.rooms.get(joined.room);
      const chart = charts.find((song) => song.id === room.song);
      room.startAt = Date.now() - (chart.duration + 1) * 1000;
      t.mock.timers.tick(17);
      assert.equal(room.phase, 'results');
      const resultA = await receive(a, (m) => m.phase === 'results');
      const resultB = await receive(b, (m) => m.phase === 'results');
      assert.deepEqual(resultA, resultB);
      assert.equal(resultA.round, 1);
      assert.ok(resultA.players.every((player) => player.counts.miss > 0));
      a.send({ type: 'ready', ready: true });
      b.send({ type: 'ready', ready: true });
      const rematch = await receive(a, (m) => m.round === 2);
      assert.equal(rematch.phase, 'playing');
      assert.ok(rematch.players.every((player) => player.score === 0));
    } finally {
      await running.close();
      t.mock.timers.reset();
    }
  });
}
