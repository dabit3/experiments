import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { Writable } from 'node:stream';
import { WebSocket } from 'ws';
import { createDuelServer } from './server.mjs';

test('blocked evidence storage does not block WebSocket samples; close drains ordered logs', async () => {
  const lines = [];
  let release;
  const sink = new Writable({
    write(chunk, encoding, done) {
      lines.push(JSON.parse(chunk.toString()));
      if (!release) release = done;
      else done();
    },
  });
  const server = createDuelServer({ port: 0, startDelay: 0, logStream: sink });
  await once(server.http, 'listening');
  const url = `ws://127.0.0.1:${server.http.address().port}`;
  const peers = [];
  async function until(predicate) {
    const deadline = Date.now() + 2000;
    while (!predicate()) {
      assert.ok(Date.now() < deadline, 'WebSocket processing must not wait for evidence storage');
      await new Promise(resolve => setTimeout(resolve, 5));
    }
  }
  try {
    for (const id of ['log-alpha', 'log-bravo']) {
      const ws = new WebSocket(url);
      peers.push(ws);
      await once(ws, 'open');
      ws.send(JSON.stringify({
        type: 'hello', id, name: id, token: `token-${id}-0123456789`,
        code: 'LOG01', create: true, chart: 'ion-afterburn-v1',
      }));
    }
    await until(() => server.rooms.get('LOG01')?.players.size === 2);
    for (const ws of peers) ws.send(JSON.stringify({ type: 'ready' }));
    await until(() => server.rooms.get('LOG01')?.phase === 'playing');
    const room = server.rooms.get('LOG01');
    for (let seq = 0; seq < 20; seq++) {
      peers[0].send(JSON.stringify({
        type: 'input', kind: 'laser', color: 0, x: 0.5, source: 'touch',
        seq, epoch: room.epoch, time: (Date.now() - room.startAt) / 1000,
      }));
    }
    await until(() => room.players.get('log-alpha').inputCount === 20);
    assert.equal(lines.length, 1, 'the evidence sink is still stalled while input is processed');
    peers[0].send(JSON.stringify({
      type: 'input', kind: 'laser', color: 0, x: 0.5, source: 'touch',
      seq: 20, epoch: room.epoch, time: (Date.now() - room.startAt) / 1000 - 0.37,
    }));
    await new Promise(resolve => setTimeout(resolve, 30));
  } finally {
    release?.();
    await server.close();
  }
  assert.deepEqual(lines.filter(entry => entry.event === 'input').map(entry => entry.seq),
    Array.from({ length: 20 }, (_, index) => index));
  const rejected = lines.find(entry => entry.event === 'input-rejected');
  assert.equal(rejected?.reason, 'clock-skew', '370ms-old input must remain rejected');
  assert.equal(rejected?.seq, 20);
  assert.equal(sink.writableFinished, true);
});
