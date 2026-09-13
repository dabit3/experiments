import test from 'node:test';
import assert from 'node:assert/strict';
import { Game, player } from './game.mjs';

function fixture() {
  const game = new Game('TEST');
  const a = player('a', 'Alpha', [0, 1]);
  const b = player('b', 'Beta', [2, 3]);
  game.players.push(a, b);
  game.ready(a); game.ready(b);
  for (let i = 0; i < 150; i++) game.step();
  a.x = -0.65; b.x = 0.65;
  const input = (p, action, data = {}) => game.input(p, { seq: p.seq + 1, action, ...data });
  const frames = n => { for (let i = 0; i < n; i++) game.step(); };
  return { game, a, b, input, frames };
}
test('ready gate and distinct active/reserve health', () => {
  const game = new Game('WAIT');
  const a = player('a', 'A'), b = player('b', 'B');
  game.players.push(a, b); game.ready(a);
  assert.equal(game.phase, 'lobby');
  game.ready(b);
  assert.equal(game.phase, 'countdown');
  assert.notEqual(a.health, b.health);
});
test('startup, range, duplicate sequence rejection and recovery', () => {
  const { a, b, input, frames, game } = fixture();
  input(a, 'punch'); frames(8);
  assert.equal(b.health[0], 150);
  frames(1); assert.equal(b.health[0], 139);
  game.input(a, { seq: a.seq, action: 'launch' });
  input(a, 'kick');
  assert.equal(a.attack, 'punch');
  frames(20); b.x = 4; input(a, 'kick'); frames(22);
  assert.equal(b.health[0], 139);
});
test('guard chips but prevents launch, sidestep evades a linear strike', () => {
  const { a, b, input, frames } = fixture();
  input(b, 'guard', { down: true }); input(a, 'launch'); frames(20);
  assert.equal(b.y, 0); assert.equal(b.health[0], 148);
  frames(40);
  input(b, 'guard', { down: false });
  input(a, 'launch'); input(b, 'move', { x: 0, z: 1 }); frames(19);
  assert.equal(b.health[0], 148);
});
test('punch cross kick authors a finisher; guard input expires safely', () => {
  const { a, b, input, frames } = fixture();
  input(a, 'punch'); frames(26);
  input(a, 'punch'); assert.equal(a.attack, 'cross'); frames(33);
  input(a, 'kick'); assert.equal(a.attack, 'finisher'); frames(20);
  assert.equal(b.health[0], 99);
  input(b, 'guard', { down: true }); frames(25);
  assert.equal(b.guard, false);
});
test('launcher, tag cancel, juggle damage and independent reserve healing', () => {
  const { a, b, input, frames, game } = fixture();
  a.health[0] = 90; a.red[0] = 120;
  input(a, 'launch'); frames(19);
  assert.ok(b.y > 0);
  input(a, 'tag'); assert.equal(a.active, 1);
  frames(9); input(a, 'punch'); frames(10);
  assert.ok(game.events.some(event => event.kind === 'juggle'));
  assert.ok(a.health[0] > 90 && a.health[0] < 120);
  assert.equal(a.health[1], 150);
  input(a, 'tag'); assert.equal(a.active, 1);
  frames(100); assert.equal(b.y, 0);
});
test('first-to-two winner and mutual rematch restore shared state', () => {
  const { game, a, b, input, frames } = fixture();
  for (let round = 0; round < 2; round++) {
    b.health[0] = 5; a.x = -0.65; b.x = 0.65;
    input(a, 'punch'); frames(10);
    assert.equal(game.phase, 'roundEnd');
    frames(180);
    if (round === 0) frames(150);
  }
  assert.equal(game.winner, 'a');
  assert.equal(game.phase, 'result');
  game.rematch(a); assert.equal(game.phase, 'result');
  game.rematch(b); assert.equal(game.phase, 'countdown');
  assert.equal(a.wins, 0); assert.equal(b.health[0], 150);
});
test('disconnect pauses combat and timeout compares team health', () => {
  const { game, a, b, frames } = fixture();
  b.online = false;
  const remaining = game.remaining; frames(120);
  assert.equal(game.remaining, remaining);
  b.online = true; b.health[0] = 100;
  game.remaining = 1; frames(1);
  assert.equal(game.roundWinner, a.id);
});
