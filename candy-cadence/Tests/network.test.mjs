import test from "node:test";
import assert from "node:assert/strict";
import { WebSocket } from "../Server/node_modules/ws/wrapper.mjs";
import { createGameServer } from "../Server/server.mjs";

async function peer(port) {
  const socket = new WebSocket(`ws://127.0.0.1:${port}`);
  const messages = [];
  socket.on("message", raw => messages.push(JSON.parse(raw)));
  await new Promise(resolve => socket.once("open", resolve));
  return {
    socket, messages, send: value => socket.send(JSON.stringify(value)),
    async wait(predicate) {
      for (let count = 0; count < 200; count++) {
        const found = messages.find(predicate);
        if (found) return found;
        await new Promise(resolve => setTimeout(resolve, 10));
      }
      throw new Error("Message timeout");
    },
  };
}

test("real WebSockets: room isolation, authority, synchronized start, reconnect, results and rematch", async () => {
  let now = 100_000;
  const server = createGameServer({ clock: () => now });
  const port = await server.listen();
  try {
    const a = await peer(port);
    a.send({ type: "hello", create: true, name: "Mallow" });
    const welcomeA = await a.wait(message => message.type === "welcome");
    const b = await peer(port);
    b.send({ type: "hello", room: welcomeA.room, name: "Fizzy" });
    const welcomeB = await b.wait(message => message.type === "welcome");
    assert.notEqual(welcomeA.playerID, welcomeB.playerID);
    const third = await peer(port);
    third.send({ type: "hello", room: welcomeA.room, name: "Third" });
    assert.match((await third.wait(message => message.type === "error")).error, /two players/);
    b.send({ type: "select", songID: "soda" });
    assert.match((await b.wait(message => message.type === "error")).error, /host/);
    a.send({ type: "ready" });
    b.send({ type: "ready" });
    const startA = await a.wait(message => message.phase === "playing");
    const startB = await b.wait(message => message.phase === "playing");
    assert.equal(startA.startAt, startB.startAt);
    now = startA.startAt + 2000;
    a.send({ type: "hit", lane: 0, time: now, sequence: 0 });
    b.send({ type: "hit", lane: 0, time: now + 60, sequence: 0 });
    const scored = await a.wait(message => message.players?.every(player => player.score > 0));
    assert.ok(scored.players[0].score > scored.players[1].score);
    b.socket.close();
    await a.wait(message => message.players?.some(player => !player.connected));
    const rejoined = await peer(port);
    rejoined.send({ type: "hello", room: welcomeA.room, playerID: welcomeB.playerID, token: welcomeB.token });
    const resumed = await rejoined.wait(message => message.type === "welcome");
    assert.equal(resumed.playerID, welcomeB.playerID);
    const resumeState = await rejoined.wait(message => message.phase === "playing");
    assert.equal(resumeState.players[1].score, scored.players[1].score);
    now += 60_000;
    const resultA = await a.wait(message => message.phase === "results");
    const resultB = await rejoined.wait(message => message.phase === "results");
    assert.deepEqual(resultA.players, resultB.players);
    assert.equal(resultA.players[0].judged.length, 184);
    a.send({ type: "rematch" });
    const rematch = await rejoined.wait(message => message.phase === "lobby" && message.match === 1);
    assert.ok(rematch.players.every(player => player.score === 0 && !player.ready));
  } finally {
    await server.close();
  }
});
