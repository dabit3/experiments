import test from "node:test";
import assert from "node:assert/strict";
import { WebSocket } from "ws";
import { fighter, room, startRound, step, acceptInput, MOVES } from "./combat.mjs";
import { createServer } from "./server.mjs";

function duel() {
  const r = room("TEST");
  r.players = [fighter("a", "Alice", "seraph", 0), fighter("b", "Bob", "lyra", 1)];
  r.phase = "fight";
  r.players[0].x = 500;
  r.players[1].x = 605;
  return r;
}
function ticks(r, count) { for (let i = 0; i < count; i++) step(r); }
function act(r, slot, action, options = {}) {
  const p = r.players[slot];
  return acceptInput(r, p, { seq: p.lastSeq + 1, axis: 0, guard: false, action, ...options });
}
test("reject stale sequences, malformed axes and action queue flooding", () => {
  const r = duel(), p = r.players[0];
  assert.equal(acceptInput(r, p, { seq: 10, axis: 99 }), true);
  assert.equal(p.input.axis, 1);
  assert.equal(acceptInput(r, p, { seq: 9, axis: -1 }), false);
  assert.equal(acceptInput(r, p, { seq: 11, axis: NaN }), false);
  for (let i = 0; i < 10; i++) act(r, 0, "light");
  assert.equal(p.actions.length, 4);
});
test("double jump and one airborne dash reset only on landing", () => {
  const r = duel(), p = r.players[0];
  act(r, 0, "jump"); step(r);
  assert.ok(p.y > 0);
  act(r, 0, "jump"); step(r);
  assert.equal(p.jumps, 2);
  act(r, 0, "jump"); step(r);
  assert.equal(p.jumps, 2);
  act(r, 0, "dash"); step(r);
  assert.equal(p.airDashes, 1);
  ticks(r, 14);
  act(r, 0, "dash"); step(r);
  assert.equal(p.dash, 0);
  ticks(r, 150);
  assert.equal(p.y, 0);
  assert.equal(p.jumps, 0);
});
test("confirmed light to medium chain scales damage and increments combo", () => {
  const r = duel(), p = r.players[0], target = r.players[1];
  act(r, 0, "light"); ticks(r, 6);
  assert.equal(target.hp, 935);
  act(r, 0, "medium"); ticks(r, 10);
  assert.equal(p.combo, 2);
  assert.equal(target.hp, 844);
  assert.equal(p.comboDamage, 156);
  assert.ok(p.heat >= 18);
});
test("whiff cannot cancel into higher attack; hits cannot reach behind", () => {
  const r = duel(), p = r.players[0];
  r.players[1].x = 1000;
  act(r, 0, "light"); ticks(r, 6);
  act(r, 0, "heavy"); step(r);
  assert.equal(p.attack, "light");
  assert.equal(r.players[1].hp, 1000);
});
test("barrier stops damage and pushes away; ordinary back guard receives chip", () => {
  const r = duel(), target = r.players[1];
  act(r, 1, "", { guard: true });
  act(r, 0, "medium"); ticks(r, 12);
  assert.equal(target.hp, 1000);
  assert.ok(target.barrier < 90);
  const ordinary = duel();
  act(ordinary, 1, "", { axis: 1 });
  act(ordinary, 0, "medium"); ticks(ordinary, 12);
  assert.ok(ordinary.players[1].hp < 1000);
  assert.ok(ordinary.players[1].hp > 950);
});
test("barrier depletion causes Danger then recovers", () => {
  const r = duel(), p = r.players[1];
  p.barrier = 0.1;
  act(r, 1, "", { guard: true }); step(r);
  assert.ok(p.danger > 0);
  assert.equal(p.barrier, 0);
  ticks(r, 250);
  assert.equal(p.danger, 0);
  assert.ok(p.barrier > 0);
});
test("Seraph Drive heals on contact; Lyra projectile freezes at range", () => {
  const r = duel(), p = r.players[0];
  p.hp = 700;
  act(r, 0, "drive"); ticks(r, 19);
  assert.equal(p.hp, 748);
  const frost = duel();
  frost.players[0].x = 250;
  frost.players[1].x = 650;
  act(frost, 1, "drive"); ticks(frost, 54);
  assert.ok(frost.players[0].hp < 1000);
  assert.ok(frost.events.some(e => e.text === "FROST BIND"));
});
test("super requires and spends 50 heat, does meaningful damage", () => {
  const r = duel(), p = r.players[0];
  act(r, 0, "super"); step(r);
  assert.equal(p.attack, "");
  p.heat = 50;
  act(r, 0, "super"); step(r);
  assert.equal(p.heat, 0);
  ticks(r, 20);
  assert.equal(r.players[1].hp, 670);
});
test("two round wins create shared result; countdown clears held input", () => {
  const r = duel(), p = r.players[0];
  p.wins = 1;
  r.players[1].hp = 40;
  act(r, 0, "light"); ticks(r, 6);
  assert.equal(r.phase, "result");
  assert.equal(r.winner, p.id);
  assert.equal(p.wins, 2);
  startRound(r);
  assert.equal(r.players[0].wins, 2);
  assert.equal(r.players[0].hp, 1000);
  assert.equal(r.phase, "countdown");
});
test("disconnect pauses combat and clock, then forfeits after grace", () => {
  const r = duel();
  r.players[1].connected = false;
  ticks(r, 120);
  assert.equal(r.clock, 90);
  assert.equal(r.phase, "fight");
  ticks(r, 1680);
  assert.equal(r.phase, "result");
  assert.equal(r.winner, "a");
});
test("impact depletion triggers Danger even before passive barrier drain", () => {
  const r = duel();
  r.players[1].barrier = 5;
  act(r, 1, "", { guard: true });
  act(r, 0, "medium");
  ticks(r, 10);
  assert.equal(r.players[1].barrier, 0);
  assert.ok(r.players[1].danger > 0);
  assert.ok(r.events.some(e => e.kind === "danger"));
});
test("ordinary sequenced attacks complete a first-to-two match from full health", () => {
  const r = duel();
  const sequences = [0, 0];
  const healthChanged = [false, false];
  for (let frame = 0; frame < 24000 && r.phase !== "result"; frame++) {
    for (const [slot, p] of r.players.entries()) {
      const opponent = r.players[1 - slot];
      if (frame % 6 !== 0) continue;
      const distance = Math.abs(opponent.x - p.x);
      let action;
      if (p.heat >= 50 && !p.attack && distance < 380) action = "super";
      else if (p.attack && p.hit) {
        action = { light: "medium", medium: "heavy", heavy: "drive" }[p.attack];
      } else if (!p.attack && distance < 190 && (slot === 0 || frame % 30 === 0)) {
        action = frame % 120 === 0 ? "drive" : "light";
      }
      acceptInput(r, p, { seq: ++sequences[slot],
        axis: distance > 100 ? Math.sign(opponent.x - p.x) : 0, action });
    }
    step(r);
    r.players.forEach((p, slot) => { healthChanged[slot] ||= p.hp < 1000; });
  }
  assert.equal(r.phase, "result");
  assert.deepEqual(healthChanged, [true, true]);
  assert.equal(r.players.find(p => p.id === r.winner).wins, 2);
});
test("real sockets: guests, full-room rejection, ordered input, ready, reconnect", async () => {
  const app = createServer({ port: 0, host: "127.0.0.1", logging: false });
  if (!app.server.listening) await new Promise(resolve => app.server.once("listening", resolve));
  const address = `ws://127.0.0.1:${app.server.address().port}`;
  const peers = [];
  async function peer() {
    const ws = new WebSocket(address);
    const messages = [];
    ws.on("message", bytes => messages.push(JSON.parse(bytes)));
    await new Promise(resolve => ws.once("open", resolve));
    peers.push(ws);
    return { ws, messages, send: data => ws.send(JSON.stringify(data)) };
  }
  async function until(fn) {
    const deadline = Date.now() + 3500;
    while (Date.now() < deadline) {
      const value = fn(); if (value) return value;
      await new Promise(resolve => setTimeout(resolve, 10));
    }
    throw new Error("condition timed out");
  }
  try {
    const a = await peer(), b = await peer();
    a.send({ type: "join", version: 1, room: "TEST", create: true, name: "Alice", character: "seraph" });
    b.send({ type: "join", version: 1, room: "TEST", create: true, name: "Bob", character: "lyra" });
    const aw = await until(() => a.messages.find(m => m.type === "welcome"));
    const bw = await until(() => b.messages.find(m => m.type === "welcome"));
    assert.notEqual(aw.id, bw.id);
    const c = await peer();
    c.send({ type: "join", version: 1, room: "TEST", name: "Eve" });
    assert.match((await until(() => c.messages.find(m => m.type === "error"))).message, /two players/);
    a.send({ type: "ready", ready: true }); b.send({ type: "ready", ready: true });
    await until(() => a.messages.find(m => m.phase === "fight"));
    a.send({ type: "input", seq: 1, axis: 1, action: "dash" });
    b.send({ type: "input", seq: 1, axis: -1, action: "jump" });
    await until(() => b.messages.find(m => m.events?.some(e => e.kind === "jump")));
    const close = new Promise(resolve => b.ws.once("close", resolve)); b.ws.close(); await close;
    await until(() => a.messages.find(m => m.paused));
    const rejoin = await peer();
    rejoin.send({ type: "join", version: 1, room: "TEST", token: bw.token });
    assert.equal((await until(() => rejoin.messages.find(m => m.type === "welcome"))).id, bw.id);
    assert.equal(app.rooms.get("TEST").players.length, 2);
  } finally {
    peers.forEach(ws => ws.terminate());
    await app.close();
  }
});
