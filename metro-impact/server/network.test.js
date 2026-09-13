import test from 'node:test';
import assert from 'node:assert/strict';
import { WebSocket } from 'ws';
import { createServer } from './server.js';

async function peer(port) {
  const ws = new WebSocket(`ws://127.0.0.1:${port}`), inbox = [];
  ws.on('message', raw => inbox.push(JSON.parse(raw)));
  await new Promise(resolve => ws.once('open', resolve));
  return { ws, send: m => ws.send(JSON.stringify(m)), inbox,
    wait: async predicate => {
      const until = Date.now() + 7000;
      while (Date.now() < until) {
        const message = inbox.find(predicate);
        if (message) return message;
        await new Promise(resolve => setTimeout(resolve, 10));
      }
      throw new Error('Timed out waiting for protocol message');
    } };
}
test('real WebSockets: room limit, identities, ready, shared damage, authenticated rejoin', async () => {
  const app = createServer({ port: 0, host: '127.0.0.1', log: () => {} });
  const port = await app.listen();
  try {
    const a = await peer(port), b = await peer(port), extra = await peer(port);
    a.send({ type: 'hello', create: true, room: 'TEST1', name: 'Alpha', character: 'kai' });
    const wa = await a.wait(m => m.type === 'welcome');
    b.send({ type: 'hello', room: 'TEST1', name: 'Beta', character: 'rhea' });
    const wb = await b.wait(m => m.type === 'welcome');
    assert.notEqual(wa.playerID, wb.playerID);
    extra.send({ type: 'hello', room: 'TEST1', name: 'Third', character: 'kai' });
    assert.match((await extra.wait(m => m.type === 'error')).message, /full/);
    a.send({ type: 'ready', ready: true }); b.send({ type: 'ready', ready: true });
    await a.wait(m => m.phase === 'fight');
    a.send({ type: 'input', seq: 0, held: {}, action: 'fire' });
    const sa = await a.wait(m => m.phase === 'fight' && m.players[1].hp < 100);
    const sb = await b.wait(m => m.tick === sa.tick);
    assert.deepEqual(sa, sb); assert.ok(sa.players[0].damageDealt > 0);
    b.ws.close(); await a.wait(m => m.paused === true);
    const impostor = await peer(port);
    impostor.send({ type: 'hello', room: 'TEST1', playerID: wb.playerID, token: '0'.repeat(48) });
    assert.match((await impostor.wait(m => m.type === 'error')).message, /expired/);
    const malformed = await peer(port);
    malformed.send({ type: 'hello', room: 'TEST1', playerID: wb.playerID, token: 'é'.repeat(48) });
    assert.match((await malformed.wait(m => m.type === 'error')).message, /expired/);
    const returning = await peer(port);
    returning.send({ type: 'hello', room: 'TEST1', playerID: wb.playerID, token: wb.token });
    const resume = await returning.wait(m => m.type === 'welcome');
    assert.equal(resume.playerID, wb.playerID);
    const resumed = await returning.wait(m => m.type === 'state' && !m.paused);
    assert.equal(resumed.players[1].hp, sa.players[1].hp);
    const [old] = a.inbox.splice(0);
    assert.ok(old);
    a.send({ type: 'input', seq: 1, held: { right: true } });
    const moved = await returning.wait(m => m.type === 'state' && m.players[0].x > 275);
    assert.ok(moved.players[0].x > 275);
  } finally { await app.close(); }
});
