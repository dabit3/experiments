import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { WebSocket } from 'ws';
import { startServer } from './server.mjs';

async function peer(url) {
  const ws = new WebSocket(url);
  const inbox = [];
  ws.on('message', raw => inbox.push(JSON.parse(raw)));
  await once(ws, 'open');
  const wait = async predicate => {
    const until = Date.now() + 5000;
    while (Date.now() < until) {
      const value = inbox.find(predicate);
      if (value) return value;
      await new Promise(resolve => setTimeout(resolve, 10));
    }
    throw new Error(`Timed out. Last messages: ${JSON.stringify(inbox.slice(-2))}`);
  };
  return { ws, inbox, wait, send: body => ws.send(JSON.stringify(body)) };
}
test('real WS room isolation, validation, ordered inputs and token reconnection', async () => {
  const app = startServer(0, '127.0.0.1');
  await once(app.server, 'listening');
  const url = `ws://127.0.0.1:${app.server.address().port}`;
  try {
    const [a, b, c] = await Promise.all([peer(url), peer(url), peer(url)]);
    a.send({ type: 'join', code: '!', name: 'A' });
    assert.match((await a.wait(v => v.type === 'error')).message, /room code/);
    a.send({ type: 'join', code: 'REAL', name: 'A', team: [0, 1] });
    b.send({ type: 'join', code: 'REAL', name: 'B', team: [2, 3] });
    const wa = await a.wait(v => v.type === 'welcome');
    const wb = await b.wait(v => v.type === 'welcome');
    assert.notEqual(wa.id, wb.id);
    c.send({ type: 'join', code: 'REAL', name: 'C' });
    assert.match((await c.wait(v => v.type === 'error')).message, /full/);
    a.send({ type: 'ready' }); b.send({ type: 'ready' });
    await a.wait(v => v.phase === 'fight');
    a.send({ type: 'input', action: 'move', seq: 1, x: 1, z: 0 });
    a.send({ type: 'input', action: 'move', seq: 1, x: -1, z: 0 });
    const moving = await a.wait(v => v.type === 'state' && v.players[0].seq === 1);
    assert.equal(moving.players[0].vx, 1);
    assert.equal(moving.players[0].team[0], 0);
    b.ws.close(); await once(b.ws, 'close');
    await a.wait(v => v.paused === true);
    const rejoin = await peer(url);
    rejoin.send({ type: 'join', code: 'REAL', name: 'B', token: wb.token });
    const wr = await rejoin.wait(v => v.type === 'welcome');
    assert.equal(wr.id, wb.id);
    const resumed = await rejoin.wait(v => v.type === 'state' && !v.paused);
    assert.equal(resumed.players.length, 2);
    console.log(JSON.stringify({ assertion: 'distinct peers rejoined through WebSocket', a: wa.id, b: wb.id }));
  } finally { await app.close(); }
});
