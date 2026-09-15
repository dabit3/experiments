import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import WebSocket from 'ws';
import { startServer } from '../server.mjs';

async function peer(url) {
  const ws = new WebSocket(url);
  const messages = [];
  ws.on('message', data => messages.push(JSON.parse(data)));
  await once(ws, 'open');
  return {
    ws, messages,
    send: message => ws.send(JSON.stringify(message)),
    wait: async predicate => {
      const end = Date.now() + 8000;
      while (Date.now() < end) {
        const found = messages.find(predicate);
        if (found) return found;
        await new Promise(resolve => setTimeout(resolve, 20));
      }
      throw new Error('Timed out waiting for network state');
    },
  };
}
test('real sockets join, affect shared state, reject impersonation and resume token', async () => {
  const service = startServer({ port: 0, host: '127.0.0.1', log: () => {} });
  await once(service.server, 'listening');
  const url = `ws://127.0.0.1:${service.server.address().port}`;
  try {
    const a = await peer(url), b = await peer(url);
    a.send({ type: 'hello', create: true, code: 'COOP', name: 'A', hero: 0 });
    const wa = await a.wait(m => m.type === 'welcome');
    b.send({ type: 'hello', code: 'COOP', name: 'B', hero: 2 });
    const wb = await b.wait(m => m.type === 'welcome');
    assert.notEqual(wa.id, wb.id);
    a.send({ type: 'ready' }); b.send({ type: 'ready' });
    await a.wait(m => m.phase === 'playing');
    await b.wait(m => m.phase === 'playing');
    a.send({ type: 'input', seq: 1, dx: 1, dy: 0, action: 'jump', id: wb.id });
    b.send({ type: 'input', seq: 1, dx: 1, dy: 0, action: 'special' });
    const stateA = await a.wait(m => m.players?.find(p => p.id === wa.id)?.stats.jumps === 1 &&
      m.players?.find(p => p.id === wb.id)?.stats.specials === 1);
    const stateB = await b.wait(m => m.tick === stateA.tick);
    assert.deepEqual(stateA, stateB);
    assert.equal(stateA.players.find(p => p.id === wb.id).stats.jumps, 0);
    a.ws.close(); await once(a.ws, 'close');
    const resumed = await peer(url);
    resumed.send({ type: 'hello', token: wa.token });
    const welcome = await resumed.wait(m => m.type === 'welcome');
    assert.equal(welcome.id, wa.id); assert.equal(welcome.resumed, true);
    const state = await resumed.wait(m => m.type === 'state');
    assert.equal(state.players.length, 2);
    assert.equal(state.players.find(p => p.id === wa.id).stats.jumps, 1);
    assert.ok(!JSON.stringify(state).includes(wa.token));
  } finally { await service.close(); }
});
