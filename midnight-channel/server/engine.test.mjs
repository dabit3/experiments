import test from 'node:test';
import assert from 'node:assert/strict';
import { room, fighter, ready, input, step } from './engine.mjs';
function duel() {
  const r = room('TEST');
  r.fighters = [fighter('a', 'Rei', 0), fighter('b', 'Mika', 1)];
  ready(r, r.fighters[0]); ready(r, r.fighters[1]);
  for (let i = 0; i < 180; i++) step(r);
  return r;
}
function act(r, slot, action, guard = false, axis = 0) {
  const p = r.fighters[slot];
  input(r, p, { seq: p.lastSeq + 1, action, axis, guard });
}
function ticks(r, n) { for (let i = 0; i < n; i++) step(r); }
test('both ready gates fight and disconnect freezes authoritative clock', () => {
  const r = room('TEST');
  r.fighters = [fighter('a', 'A', 0), fighter('b', 'B', 1)];
  ready(r, r.fighters[0]); ticks(r, 200);
  assert.equal(r.phase, 'lobby');
  ready(r, r.fighters[1]); ticks(r, 180);
  assert.equal(r.phase, 'fight');
  r.fighters[1].connected = false;
  const time = r.time; ticks(r, 120);
  assert.equal(r.time, time);
});
test('attack reach, startup, one hit per move and guard chip', () => {
  const r = duel(), [a, b] = r.fighters;
  act(r, 0, 'light'); ticks(r, 25); assert.equal(b.hp, 1000);
  a.x = 460; b.x = 550;
  act(r, 0, 'heavy'); ticks(r, 8); assert.equal(b.hp, 1000);
  ticks(r, 6); assert.equal(b.hp, 892);
  ticks(r, 40); assert.equal(b.hp, 892);
  a.x = 460; b.x = 550;
  act(r, 1, '', true); act(r, 0, 'light'); ticks(r, 10);
  assert.equal(b.hp, 886);
  assert.ok(r.events.some(e => e.kind === 'block'));
});
test('jump evades grounded attack; burst escapes stun and pushes attacker', () => {
  const r = duel(), [a, b] = r.fighters;
  a.x = 460; b.x = 550;
  act(r, 1, 'jump'); ticks(r, 20);
  act(r, 0, 'light'); ticks(r, 10);
  assert.equal(b.hp, 1000);
  ticks(r, 35); a.x = 460; b.x = 550;
  act(r, 0, 'heavy'); ticks(r, 14);
  assert.ok(b.stun > 0);
  act(r, 1, 'burst'); ticks(r, 2);
  assert.equal(b.stun, 0); assert.ok(b.burst < 2);
  assert.ok(a.x < 300);
});
test('visible companion loses cards, breaks for 600 ticks and restores', () => {
  const r = duel(), [a, b] = r.fighters;
  for (let i = 0; i < 4; i++) {
    a.x = 460; b.x = 550; a.move = ''; b.move = ''; b.stun = 0;
    act(r, 1, 'summon'); act(r, 0, 'light'); ticks(r, 7);
    ticks(r, 20);
  }
  assert.equal(b.cards, 0); assert.ok(b.breakTicks > 0);
  act(r, 1, 'summon'); ticks(r, 2); assert.equal(b.move, '');
  ticks(r, 600); assert.equal(b.cards, 4);
});
test('super requires earned meter and awakening expands capacity', () => {
  const r = duel(), [a, b] = r.fighters;
  act(r, 0, 'super'); ticks(r, 8); assert.equal(a.move, '');
  a.x = 460; b.x = 550; b.hp = 390;
  act(r, 0, 'heavy'); ticks(r, 14);
  assert.equal(b.awakened, true); assert.ok(b.meter >= 50);
  ticks(r, 40);
  act(r, 1, 'super'); ticks(r, 1);
  assert.equal(b.move, 'super'); assert.ok(b.meter < 50);
});
test('ordered inputs reject duplicates, buffers are bounded, stale held controls release', () => {
  const r = duel(), a = r.fighters[0];
  assert.equal(input(r, a, { seq: 4, axis: 1, guard: false }), true);
  assert.equal(input(r, a, { seq: 3, axis: -1, guard: false }), false);
  ticks(r, 31); assert.equal(a.axis, 0);
  for (let seq = 5; seq < 100; seq++) input(r, a, { seq, axis: 0, action: 'light' });
  assert.ok(a.queue.length <= 3);
});
test('round win, match win and mutual rematch reset resources', () => {
  const r = duel(), [a, b] = r.fighters;
  for (let round = 0; round < 2; round++) {
    a.x = 460; b.x = 550; b.hp = 1;
    act(r, 0, 'light'); ticks(r, 10);
    assert.equal(r.phase, 'roundEnd');
    ticks(r, round === 0 ? 360 : 180);
  }
  assert.equal(r.phase, 'result'); assert.equal(r.winner, 'a');
  ready(r, a); assert.equal(r.phase, 'result');
  ready(r, b); assert.equal(r.phase, 'versus');
  assert.equal(r.match, 2); assert.equal(a.wins, 0); assert.equal(b.hp, 1000);
});
