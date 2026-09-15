import test from "node:test";
import assert from "node:assert/strict";
import { Arena } from "./game.mjs";

function match() {
  const arena = new Arena("TEST");
  arena.add("alpha", "ALPHA"); arena.add("beta", "BETA");
  arena.vote("alpha"); arena.vote("beta");
  for (let n = 0; n < 91; n++) arena.step();
  arena.aiInput = () => {};
  return arena;
}
function advance(arena, ticks, id, input) {
  for (let n = 0; n < ticks; n++) {
    if (id) arena.input(id, { seq: arena.tick, x: 0, z: 0, ...input });
    arena.step();
  }
}
test("lobby requires two real ready peers and ordered finite inputs", () => {
  const arena = new Arena("TEST");
  arena.add("alpha", "A"); arena.vote("alpha");
  assert.equal(arena.phase, "lobby");
  arena.add("beta", "B"); arena.vote("beta");
  assert.equal(arena.phase, "countdown");
  assert.throws(() => arena.add("third", "C"), /full/);
  assert.equal(arena.input("alpha", { seq: 2, x: NaN, z: 1 }), false);
  assert.equal(arena.input("alpha", { seq: 2, x: 5, z: 5 }), true);
  assert.equal(arena.input("alpha", { seq: 1, x: 0, z: 0 }), false);
  assert.ok(Math.hypot(arena.units[0].input.x, arena.units[0].input.z) <= 1);
});
test("flight exhausts boost, falls, and recharges only after landing", () => {
  const arena = match(), pilot = arena.units[0];
  advance(arena, 115, "alpha", { x: 1, boost: true });
  assert.ok(pilot.overheated);
  assert.ok(pilot.y > 0);
  assert.ok(pilot.x <= 44);
  const before = pilot.boost;
  advance(arena, 5, "alpha", { boost: false });
  assert.equal(pilot.boost, before);
  advance(arena, 180, "alpha", { boost: false });
  assert.equal(pilot.y, 0);
  assert.equal(pilot.boost, 100);
  assert.equal(pilot.overheated, false);
});
test("projectiles travel, damage the enemy, consume ammunition and reload", () => {
  const arena = match(), pilot = arena.units[0], target = arena.units[2];
  arena.action(pilot, "fire");
  assert.equal(target.hp, 520);
  assert.equal(pilot.ammo, 6);
  assert.equal(arena.projectiles.length, 1);
  advance(arena, 25);
  assert.equal(target.hp, 455);
  assert.equal(pilot.damage, 65);
  advance(arena, 45);
  assert.equal(pilot.ammo, 7);
});
test("dodge evades and cancels; guard reduces damage; close saber combo finishes", () => {
  const arena = match(), pilot = arena.units[0], enemy = arena.units[2];
  arena.action(enemy, "dodge");
  arena.hit(enemy, pilot, 70);
  assert.equal(enemy.hp, 520);
  advance(arena, 9);
  enemy.blocking = true;
  arena.hit(enemy, pilot, 100);
  assert.equal(enemy.hp, 492);
  enemy.blocking = false;
  enemy.x = pilot.x + 3; enemy.z = pilot.z;
  arena.action(pilot, "melee");
  assert.equal(enemy.hp, 422);
  advance(arena, 16);
  arena.action(pilot, "melee");
  advance(arena, 16);
  arena.action(pilot, "melee");
  assert.equal(pilot.combo, 3);
  assert.equal(enemy.hp, 247);
});
test("cost depletion produces common finite result and a clean voted rematch", () => {
  const arena = match(), pilot = arena.units[0], enemy = arena.units[2];
  for (let life = 0; life < 3; life++) {
    enemy.hp = enemy.maxHP; enemy.invulnerable = 0;
    arena.hit(enemy, pilot, 600);
  }
  assert.deepEqual(arena.costs, [6000, 0]);
  assert.equal(arena.winner, 0);
  assert.equal(arena.phase, "result");
  arena.vote("alpha", true);
  assert.equal(arena.phase, "result");
  arena.vote("beta", true);
  assert.equal(arena.phase, "countdown");
  assert.equal(arena.round, 2);
  assert.deepEqual(arena.costs, [6000, 6000]);
  assert.equal(arena.units[0].damage, 0);
});
test("stale input and disconnect stop movement, timeout is finite", () => {
  const arena = match();
  arena.input("alpha", { seq: 500, x: 1, z: 0, actions: ["fire"] });
  arena.disconnect("alpha");
  const x = arena.units[0].x;
  advance(arena, 30);
  assert.equal(arena.units[0].x, x);
  arena.time = 0.01;
  arena.step();
  assert.equal(arena.phase, "result");
  assert.equal(arena.reason, "TIME LIMIT · COST + ARMOR");
});
