import test from 'node:test';
import assert from 'node:assert/strict';
import { Arena, fighter } from './combat.mjs';

function match() {
  const arena = new Arena('TEST');
  arena.players = [fighter('a', 'Flare', 0), fighter('b', 'Ion', 1)];
  arena.players.forEach(p => arena.ready(p));
  for (let i = 0; i < 91; i++) arena.step();
  return arena;
}
function input(arena, id, actions, fields = {}) {
  const p = arena.players.find(p => p.id === id);
  return arena.input(p, { seq: p.seq + 1, x: 0, z: 0, lift: 0, actions, ...fields });
}
function advance(arena, ticks) { for (let i = 0; i < ticks; i++) arena.step(); }

test('both ready required, round resets health, both see deterministic outcome', () => {
  const arena = match();
  assert.equal(arena.phase, 'playing');
  arena.players[0].hp = 0;
  arena.step();
  assert.equal(arena.winner, 'b');
  assert.equal(arena.reason, 'KNOCKOUT');
  arena.ready(arena.players[0]);
  assert.equal(arena.phase, 'result');
  arena.ready(arena.players[1]);
  assert.equal(arena.round, 2);
  assert.equal(arena.players[0].hp, 300);
});
test('projectiles travel through world before damaging the remote player', () => {
  const arena = match();
  input(arena, 'a', ['shot']); arena.step();
  assert.equal(arena.players[1].hp, 300);
  advance(arena, 14);
  assert.equal(arena.players[1].hp, 290);
  assert.equal(arena.players[0].hits, 1);
});
test('beam telegraph can be dodged; cooldown and energy prevent spamming', () => {
  const arena = match();
  input(arena, 'a', ['beam', 'beam']); arena.step();
  assert.ok(arena.players[0].energy < 59);
  advance(arena, 12);
  input(arena, 'b', ['dodge']); arena.step();
  advance(arena, 18);
  assert.equal(arena.players[1].hp, 300);
  assert.ok(Math.abs(arena.players[1].pos.z) > 2);
});
test('three close strikes form combo and launch target; distant melee misses', () => {
  const arena = match();
  input(arena, 'a', ['melee']); arena.step();
  assert.equal(arena.players[1].hp, 300);
  advance(arena, 40);
  arena.players[1].pos.x = -2;
  for (let hit = 0; hit < 3; hit++) {
    input(arena, 'a', ['melee']); arena.step();
    advance(arena, 11);
  }
  assert.ok(arena.players[1].hp <= 265);
  assert.equal(arena.players[0].combo, 3);
  assert.ok(arena.players[1].pos.x > 0);
});
test('reject stale and invalid inputs, normalize movement, pause disconnection', () => {
  const arena = match();
  const p = arena.players[0];
  assert.equal(input(arena, 'a', [], { x: NaN }), false);
  input(arena, 'a', [], { x: 500, z: 500 });
  assert.equal(arena.input(p, { seq: p.seq, x: 0, z: 0, lift: 0 }), false);
  const before = { ...p.pos };
  arena.step();
  assert.ok(Math.hypot(p.pos.x - before.x, p.pos.z - before.z) < 0.24);
  p.connected = false;
  const time = arena.time;
  advance(arena, 60);
  assert.equal(arena.time, time);
});
