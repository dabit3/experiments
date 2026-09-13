import { test } from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { readFileSync } from 'node:fs';
import { WebSocket } from 'ws';
import { DuelEngine, laserX } from './engine.mjs';
import { createDuelServer } from './server.mjs';

const chart = JSON.parse(readFileSync(new URL('../Resources/chart.json', import.meta.url)));
const fixture = {
  duration: 3, tick: 0.1,
  notes: [
    { id: 0, time: 1, lane: 0, kind: 'bt', duration: 0.6 },
    { id: 1, time: 2, lane: 4, kind: 'fx', duration: 0 },
  ],
  lasers: [{ color: 0, points: [{ time: 1, x: 0.1 }, { time: 2, x: 0.9 }] }],
};

test('timing windows, unique input sequence, future input and score ownership', () => {
  const engine = new DuelEngine(fixture);
  const a = engine.player('alpha', 'Alpha'), b = engine.player('bravo', 'Bravo');
  const event = { kind: 'button', lane: 0, down: true, time: 1, seq: 0 };
  assert.equal(engine.input(a, event, 1), true);
  assert.equal(a.tapHits, 1);
  assert.equal(b.score, 0);
  assert.equal(engine.input(a, event, 1), false);
  assert.equal(engine.input(a, { ...event, seq: 1, time: 2 }, 1), false);
  engine.input(b, { ...event, time: 1.09 }, 1.09);
  assert.equal(b.near, 1);
  assert.equal(a.earned, b.earned * 2);
  assert.ok(Math.abs(a.score - b.score * 2) <= 1, 'normalized integer scores round independently');
});

test('holds require sustained state; moving lasers require fresh tracked gestures', () => {
  const engine = new DuelEngine(fixture);
  const held = engine.player('held', 'Held'), released = engine.player('released', 'Released');
  for (const p of [held, released]) engine.input(p, { kind: 'button', lane: 0, down: true, time: 1, seq: 0 }, 1);
  engine.input(released, { kind: 'button', lane: 0, down: false, time: 1.08, seq: 1 }, 1.08);
  for (let i = 0; i < 61; i++) {
    const time = 1 + i / 60;
    engine.input(held, { kind: 'laser', color: 0, x: laserX(fixture.lasers[0], time), time, seq: i + 1 }, time);
    engine.advance(held, time);
    engine.advance(released, time);
  }
  engine.advance(held, 3);
  engine.advance(released, 3);
  assert.ok(held.holdHits >= 4);
  assert.equal(released.holdHits, 0);
  assert.ok(held.laserHits >= 9);
  assert.equal(released.laserHits, 0);
  assert.ok(held.score > released.score * 2);
});

test('full authored score has reachable taps, holds, FX, ramps and slams', () => {
  const engine = new DuelEngine(chart), player = engine.player('chart', 'Chart');
  const controls = [];
  for (const n of chart.notes) {
    controls.push({ time: n.time, kind: 'button', lane: n.lane, down: true });
    controls.push({ time: n.time + Math.max(0.065, n.duration), kind: 'button', lane: n.lane, down: false });
  }
  for (let i = 0; i < chart.duration * 120; i++) {
    const time = i / 120;
    for (const path of chart.lasers) {
      if (time >= path.points[0].time - 0.05 && time <= path.points.at(-1).time + 0.04) {
        controls.push({ time, kind: 'laser', color: path.color, x: laserX(path, time) });
      }
    }
  }
  controls.sort((a, b) => a.time - b.time);
  controls.forEach((event, seq) => {
    engine.input(player, { ...event, seq }, event.time);
    engine.advance(player, event.time);
  });
  engine.advance(player, chart.duration + 1);
  assert.equal(player.tapHits, chart.notes.filter(n => n.kind === 'bt').length);
  assert.equal(player.fxHits, chart.notes.filter(n => n.kind === 'fx').length);
  assert.ok(player.holdHits > 100);
  assert.ok(player.laserHits > 400);
  assert.ok(player.slamHits > 20);
  assert.ok(player.score > 9_500_000, `${player.score}`);
  assert.ok(player.score <= 10_000_000);
  assert.equal(player.processed.size, engine.events.length);
});

test('real WebSockets isolate two guests, reject third peer, synchronize start and resume', async () => {
  const server = createDuelServer({ port: 0, startDelay: 80 });
  await once(server.http, 'listening');
  const address = server.http.address();
  assert.equal(typeof address, 'object');
  const url = `ws://127.0.0.1:${address.port}`;
  async function peer(id, code, create = false, token = `token-${id}-0123456789`) {
    const ws = new WebSocket(url), messages = [];
    ws.on('message', data => messages.push(JSON.parse(data)));
    await once(ws, 'open');
    ws.send(JSON.stringify({ type: 'hello', id, token, name: id, code, create, chart: chart.id }));
    return { ws, messages, send: data => ws.send(JSON.stringify(data)) };
  }
  async function until(check) {
    const start = Date.now();
    while (!check()) {
      if (Date.now() - start > 2500) throw Error('Timed out waiting for protocol state');
      await new Promise(resolve => setTimeout(resolve, 10));
    }
  }
  try {
    const a = await peer('alpha-123', 'TEST01', true);
    const b = await peer('bravo-123', 'TEST01');
    await until(() => b.messages.some(m => m.players?.length === 2));
    const c = await peer('charlie-123', 'TEST01');
    await until(() => c.messages.some(m => m.type === 'error'));
    assert.match(c.messages.find(m => m.type === 'error').message, /full/);
    a.send({ type: 'ready' }); b.send({ type: 'ready' });
    await until(() => a.messages.some(m => m.phase === 'playing') && b.messages.some(m => m.phase === 'playing'));
    const startA = a.messages.find(m => m.phase === 'playing');
    const startB = b.messages.find(m => m.phase === 'playing');
    assert.equal(startA.startAt, startB.startAt);
    assert.equal(startA.epoch, startB.epoch);
    a.ws.close();
    await once(a.ws, 'close');
    const impostor = await peer('alpha-123', 'TEST01', false, 'wrong-token-0123456789');
    await until(() => impostor.messages.some(m => m.type === 'error'));
    const resumed = await peer('alpha-123', 'TEST01');
    await until(() => resumed.messages.some(m => m.phase === 'playing'));
    assert.equal(resumed.messages.find(m => m.phase === 'playing').startAt, startA.startAt);
    assert.equal(resumed.messages.find(m => m.phase === 'playing').players.length, 2);
  } finally { await server.close(); }
});
