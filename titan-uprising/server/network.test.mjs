import test from 'node:test';
import assert from 'node:assert/strict';
import { WebSocket } from 'ws';
import { serve } from './server.mjs';

async function client(url) {
  const ws = new WebSocket(url);
  const messages = [];
  ws.on('message', data => messages.push(JSON.parse(data)));
  await new Promise(resolve => ws.on('open', resolve));
  return { ws, messages, send: msg => ws.send(JSON.stringify(msg)),
    wait: async predicate => {
      const until = Date.now() + 6000;
      while (Date.now() < until) {
        const result = messages.find(predicate);
        if (result) return result;
        await new Promise(resolve => setTimeout(resolve, 10));
      }
      throw new Error('Timed out waiting for protocol state');
    } };
}

test('real WebSockets: distinct peers, capacity, combat convergence, resume authorization and sequence', async () => {
  const server = serve({ port: 0, host: '127.0.0.1' });
  await new Promise(resolve => server.http.on('listening', resolve));
  const url = `ws://127.0.0.1:${server.http.address().port}`;
  try {
    const a = await client(url);
    a.send({ type: 'create', name: 'Alice', team: [0, 1, 2] });
    const aw = await a.wait(m => m.type === 'welcome');
    const b = await client(url);
    b.send({ type: 'join', code: aw.code, name: 'Bob', team: [3, 4, 5] });
    const bw = await b.wait(m => m.type === 'welcome');
    assert.notEqual(aw.id, bw.id);
    const c = await client(url);
    c.send({ type: 'join', code: aw.code, name: 'Eve', team: [0, 3, 5] });
    assert.equal((await c.wait(m => m.type === 'error')).message, 'Room full');
    a.send({ type: 'input', seq: 1, action: 'ready' });
    b.send({ type: 'input', seq: 1, action: 'ready' });
    await a.wait(m => m.phase === 'fight');
    a.send({ type: 'input', seq: 2, action: 'strong' });
    b.send({ type: 'input', seq: 2, action: 'block', down: true });
    const stateA = await a.wait(m => m.events?.some(e => e.type === 'block'));
    const stateB = await b.wait(m => m.tick === stateA.tick && m.events?.some(e => e.type === 'block'));
    assert.deepEqual(stateA.players.map(p => p.hp), stateB.players.map(p => p.hp));
    b.ws.close();
    await a.wait(m => m.players?.some(p => p.id === bw.id && !p.connected));
    const resumed = await client(url);
    resumed.send({ type: 'resume', token: bw.token });
    const rw = await resumed.wait(m => m.type === 'welcome');
    assert.equal(rw.id, bw.id);
    assert.equal(rw.lastSeq, 2);
    const impostor = await client(url);
    impostor.send({ type: 'resume', token: 'not-a-valid-token' });
    assert.match((await impostor.wait(m => m.type === 'error')).message, /expired/);
  } finally { await server.close(); }
});
