import test from 'node:test';
import assert from 'node:assert/strict';
import { Game, HEROES } from '../game.mjs';

function fixture() {
  const g = new Game('TEST');
  g.addPlayer('a', 'Alpha', 0);
  g.addPlayer('b', 'Bravo', 2);
  g.ready('a'); g.ready('b');
  for (let i = 0; i < 91; i++) g.update();
  return g;
}
test('two distinct guests and unanimous readiness are required', () => {
  const g = new Game('TEST');
  g.addPlayer('a', 'A', 0); g.ready('a');
  assert.equal(g.phase, 'lobby');
  assert.throws(() => g.addPlayer('c', 'C', 0), /already selected/);
  g.addPlayer('b', 'B', 1);
  assert.equal(g.phase, 'lobby');
  g.ready('b');
  assert.equal(g.phase, 'countdown');
});
test('ordered, normalized inputs cannot teleport and expire without heartbeat', () => {
  const g = fixture(), p = g.players[0], x = p.x;
  assert.equal(g.input('a', { seq: 2, dx: 999, dy: 999 }), true);
  assert.equal(g.input('a', { seq: 1, dx: -1, dy: 0 }), false);
  assert.equal(g.input('a', { seq: 3, dx: NaN, dy: 0 }), false);
  for (let i = 0; i < 30; i++) g.update();
  assert.ok(p.x - x < 60);
  assert.equal(p.input.dx, 0);
});
test('direction and lane matter; third strike knocks back and does more damage', () => {
  const g = fixture(), p = g.players[0], e = g.enemies[0];
  g.enemies = [e]; e.x = p.x + 60; e.y = p.y; e.hp = e.maxHP = 1000;
  p.face = -1; g.attack(p);
  assert.equal(e.hp, 1000);
  p.face = 1; p.attackCD = 0; p.combo = 0;
  g.attack(p); const first = 1000 - e.hp;
  p.attackCD = 0; g.attack(p);
  p.attackCD = 0; const before = e.hp; g.attack(p);
  assert.ok(before - e.hp > first);
  assert.ok(e.vx > 0);
  p.attackCD = 0; e.y = p.y + 100; const hp = e.hp; g.attack(p);
  assert.equal(e.hp, hp);
});
test('four weapons differ in actual damage, reach, timing or speed', () => {
  assert.equal(new Set(HEROES.map(h => h.reach)).size, 4);
  assert.equal(new Set(HEROES.map(h => h.damage)).size, 4);
});
test('special spends earned meter; jumping avoids a ground slam', () => {
  const g = fixture(), p = g.players[0], e = g.enemies[0];
  e.x = p.x + 60; e.y = p.y;
  g.attack(p, true); assert.equal(p.power, 0);
  p.attackCD = 0; g.attack(p, true); assert.equal(p.stats.specials, 1);
  p.invuln = 0; p.z = 50; g.hurt(p, 26, e); assert.equal(p.hp, 100);
  p.z = 0; g.hurt(p, 26, e); assert.equal(p.hp, 74);
});
test('nearby teammate revives and healing pickup is consumed only once', () => {
  const g = fixture(), [p, q] = g.players;
  g.enemies = [];
  p.hp = 0; p.down = 18;
  q.x = p.x; q.y = p.y;
  for (let i = 0; i < 80; i++) g.update();
  assert.equal(p.hp, 50); assert.equal(q.stats.revives, 1);
  g.pickups = [{ id: 'slice', x: p.x, y: p.y }];
  g.update(); assert.equal(p.hp, 85); assert.equal(g.pickups.length, 0);
});
test('stage gates require the crew; outcome and rematch are shared', () => {
  const g = fixture();
  g.enemies = [];
  g.players[0].x = 720; g.update();
  assert.equal(g.sector, 0);
  g.players[1].x = 720; g.update();
  assert.equal(g.sector, 1);
  g.enemies = []; g.players.forEach(p => { p.x = 1450; }); g.update();
  assert.equal(g.sector, 2);
  assert.ok(g.enemies.some(e => e.kind === 'boss'));
  g.enemies = []; g.update();
  assert.equal(g.phase, 'clear');
  g.voteRematch('a'); assert.equal(g.phase, 'clear');
  g.voteRematch('b'); assert.equal(g.phase, 'countdown');
  assert.equal(g.match, 2);
});
test('disconnect neutralizes input and reconnect preserves progress', () => {
  const g = fixture(), p = g.players[0];
  p.hp = 65; p.score = 500;
  g.input('a', { seq: 10, dx: 1, dy: 0 });
  g.disconnect('a'); const x = p.x;
  g.update(); assert.equal(p.x, x);
  g.reconnect('a');
  assert.equal(p.hp, 65); assert.equal(p.score, 500);
  assert.equal(g.input('a', { seq: 0, dx: 0, dy: 0 }), true);
});
