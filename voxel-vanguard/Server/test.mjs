import test from 'node:test';
import assert from 'node:assert/strict';
import { WebSocket } from 'ws';
import { Game, walkable } from './game.mjs';
import { startServer } from './server.mjs';

function party() {
  const game = new Game('TEST');
  const a = game.add('a', 'Aster'), b = game.add('b', 'Bramble');
  game.ready(a.id); game.ready(b.id);
  return { game, a, b };
}
test('two humans are required; slot cap and ordered, finite inputs are enforced', () => {
  const game = new Game('TEST');
  const a = game.add('a', 'Aster');
  game.ready('a'); assert.equal(game.phase, 'lobby');
  const b = game.add('b', 'Bramble');
  assert.equal(game.add('c', 'Third'), null);
  game.ready('b'); assert.equal(game.phase, 'playing');
  game.input('a', { seq: 1, x: 1, z: 0 }); game.update();
  const x = a.x;
  assert.equal(game.input('a', { seq: 1, x: -1, z: 0 }), false);
  assert.equal(game.input('b', { seq: 1, x: Infinity, z: 0 }), false);
  assert.equal(b.x, -6);
  for (let i = 0; i < 20; i++) game.update();
  assert.ok(a.x > x && a.x < x + 2);
});
test('geometry has continuous bridges, blocked columns, stage gates and map boundaries', () => {
  assert.equal(walkable(-2, -3), false);
  assert.equal(walkable(12, 4), false);
  assert.equal(walkable(10, 0, 1), false);
  for (let x = 8; x <= 18; x += 0.1) assert.equal(walkable(x, 0, 2), true);
  assert.equal(walkable(100, 0), false);
});
test('melee damage, cooldown, real projectile travel and dodge invulnerability', () => {
  const { game, a } = party();
  const e = game.enemies[0];
  a.x = e.x - 1; a.z = e.z;
  game.input('a', { seq: 1, x: 0, z: 0, action: 'melee' });
  const hp = e.hp;
  assert.ok(hp < e.maxHP);
  game.input('a', { seq: 2, x: 0, z: 0, action: 'melee' });
  assert.equal(e.hp, hp);
  game.input('a', { seq: 3, x: 0, z: 0, action: 'ranged' });
  assert.equal(game.projectiles.length, 1);
  game.update(); assert.ok(e.hp < hp);
  game.input('a', { seq: 4, x: 0, z: 1, action: 'dodge' });
  const before = a.hp; game.hurt(a, 30); assert.equal(a.hp, before);
});
test('healing cooldown, cooperative revive and once-per-player gear chest claims', () => {
  const { game, a, b } = party();
  game.enemies = [];
  a.hp = 10;
  game.action(a, 'heal'); assert.equal(a.hp, 58);
  game.action(a, 'heal'); assert.equal(a.hp, 58);
  b.down = true; b.hp = 0; b.x = a.x; b.z = a.z + 1;
  for (let i = 0; i < 51; i++) { game.action(a, 'revive'); game.update(); }
  assert.equal(b.down, false); assert.equal(b.hp, 55); assert.equal(a.stats.revive, 1);
  game.loot.push({ id: 'chest', kind: 'chest', x: a.x, z: a.z, claimed: [] });
  game.action(a, 'equip', 'cleaver'); game.action(a, 'equip', 'ember');
  assert.equal(a.weapon, 'cleaver'); assert.equal(a.bow, 'oak');
  game.action(b, 'equip', 'guardian'); assert.equal(b.maxHP, 120);
});
test('disconnect pauses damage and movement; shared defeat and rematch reset', () => {
  const { game, a, b } = party();
  b.connected = false;
  game.input('a', { seq: 2, x: 1, z: 0 });
  game.update(); assert.equal(a.x, -6); assert.equal(game.snapshot().paused, true);
  b.connected = true; a.down = b.down = true; game.update();
  assert.equal(game.phase, 'defeat');
  game.ready('a'); game.ready('b');
  assert.equal(game.phase, 'playing'); assert.equal(game.round, 2);
  assert.equal(a.hp, 100); assert.equal(b.down, false);
});
test('stage clearance opens gates, permits traversal and shared boss completion', () => {
  const { game, a, b } = party();
  for (const e of game.enemies) game.damage(e, 999, a);
  game.update(); assert.equal(game.completedStages, 1);
  a.x = 8.4; a.z = 0; game.move(a, 1, 0, 4.6); assert.ok(a.x > 8.5);
  a.x = 19; game.update(); assert.equal(game.stage, 2);
  for (const e of game.enemies) game.damage(e, 999, b);
  game.update(); a.x = 43; game.update(); assert.equal(game.stage, 3);
  assert.ok(game.enemies.some(e => e.kind === 'boss'));
  for (const e of game.enemies) game.damage(e, 999, b);
  game.update(); assert.equal(game.phase, 'victory'); assert.equal(game.completedStages, 3);
});
function connect(url) {
  return new Promise(resolve => {
    const ws = new WebSocket(url);
    ws.on('open', () => resolve(ws));
  });
}
function until(ws, predicate) {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => { ws.off('message', listener); reject(new Error('message timeout')); }, 4000);
    const listener = raw => {
      const m = JSON.parse(raw);
      if (predicate(m)) { clearTimeout(timeout); ws.off('message', listener); resolve(m); }
    };
    ws.on('message', listener);
  });
}
test('real WebSockets isolate rooms, reject a third peer and resume the same identity', async () => {
  const service = startServer(0, '127.0.0.1');
  await new Promise(resolve => service.server.on('listening', resolve));
  try {
    const url = `ws://127.0.0.1:${service.server.address().port}`;
    const a = await connect(url), b = await connect(url), c = await connect(url);
    const aw = until(a, m => m.type === 'welcome');
    a.send(JSON.stringify({ type: 'hello', create: true, code: 'NET1', name: 'Aster' }));
    const wa = await aw;
    const bw = until(b, m => m.type === 'welcome');
    b.send(JSON.stringify({ type: 'hello', code: 'NET1', name: 'Bramble' }));
    const wb = await bw; assert.notEqual(wa.id, wb.id);
    const error = until(c, m => m.type === 'error');
    c.send(JSON.stringify({ type: 'hello', code: 'NET1' }));
    assert.match((await error).message, /full/);
    const playing = until(a, m => m.phase === 'playing');
    a.send('{"type":"ready"}'); b.send('{"type":"ready"}');
    await playing;
    const left = new Promise(resolve => a.on('close', resolve)); a.close(); await left;
    await until(b, m => m.paused === true);
    const rejoined = await connect(url);
    const rw = until(rejoined, m => m.type === 'welcome');
    rejoined.send(JSON.stringify({ type: 'hello', resume: wa.token }));
    assert.equal((await rw).id, wa.id);
    const state = await until(b, m => m.type === 'state' && !m.paused);
    assert.equal(state.players.length, 2); assert.equal(state.round, 1);
    const other = await connect(url), ow = until(other, m => m.type === 'welcome');
    other.send('{"type":"hello","create":true,"code":"NET2"}'); await ow;
    const isolated = await until(other, m => m.type === 'state');
    assert.equal(isolated.players.length, 1); assert.equal(isolated.phase, 'lobby');
  } finally { service.close(); }
});
