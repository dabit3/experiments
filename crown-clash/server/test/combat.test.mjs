import test from 'node:test';
import assert from 'node:assert/strict';
import { Match, makePeer, MOVES } from '../engine.mjs';

function fixture() {
  const game = new Match('TEST');
  const a = makePeer('alpha', 'Alpha', ['rook', 'vesper', 'atlas']);
  const b = makePeer('bravo', 'Bravo', ['sora', 'kestrel', 'jin']);
  game.join(a); game.join(b);
  game.ready(a, ['rook', 'vesper', 'atlas']);
  game.ready(b, ['sora', 'kestrel', 'jin']);
  for (let index = 0; index < 180; index++) game.step();
  return { game, a, b };
}

test('team choice validates uniqueness and needs two ready humans', () => {
  const game = new Match('TEAM');
  const a = makePeer('a', 'A', ['rook', 'vesper', 'atlas']);
  game.join(a);
  assert.equal(game.ready(a, ['rook', 'rook', 'atlas']), false);
  game.ready(a, ['jin', 'sora', 'kestrel']);
  assert.equal(game.phase, 'lobby');
  assert.deepEqual(a.roster.map((member) => member.fighter), ['jin', 'sora', 'kestrel']);
});

test('stale sequence cannot replace new input; disconnected match freezes', () => {
  const { game, a, b } = fixture();
  assert.equal(game.input(a, { seq: 4, move: 1 }), true);
  assert.equal(game.input(a, { seq: 3, move: -1 }), false);
  game.step();
  assert.ok(a.x > 370);
  const timer = game.timer;
  const x = a.x;
  b.connected = false;
  for (let index = 0; index < 100; index++) game.step();
  assert.equal(a.x, x);
  assert.equal(game.timer, timer);
  assert.equal(game.snapshot().paused, true);
});

test('hop and jump have different physical arcs and always land', () => {
  const heights = [];
  for (const action of ['hop', 'jump']) {
    const { game, a } = fixture();
    game.input(a, { seq: 1, action });
    let maximum = 0;
    for (let tick = 0; tick < 100; tick++) {
      game.step();
      maximum = Math.max(maximum, a.y);
    }
    heights.push(maximum);
    assert.equal(a.y, 0);
  }
  assert.ok(heights[0] > 45);
  assert.ok(heights[1] > heights[0] * 2);
});

test('range, recovery, guard, low and overhead create actual combat constraints', () => {
  const { game, a, b } = fixture();
  game.input(a, { seq: 1, action: 'heavyKick' });
  for (let tick = 0; tick < 50; tick++) game.step();
  assert.equal(b.roster[0].hp, 100, 'out of range attacks miss');
  b.guarding = true; b.crouch = false;
  game.hit(a, b, MOVES.heavyKick, { name: 'heavyKick', air: false, low: false });
  assert.equal(b.roster[0].hp, 100, 'standing guard blocks a mid');
  assert.ok(b.guard < 100);
  game.hit(a, b, MOVES.kick, { name: 'kick', air: false, low: true });
  assert.ok(b.roster[0].hp < 100, 'low attacks defeat standing guard');
  const hp = b.roster[0].hp;
  b.guarding = true; b.crouch = true;
  game.hit(a, b, MOVES.kick, { name: 'kick', air: true, low: false });
  assert.ok(b.roster[0].hp < hp, 'air overhead defeats low guard');
});

test('special cancel and super stock consumption are enforced', () => {
  const { game, a } = fixture();
  game.startAttack(a, 'super');
  assert.equal(a.attack, null);
  game.startAttack(a, 'punch');
  game.startAttack(a, 'heavyKick');
  assert.equal(a.attack.name, 'punch', 'cannot skip arbitrary recovery');
  a.attack.hit = true;
  game.startAttack(a, 'special');
  assert.equal(a.attack.name, 'special');
  a.attack.hit = true;
  a.meter = 250;
  game.startAttack(a, 'super');
  assert.equal(a.attack.name, 'super');
  assert.equal(a.meter, 50);
});

test('full input-driven match replaces all three members before declaring victory and rematches', () => {
  const { game, a, b } = fixture();
  let sequence = 0;
  for (let tick = 0; tick < 25_000 && game.phase !== 'result'; tick++) {
    if (tick % 6 === 0) {
      const distance = b.x - a.x;
      game.input(a, { seq: sequence++, move: Math.abs(distance) > 95 ? Math.sign(distance) : 0,
        action: a.meter >= 200 ? 'super' : tick % 24 === 0 ? 'heavyPunch' : 'special' });
      game.input(b, { seq: sequence++, move: Math.abs(distance) > 150 ? -Math.sign(distance) : 0,
        action: tick % 150 === 0 ? 'kick' : '' });
    }
    game.step();
    if (game.phase !== 'result') assert.ok(game.peers.every((peer) => peer.active <= 2));
  }
  assert.equal(game.phase, 'result');
  assert.equal(game.winner, a.id);
  assert.deepEqual(b.roster.map((member) => member.hp), [0, 0, 0]);
  assert.equal(b.active, 3);
  assert.equal(a.knockouts, 3);
  game.rematch(a);
  assert.equal(game.phase, 'result');
  game.rematch(b);
  assert.equal(game.phase, 'countdown');
  assert.equal(game.match, 2);
  assert.equal(b.active, 0);
  assert.deepEqual(b.roster.map((member) => member.hp), [100, 100, 100]);
});

test('timeout compares active health and only removes current team member', () => {
  const { game, a, b } = fixture();
  a.roster[0].hp = 50;
  b.roster[0].hp = 70;
  game.timer = 1;
  game.step();
  assert.equal(game.phase, 'transition');
  for (let tick = 0; tick < 140; tick++) game.step();
  assert.equal(a.active, 1);
  assert.equal(b.active, 0);
  assert.equal(game.phase, 'countdown');
});

test('projectile contact opens a super cancel during special recovery', () => {
  const { game, a, b } = fixture();
  b.x = a.x + 140;
  a.meter = 200;
  game.input(a, { seq: 1, action: 'special' });
  for (let tick = 0; tick < 30 && !a.attack?.hit; tick++) game.step();
  assert.ok(b.roster[0].hp < 100);
  assert.equal(a.attack?.name, 'special');
  assert.equal(a.attack?.hit, true);
  const before = a.meter;
  game.input(a, { seq: 2, action: 'super' });
  game.step();
  assert.equal(a.attack.name, 'super');
  assert.equal(a.meter, before - 200);
});
