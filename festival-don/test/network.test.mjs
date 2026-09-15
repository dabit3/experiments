import test from 'node:test';
import assert from 'node:assert/strict';
import { WebSocket } from 'ws';
import { createFestivalServer } from '../server/index.mjs';

async function peer(url) {
  const socket = new WebSocket(url);
  const messages = [];
  const listeners = new Set();
  socket.on('message', data => {
    const value = JSON.parse(data);
    messages.push(value);
    listeners.forEach(listener => listener(value));
  });
  await new Promise(resolve => socket.once('open', resolve));
  return {
    socket, messages,
    send: data => socket.send(JSON.stringify(data)),
    wait: predicate => new Promise((resolve, reject) => {
      const found = messages.find(predicate);
      if (found) { resolve(found); return; }
      const timeout = setTimeout(() => { listeners.delete(listener); reject(new Error('Protocol timeout')); }, 5000);
      const listener = value => {
        if (predicate(value)) { clearTimeout(timeout); listeners.delete(listener); resolve(value); }
      };
      listeners.add(listener);
    }),
  };
}
test('real WebSockets: rooms, two guests, shared epoch, capacity, token reconnect, rematch', async () => {
  const server = createFestivalServer({ port: 0, host: '127.0.0.1', logger: () => {} });
  const address = await server.listen();
  try {
    const url = `ws://127.0.0.1:${address.port}`;
    const [one, two, extra] = await Promise.all([peer(url), peer(url), peer(url)]);
    one.send({ type: 'create', name: 'Hana' });
    const first = await one.wait(message => message.type === 'joined');
    two.send({ type: 'join', name: 'Sora', code: first.room.code });
    const second = await two.wait(message => message.type === 'joined');
    assert.notEqual(first.id, second.id);
    extra.send({ type: 'join', name: 'Third', code: first.room.code });
    assert.match((await extra.wait(message => message.type === 'error')).message, /two drummers/);
    two.send({ type: 'select', song: 'moon', difficulty: 'easy' });
    assert.match((await two.wait(message => message.type === 'error')).message, /host/);
    one.send({ type: 'ready', ready: true });
    two.send({ type: 'ready', ready: true });
    const [startOne, startTwo] = await Promise.all([one, two].map(client => client.wait(message => message.room?.phase === 'playing')));
    assert.equal(startOne.room.startAt, startTwo.room.startAt);
    assert.equal(startOne.room.round, 1);
    const liveRoom = server.rooms.get(first.room.code);
    // Move the test clock's epoch, never the clients' scores; hit goes through the socket.
    liveRoom.startAt = Date.now() - 2000;
    one.send({ type: 'hit', seq: 0, at: Date.now(), kind: 'don', hand: 'left' });
    const scored = await two.wait(message => message.room?.players[0].score > 0);
    assert.equal(scored.room.players[0].score, 1000);
    two.socket.close();
    await one.wait(message => message.room?.players[1]?.connected === false);
    const resumed = await peer(url);
    resumed.send({ type: 'join', code: first.room.code, token: second.token });
    const rejoin = await resumed.wait(message => message.type === 'joined');
    assert.equal(rejoin.id, second.id);
    assert.equal(rejoin.room.startAt, liveRoom.startAt);
    liveRoom.startAt = Date.now() - liveRoom.chart.duration - 300;
    const result = await one.wait(message => message.room?.phase === 'results');
    assert.equal(result.room.winner, first.id);
    one.send({ type: 'ready', ready: true });
    resumed.send({ type: 'ready', ready: true });
    const rematch = await resumed.wait(message => message.room?.round === 2);
    assert.equal(rematch.room.players[0].score, 0);
    assert.equal(rematch.room.players[1].id, second.id);
  } finally { await server.close(); }
});
