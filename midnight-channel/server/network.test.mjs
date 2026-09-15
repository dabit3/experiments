import test from 'node:test';
import assert from 'node:assert/strict';
import { WebSocket } from 'ws';
import { once } from 'node:events';
import { startServer } from './server.mjs';

async function peer(url) {
  const ws = new WebSocket(url);
  const messages = [];
  ws.on('message', raw => messages.push(JSON.parse(raw.toString())));
  await once(ws, 'open');
  return { ws, messages, send: obj => ws.send(JSON.stringify(obj)) };
}
async function until(fn) {
  for (let i = 0; i < 200; i++) {
    const result = fn();
    if (result) return result;
    await new Promise(resolve => setTimeout(resolve, 20));
  }
  throw new Error('Timed out waiting for network state');
}
test('real peers: distinct IDs, shared state, room limit, private resume token, reconnect', async () => {
  const service = startServer(0, '127.0.0.1');
  await once(service.server, 'listening');
  const url = `ws://127.0.0.1:${service.server.address().port}`;
  try {
    const a = await peer(url), b = await peer(url), c = await peer(url);
    a.send({ type: 'join', code: 'NET1', name: 'Alpha' });
    b.send({ type: 'join', code: 'NET1', name: 'Beta' });
    const wa = await until(() => a.messages.find(m => m.type === 'welcome'));
    const wb = await until(() => b.messages.find(m => m.type === 'welcome'));
    assert.notEqual(wa.playerID, wb.playerID);
    c.send({ type: 'join', code: 'NET1', name: 'Third' });
    assert.match((await until(() => c.messages.find(m => m.type === 'error'))).message, /two fighters/);
    a.send({ type: 'ready' }); b.send({ type: 'ready' });
    await until(() => b.messages.find(m => m.phase === 'fight'));
    a.send({ type: 'input', seq: 1, axis: 1, guard: false });
    await until(() => b.messages.find(m => m.fighters?.[0].x > 310));
    assert.ok(!JSON.stringify(b.messages).includes(wa.token));
    b.ws.close(); await once(b.ws, 'close');
    await until(() => a.messages.find(m => m.paused));
    const reconnect = await peer(url);
    reconnect.send({ type: 'join', code: 'NET1', name: 'Beta', playerID: wb.playerID, token: wb.token });
    const welcome = await until(() => reconnect.messages.find(m => m.type === 'welcome'));
    assert.equal(welcome.playerID, wb.playerID);
    const state = await until(() => reconnect.messages.find(m => m.type === 'state'));
    assert.equal(state.paused, false); assert.equal(state.fighters.length, 2);
  } finally { await service.close(); }
});
