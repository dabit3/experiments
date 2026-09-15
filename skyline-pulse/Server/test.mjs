import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { WebSocket } from 'ws';
import { newPlayer, units, advance, input } from './engine.mjs';
import { startServer, charts } from './server.mjs';

const chart = { tick: 0.25, notes: [
  { id: 0, time: 1, kind: 'tap', lane: 2, width: 2, duration: 0, endLane: 2 },
  { id: 1, time: 2, kind: 'hold', lane: 2, width: 2, duration: 1, endLane: 2 },
  { id: 2, time: 4, kind: 'slide', lane: 2, width: 2, duration: 1, endLane: 10 },
  { id: 3, time: 6, kind: 'air', lane: 5, width: 3, duration: 0, endLane: 5 },
] };
const all = units(chart);
const p = () => newPlayer('one', 'Aria');
const event = (time, x, action = 'down', y = 0.9) => ({ pointer: 'finger', time, x, y, action });

test('timing boundaries, wrong lane, duplicate and miss combo', () => {
  const player = p();
  input(player, all, event(1, 8));
  assert.equal(player.score, 0);
  input(player, all, event(1.044, 3));
  input(player, all, event(1.045, 3));
  assert.equal(player.counts.critical, 1);
  advance(player, all, 2.2);
  assert.equal(player.combo, 0);
  assert.equal(player.counts.miss, 1);
  const late = p();
  input(late, all, event(1.12, 3));
  assert.equal(late.counts.attack, 1);
});
test('hold release loses ticks and rehold recovers without a second head', () => {
  const player = p();
  input(player, all, event(2, 3));
  input(player, all, event(2.24, 3, 'move'));
  advance(player, all, 2.25);
  input(player, all, event(2.3, 3, 'up'));
  advance(player, all, 2.5);
  input(player, all, event(2.7, 3));
  advance(player, all, 2.75);
  assert.equal(player.counts.critical, 3);
  assert.equal(player.counts.miss, 2); // The earlier tap plus released sustain tick.
  assert.equal(player.combo, 1);
});
test('slide requires following its path, not holding its head', () => {
  const moving = p(); const stationary = p();
  input(moving, all, event(4, 3)); input(stationary, all, event(4, 3));
  for (let tick = 1; tick <= 4; tick++) {
    input(moving, all, event(4 + tick / 4 - 0.01, 3 + tick * 2, 'move'));
    input(stationary, all, event(4 + tick / 4 - 0.01, 3, 'move'));
    advance(moving, all, 4 + tick / 4); advance(stationary, all, 4 + tick / 4);
  }
  assert.equal(moving.counts.critical, 5);
  assert.equal(stationary.counts.critical, 1);
});
test('air requires upward movement; stationary and horizontal presses fail', () => {
  const player = p();
  input(player, all, event(5.94, 6));
  input(player, all, event(5.97, 7, 'move'));
  assert.equal(player.score, 0);
  input(player, all, event(6.01, 7, 'move', 0.65));
  assert.equal(player.counts.critical, 1);
  input(player, all, event(6.02, 7, 'move', 0.5));
  assert.equal(player.judged, 1);
});
test('authored charts contain all gestures, ordered valid widths, and full musical tails', () => {
  for (const song of charts) {
    assert.deepEqual(new Set(song.notes.map((n) => n.kind)), new Set(['tap', 'hold', 'slide', 'air']));
    for (const note of song.notes) {
      assert.ok(note.lane >= 0 && note.lane + note.width <= 16);
      assert.ok(note.endLane >= 0 && note.endLane + note.width <= 16);
      assert.ok(note.time + note.duration < song.duration);
    }
    assert.ok(units(song).length > 150);
  }
});

async function client(url) {
  const ws = new WebSocket(url);
  const messages = [];
  ws.on('message', (raw) => messages.push(JSON.parse(raw)));
  await once(ws, 'open');
  const until = async (predicate) => {
    const deadline = Date.now() + 3000;
    while (Date.now() < deadline) {
      const found = messages.find(predicate);
      if (found) return found;
      await new Promise((resolve) => setTimeout(resolve, 10));
    }
    throw new Error(`Missing message; received ${JSON.stringify(messages)}`);
  };
  return { ws, messages, send: (m) => ws.send(JSON.stringify(m)), until };
}
test('real sockets: rooms, two ready, shared clock, limits, invalid input and rejoin identity', async () => {
  const running = startServer(0, '127.0.0.1');
  await once(running.server, 'listening');
  const url = `ws://127.0.0.1:${running.server.address().port}`;
  try {
    const a = await client(url); const b = await client(url); const c = await client(url);
    a.send({ type: 'join', create: true, name: 'Aria' });
    const joinedA = await a.until((m) => m.type === 'joined');
    b.send({ type: 'join', room: joinedA.room, name: 'Nova' });
    const joinedB = await b.until((m) => m.type === 'joined');
    assert.notEqual(joinedA.id, joinedB.id);
    c.send({ type: 'join', room: joinedA.room, name: 'Third' });
    assert.match((await c.until((m) => m.type === 'error')).message, /full/);
    b.send({ type: 'song', song: 'aurora' });
    assert.match((await b.until((m) => m.type === 'error')).message, /host/);
    a.send({ type: 'ready', ready: true }); b.send({ type: 'ready', ready: true });
    const stateA = await a.until((m) => m.phase === 'playing');
    const stateB = await b.until((m) => m.phase === 'playing');
    assert.equal(stateA.startAt, stateB.startAt);
    assert.ok(stateA.startAt > Date.now());
    a.send({ type: 'input', seq: 1, at: Date.now() + 10000, x: 3, y: 0.9, pointer: 'test', action: 'down' });
    await new Promise((resolve) => setTimeout(resolve, 40));
    assert.equal(running.rooms.get(joinedA.room).players.get(joinedA.id).seq, -1);
    b.ws.close(); await once(b.ws, 'close');
    const rejoin = await client(url);
    rejoin.send({ type: 'join', room: joinedA.room, name: 'Nova', token: joinedB.token });
    assert.equal((await rejoin.until((m) => m.type === 'joined')).id, joinedB.id);
    assert.equal((await rejoin.until((m) => m.type === 'state')).startAt, stateA.startAt);
  } finally { await running.close(); }
});
