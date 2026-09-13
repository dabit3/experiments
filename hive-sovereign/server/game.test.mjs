import test from 'node:test';
import assert from 'node:assert/strict';
import { createGame, step, DT } from './game.mjs';

function fixture() {
  const g = createGame();
  for (const u of g.units) {
    u.human = true;
    u.invulnerable = 0;
    u.x = u.team ? 900 : 60;
    u.y = 65;
  }
  return g;
}
function run(g, seconds) { for (let i = 0; i < seconds / DT; i++) step(g); }

test('workers collect only one berry; twelve legitimate hive returns win', () => {
  const g = fixture(), u = g.units[1];
  for (let i = 0; i < 12; i++) {
    const berry = g.berries.find(b => b.active && b.x < 800);
    u.x = berry.x; u.y = berry.y; u.vy = 0;
    step(g);
    assert.equal(u.berry, true);
    const remaining = g.berries.filter(b => b.active).length;
    step(g);
    assert.equal(g.berries.filter(b => b.active).length, remaining);
    u.x = 385; u.y = 395; u.vy = 0;
    step(g);
    assert.equal(g.score[0], i + 1);
  }
  assert.equal(g.victory, 'ECONOMIC');
  assert.equal(g.winner, 0);
});

test('jump lands on a higher platform and horizontal boundaries wrap', () => {
  const g = fixture(), u = g.units[1];
  u.x = 120; u.y = 65; u.input.jump = true;
  run(g, 0.1); u.input.jump = false;
  run(g, 1.3);
  assert.equal(u.y, 150);
  assert.equal(u.grounded, true);
  u.x = -7; u.input.move = -1;
  step(g);
  assert.ok(u.x > 950);
});

test('enemy gates reject workers; claimed gate costs a berry and a full second', () => {
  const g = fixture(), u = g.units[1], gate = g.gates[0];
  u.x = gate.x; u.y = gate.y; u.berry = true; u.input.action = true;
  gate.team = 1;
  run(g, 1.2);
  assert.equal(u.role, 'worker');
  gate.team = 0;
  run(g, 0.7);
  assert.equal(u.role, 'worker');
  run(g, 0.4);
  assert.equal(u.role, 'warrior');
  assert.equal(u.berry, false);
});

test('queen contact claims gates and dive kills lower opponent', () => {
  const g = fixture(), queen = g.units[0], enemy = g.units[6];
  queen.x = 280; queen.y = 235;
  step(g);
  assert.equal(g.gates[0].team, 0);
  queen.x = 440; queen.y = 112; queen.grounded = false; queen.input.dive = true;
  enemy.x = 440; enemy.y = 85;
  run(g, 0.1);
  assert.ok(enemy.dead > 0);
});

test('three queen deaths award military victory; invulnerability prevents double hits', () => {
  const g = fixture(), attacker = g.units[1], queen = g.units[5];
  attacker.role = 'warrior';
  for (let n = 0; n < 3; n++) {
    queen.dead = 0; queen.invulnerable = 0;
    queen.x = 450; queen.y = 65; queen.vy = 0;
    attacker.x = 450; attacker.y = 86; attacker.vy = 0;
    step(g);
    assert.equal(g.lives[1], 2 - n);
    step(g);
    assert.equal(g.lives[1], 2 - n);
  }
  assert.equal(g.victory, 'MILITARY');
});

test('snail requires a worker, travels over time and can be dismounted', () => {
  const g = fixture(), u = g.units[1];
  u.x = 480; u.y = 65; u.input.action = true;
  run(g, 2);
  assert.ok(g.snail.x < 470);
  assert.equal(g.snail.rider, u.id);
  u.input.jump = true; u.input.action = false;
  step(g);
  assert.equal(g.snail.rider, '');
  u.input.jump = false; u.input.action = true; u.x = g.snail.x; u.y = 65; u.vy = 0;
  run(g, 60);
  assert.equal(g.victory, 'SNAIL');
});

test('autonomous teams can navigate, deposit, transform and finish without state injection', () => {
  const economy = createGame();
  run(economy, 180);
  assert.equal(economy.phase, 'result');
  assert.ok(economy.score.some(s => s >= 12) || economy.lives.some(l => l === 0) || economy.victory === 'SNAIL');
  assert.ok(economy.deposits.some(d => d > 0), 'bots must traverse from piles to high hive');
  const military = createGame();
  military.orders = ['military', 'military'];
  let transformed = false;
  for (let i = 0; i < 180 / DT && military.phase === 'playing'; i++) {
    step(military);
    if (military.units.some(u => u.role === 'warrior')) transformed = true;
  }
  assert.ok(transformed, 'military order uses actual berry gate transformations');
});
