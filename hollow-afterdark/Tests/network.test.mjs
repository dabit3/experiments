import test from "node:test";
import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { once } from "node:events";
import { startServer } from "../Server/server.mjs";
const require = createRequire(new URL("../Server/package.json", import.meta.url));
const { WebSocket } = require("ws");

async function connect(url, packet) {
  const ws = new WebSocket(url);
  const messages = [];
  ws.on("message", (raw) => messages.push(JSON.parse(raw.toString())));
  await once(ws, "open");
  ws.send(JSON.stringify({ type: "join", ...packet }));
  return { ws, messages };
}
async function waitUntil(predicate, timeout = 6000) {
  const start = Date.now();
  while (!predicate()) {
    if (Date.now() - start > timeout) throw new Error("Condition timed out");
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
}

test("real WebSocket room isolates peers, enforces two slots, resumes identity and shared state", async (t) => {
  const server = startServer(0, "127.0.0.1");
  t.after(() => server.close());
  await once(server.httpServer, "listening");
  const url = `ws://127.0.0.1:${server.httpServer.address().port}`;
  const a = await connect(url, { room: "TEST", name: "Ren" });
  const b = await connect(url, { room: "TEST", name: "Aya" });
  await waitUntil(() => a.messages.some((m) => m.type === "welcome") && b.messages.some((m) => m.type === "welcome"));
  const aw = a.messages.find((m) => m.type === "welcome");
  const bw = b.messages.find((m) => m.type === "welcome");
  assert.notEqual(aw.id, bw.id);
  const third = await connect(url, { room: "TEST", name: "Third" });
  await waitUntil(() => third.messages.some((m) => m.type === "error"));
  assert.match(third.messages.find((m) => m.type === "error").message, /two duelists/);
  const separate = await connect(url, { room: "ELSE", name: "Else" });
  await waitUntil(() => separate.messages.some((m) => m.type === "state"));
  assert.equal(separate.messages.find((m) => m.type === "state").players.length, 1);
  for (const peer of [a, b]) peer.ws.send('{"type":"ready"}');
  await waitUntil(() => a.messages.some((m) => m.phase === "fight"));
  a.ws.send(JSON.stringify({ type: "input", seq: 1, held: { right: true }, press: "jump" }));
  b.ws.send(JSON.stringify({ type: "input", seq: 1, held: { left: true }, press: "special" }));
  await waitUntil(() => a.messages.some((m) => m.type === "state" && m.players[0]?.stats.jumps > 0 && m.players[1]?.stats.specials > 0));
  const states = a.messages.filter((m) => m.type === "state");
  const last = states.at(-1);
  await waitUntil(() => b.messages.some((m) => m.tick === last.tick));
  assert.deepEqual(b.messages.find((m) => m.tick === last.tick), last);
  a.ws.close();
  await once(a.ws, "close");
  await waitUntil(() => b.messages.some((m) => m.type === "state" && m.players[0]?.connected === false));
  const resumed = await connect(url, { room: "TEST", name: "Ren", id: aw.id, token: aw.token });
  await waitUntil(() => resumed.messages.some((m) => m.type === "welcome"));
  assert.equal(resumed.messages.find((m) => m.type === "welcome").id, aw.id);
  await waitUntil(() => resumed.messages.some((m) => m.type === "state" && m.players.every((p) => p.connected)));
  const restored = resumed.messages.find((m) => m.type === "state" && m.players.every((p) => p.connected));
  assert.equal(restored.players[0].stats.jumps, 1);
  for (const peer of [b, third, separate, resumed]) peer.ws.close();
});
