import test from 'node:test';
import assert from 'node:assert/strict';
import { fighter, input, makeMatch, neutral, step } from './combat.js';

function arena() {
  const m = makeMatch('TEST');
  m.players = [fighter('a', 'Alpha', 'kai', 0), fighter('b', 'Beta', 'rhea', 1)];
  m.phase = 'fight';
  m.players[0].x = 400; m.players[1].x = 472;
  return m;
}
function frames(m, n) { for (let i = 0; i < n; i++) step(m); }
function press(m, i, action, held = {}) {
  const p = m.players[i];
  input(m, p, { seq: p.seq + 1, action, held: { ...neutral(), ...held } });
}
test('light has startup, applies one hit, then recovery prevents mash', () => {
  const m = arena();
  press(m, 0, 'light'); frames(m, 3); assert.equal(m.players[1].hp, 100);
  frames(m, 1); assert.equal(m.players[1].hp, 93);
  for (let i = 0; i < 12; i++) { press(m, 0, 'light'); step(m); }
  assert.equal(m.players[1].hp, 93);
  assert.ok(m.freeze >= 0);
});
test('high guard blocks normals, low attack defeats standing guard', () => {
  const m = arena();
  press(m, 1, '', { guard: true });
  press(m, 0, 'light'); frames(m, 12);
  assert.equal(m.players[1].hp, 100); assert.equal(m.players[1].blocks, 1);
  frames(m, 25); press(m, 0, 'light', { crouch: true }); frames(m, 12);
  assert.equal(m.players[1].hp, 93);
});
test('crouch guard protects low while jump-in defeats crouch guard', () => {
  const m = arena();
  press(m, 1, '', { guard: true, crouch: true });
  press(m, 0, 'light', { crouch: true }); frames(m, 30);
  assert.equal(m.players[1].hp, 100);
  m.players[0].y = 22; m.players[0].vy = -1;
  press(m, 0, 'heavy'); frames(m, 25);
  assert.ok(m.players[1].hp < 100);
});
test('projectile travels over real ticks; jumping clears its hurtbox', () => {
  const m = arena(); m.players[1].x = 720;
  press(m, 0, 'fire'); frames(m, 20);
  assert.equal(m.projectiles.length, 1); assert.equal(m.players[1].hp, 100);
  frames(m, 20); press(m, 1, '', { jump: true }); frames(m, 20);
  assert.equal(m.players[1].hp, 100); assert.ok(m.players[1].y > 100);
});
test('super requires full meter, consumes it and emits four waves', () => {
  const m = arena(); m.players[1].x = 850;
  press(m, 0, 'super'); step(m); assert.equal(m.players[0].attack, null);
  m.players[0].meter = 100; press(m, 0, 'super'); frames(m, 30);
  assert.equal(m.players[0].meter, 0); assert.equal(m.projectiles.length, 4);
});
test('ordered input rejects duplicates and stale packets', () => {
  const m = arena(), p = m.players[0];
  assert.equal(input(m, p, { seq: 2, held: { right: true } }), true);
  assert.equal(input(m, p, { seq: 1, held: { left: true } }), false);
  assert.equal(input(m, p, { seq: 2, held: {} }), false);
  step(m); assert.ok(p.x > 400); assert.equal(p.input.left, false);
});
test('KO gives rounds, resets meter, and requires two rematch votes', () => {
  const m = arena(); m.players[1].hp = 7;
  press(m, 0, 'light'); frames(m, 5);
  assert.equal(m.phase, 'roundOver'); assert.equal(m.players[0].wins, 1);
  frames(m, 330); assert.equal(m.phase, 'fight');
  assert.equal(m.players[1].hp, 100); assert.equal(m.players[0].meter, 0);
  m.players[1].hp = 0; step(m);
  assert.equal(m.phase, 'matchOver'); assert.equal(m.winner, 'a');
  m.players[0].rematch = true; step(m); assert.equal(m.match, 1);
  m.players[1].rematch = true; step(m); assert.equal(m.match, 2);
  assert.equal(m.players[0].wins, 0); assert.equal(m.phase, 'countdown');
});
test('disconnect freezes match clocks and held movement', () => {
  const m = arena(), x = m.players[0].x, clock = m.remaining;
  press(m, 0, '', { right: true }); m.players[1].connected = false;
  frames(m, 200); assert.equal(m.players[0].x, x); assert.equal(m.remaining, clock);
  m.players[1].connected = true; step(m); assert.ok(m.players[0].x > x);
});
test('time-out draw restarts a round without awarding a win', () => {
  const m = arena(); m.remaining = 1; step(m);
  assert.equal(m.phase, 'roundOver'); assert.equal(m.roundWinner, '');
  assert.deepEqual(m.players.map(p => p.wins), [0, 0]);
});
