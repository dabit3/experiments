import test from "node:test";
import assert from "node:assert/strict";
import { match, fighter, ready, input, step, CYCLE, snapshot } from "../Server/combat.mjs";

function duel() {
  const game = match();
  game.players = [fighter("ren", "Ren", 0), fighter("aya", "Aya", 1)];
  ready(game, "ren");
  ready(game, "aya");
  for (let i = 0; i < 150; i++) step(game);
  return game;
}
function advance(game, frames) { for (let i = 0; i < frames; i++) step(game); }
function press(game, slot, action, held = {}) {
  const p = game.players[slot];
  input(game, p.id, { seq: p.lastSeq + 1, press: action, held });
}

test("both guests must ready; first to two rounds; rematch resets wins", () => {
  const game = match();
  game.players = [fighter("ren", "Ren", 0), fighter("aya", "Aya", 1)];
  ready(game, "ren");
  advance(game, 200);
  assert.equal(game.phase, "lobby");
  ready(game, "aya");
  assert.equal(game.phase, "countdown");
  advance(game, 150);
  game.players[1].hp = 0;
  step(game);
  assert.equal(game.players[0].wins, 1);
  assert.equal(game.phase, "roundEnd");
  advance(game, 310);
  game.players[1].hp = 0;
  step(game);
  assert.equal(game.winner, "ren");
  assert.equal(game.phase, "result");
  ready(game, "aya");
  assert.equal(game.phase, "result");
  ready(game, "ren");
  assert.equal(game.matchNumber, 2);
  assert.equal(game.players[0].wins, 0);
  assert.equal(game.players[1].hp, 1000);
});

test("walking forward earns advantage; retreat costs it; world bounds hold", () => {
  const game = duel();
  press(game, 0, "", { right: true });
  advance(game, 30);
  assert.ok(game.players[0].x > 360);
  const gained = game.players[0].grd;
  assert.ok(gained > 0);
  press(game, 0, "", { left: true });
  advance(game, 25);
  assert.ok(game.players[0].grd < gained);
  advance(game, 200);
  assert.ok(game.players[0].x >= 55);
  assert.equal(game.players[0].held.left, false, "stale held input expires");
});

test("ordered input rejects replay and malformed sequence", () => {
  const game = duel();
  assert.equal(input(game, "ren", { seq: 50, held: { right: true } }), true);
  assert.equal(input(game, "ren", { seq: 49, held: { left: true } }), false);
  assert.equal(input(game, "ren", { seq: NaN, press: "ex" }), false);
  assert.equal(game.players[0].held.right, true);
});

test("unknown and object-prototype action names cannot enter a move state", () => {
  const game = duel();
  for (const action of ["constructor", "__proto__", "toString", { action: "ex" }]) {
    press(game, 0, action);
    step(game);
    assert.equal(game.players[0].move, "");
    assert.equal(game.players[0].meter, 35);
  }
});

test("startup, range and one-hit active windows are real", () => {
  const game = duel();
  press(game, 0, "light");
  advance(game, 30);
  assert.equal(game.players[1].hp, 1000, "whiff");
  game.players[1].x = game.players[0].x + 90;
  press(game, 0, "light");
  advance(game, 5);
  assert.equal(game.players[1].hp, 1000, "startup");
  step(game);
  assert.equal(game.players[1].hp, 945);
  advance(game, 15);
  assert.equal(game.players[1].hp, 945, "same attack cannot repeatedly damage");
});

test("guard chips, shield stops chip and steals advantage; throw breaks shield", () => {
  for (const defense of ["guard", "shield"]) {
    const game = duel();
    game.players[1].x = game.players[0].x + 70;
    press(game, 1, "", { [defense]: true });
    press(game, 0, "heavy");
    advance(game, 14);
    assert.equal(game.players[1].hp, defense === "shield" ? 1000 : 993);
    assert.ok(game.players[1].grd > 0);
    assert.equal(game.players[1].stats[defense === "shield" ? "shields" : "blocks"], 1);
  }
  const game = duel();
  game.players[1].x = game.players[0].x + 60;
  press(game, 1, "", { shield: true });
  press(game, 0, "throw");
  advance(game, 7);
  assert.equal(game.players[1].hp, 875);
  assert.ok(game.players[1].broken > 0);
  assert.equal(game.players[1].grd, 0);
});

test("jump changes collision height, evades throw, and lands under gravity", () => {
  const game = duel();
  game.players[1].x = game.players[0].x + 60;
  press(game, 1, "jump");
  press(game, 0, "throw");
  advance(game, 15);
  assert.ok(game.players[1].y > 80);
  assert.equal(game.players[1].hp, 1000);
  advance(game, 60);
  assert.equal(game.players[1].y, 0);
});

test("light-heavy-special cancels require a connected hit and pay meter", () => {
  const game = duel();
  game.players[1].x = game.players[0].x + 75;
  press(game, 0, "light");
  press(game, 0, "heavy");
  assert.equal(game.players[0].move, "light");
  advance(game, 6);
  press(game, 0, "heavy");
  assert.equal(game.players[0].move, "heavy");
  advance(game, 14);
  press(game, 0, "special");
  assert.equal(game.players[0].move, "special");
  advance(game, 20);
  assert.ok(game.players[0].stats.hits >= 2);
  assert.ok(game.players[0].meter < 35);
});

test("special travels over time and cannot be cast without EXS", () => {
  const game = duel();
  game.players[0].meter = 24;
  press(game, 0, "special");
  assert.equal(game.players[0].move, "");
  game.players[0].meter = 25;
  press(game, 0, "special");
  assert.equal(game.players[0].meter, 0);
  advance(game, 20);
  assert.equal(game.players[1].hp, 1000);
  assert.equal(game.projectiles.length, 1);
  advance(game, 50);
  assert.ok(game.players[1].hp < 1000);
});

test("periodic leader receives Ascend; Shift consumes it and releases recovery", () => {
  const game = duel();
  game.players[0].grd = 4;
  game.players[1].grd = 2;
  advance(game, CYCLE);
  assert.equal(game.players[0].ascend, true);
  assert.equal(game.players[1].ascend, false);
  press(game, 0, "heavy");
  const before = game.players[0].meter;
  press(game, 0, "shift");
  assert.equal(game.players[0].move, "");
  assert.equal(game.players[0].ascend, false);
  assert.ok(game.players[0].meter > before);
  assert.equal(game.players[0].grd, 0);
});

test("disconnect pauses time and inputs; snapshot never exposes held input", () => {
  const game = duel();
  game.players[1].connected = false;
  const time = game.fightTick;
  advance(game, 100);
  press(game, 0, "light");
  assert.equal(game.fightTick, time);
  assert.equal(game.players[0].move, "");
  assert.equal("held" in snapshot(game).players[0], false);
});
