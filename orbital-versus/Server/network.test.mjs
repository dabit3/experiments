import test from "node:test";
import assert from "node:assert/strict";
import { once } from "node:events";
import { WebSocket } from "ws";
import { createServer } from "./server.mjs";

async function connect(url, name, token) {
  const socket = new WebSocket(url);
  await once(socket, "open");
  const welcome = waitFor(socket, msg => msg.type === "welcome");
  socket.send(JSON.stringify({ type: "join", name, code: "SOCKET", token }));
  return { socket, welcome: await welcome };
}
function waitFor(socket, predicate) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => { socket.off("message", listener); reject(new Error("Timed out")); }, 8000);
    const listener = raw => {
      const msg = JSON.parse(raw);
      if (predicate(msg)) { clearTimeout(timer); socket.off("message", listener); resolve(msg); }
    };
    socket.on("message", listener);
  });
}
test("real WebSockets: independent guests, shared state, combat, reconnect and rematch", async () => {
  const app = createServer({ port: 0, host: "127.0.0.1", duration: 3 });
  await once(app.server, "listening");
  const url = `ws://127.0.0.1:${app.server.address().port}`;
  try {
    const a = await connect(url, "ALPHA"), b = await connect(url, "BETA");
    assert.notEqual(a.welcome.id, b.welcome.id);
    a.socket.send('{"type":"ready"}'); b.socket.send('{"type":"ready"}');
    const running = await waitFor(a.socket, msg => msg.type === "state" && msg.phase === "playing");
    assert.equal(running.units.filter(unit => !unit.ai).length, 2);
    a.socket.send(JSON.stringify({ type: "input", seq: 1, x: 0, z: 0, actions: ["fire"] }));
    b.socket.send(JSON.stringify({ type: "input", seq: 1, x: 0, z: 0, actions: ["fire"] }));
    const damage = await waitFor(b.socket, msg => msg.type === "state" &&
      msg.units.filter(unit => !unit.ai).every(unit => unit.damage >= 65));
    assert.ok(damage.units.filter(unit => !unit.ai).every(unit => unit.hp < 520));
    const close = once(a.socket, "close"); a.socket.close(); await close;
    const rejoined = await connect(url, "ALPHA", a.welcome.token);
    assert.equal(rejoined.welcome.id, a.welcome.id);
    const [ra, rb] = await Promise.all([
      waitFor(rejoined.socket, msg => msg.type === "state" && msg.phase === "result"),
      waitFor(b.socket, msg => msg.type === "state" && msg.phase === "result")
    ]);
    assert.equal(ra.winner, rb.winner);
    assert.deepEqual(ra.costs, rb.costs);
    rejoined.socket.send('{"type":"rematch"}'); b.socket.send('{"type":"rematch"}');
    const rematch = await waitFor(b.socket, msg => msg.type === "state" && msg.round === 2);
    assert.equal(rematch.phase, "countdown");
    assert.deepEqual(rematch.costs, [6000, 6000]);
  } finally { await app.close(); }
});
