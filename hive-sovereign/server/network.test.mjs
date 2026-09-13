import test from 'node:test';
import assert from 'node:assert/strict';
import { WebSocket } from 'ws';
import { createServer } from './server.mjs';

async function client(port) {
  const ws = new WebSocket(`ws://127.0.0.1:${port}`);
  const messages = [];
  ws.on('message', data => messages.push(JSON.parse(data)));
  await new Promise(resolve => ws.once('open', resolve));
  return {
    ws, messages,
    send: data => ws.send(JSON.stringify(data)),
    wait: (predicate, timeout = 7000) => new Promise((resolve, reject) => {
      const started = Date.now();
      const timer = setInterval(() => {
        const found = messages.find(predicate);
        if (found) { clearInterval(timer); resolve(found); }
        else if (Date.now() - started > timeout) { clearInterval(timer); reject(new Error('Message timeout')); }
      }, 10);
    }),
  };
}

test('real sockets: room bounds, readiness, ordered own-team input, disconnect and authenticated resume', async () => {
  const app = createServer({ port: 0, host: '127.0.0.1', log: () => {} });
  const port = await app.listen();
  try {
    const a = await client(port);
    a.send({ type: 'hello', create: true, id: 'blue-guest-123', name: 'Blue' });
    const welcome = await a.wait(m => m.type === 'welcome');
    const b = await client(port);
    b.send({ type: 'hello', room: welcome.room, id: 'gold-guest-123', name: 'Gold' });
    await b.wait(m => m.type === 'welcome');
    const c = await client(port);
    c.send({ type: 'hello', room: welcome.room, id: 'third-guest-123', name: 'Third' });
    assert.match((await c.wait(m => m.type === 'error')).message, /full/);
    a.send({ type: 'ready' }); b.send({ type: 'ready' });
    await a.wait(m => m.type === 'state' && m.phase === 'playing');
    a.send({ type: 'input', seq: 10, move: -1, jump: true, action: false, dive: false });
    a.send({ type: 'input', seq: 9, move: 1, jump: false, action: false, dive: false });
    const state = await a.wait(m => m.type === 'state' && m.peers[0].seq === 10);
    assert.equal(state.peers[0].inputs, 1);
    assert.equal(state.game.units.filter(u => u.human).length, 2);
    a.ws.close();
    await b.wait(m => m.type === 'state' && m.paused);
    const bad = await client(port);
    bad.send({ type: 'hello', room: welcome.room, id: welcome.id, name: 'Impostor', token: 'bad' });
    assert.match((await bad.wait(m => m.type === 'error')).message, /token/);
    const resumed = await client(port);
    resumed.send({ type: 'hello', room: welcome.room, id: welcome.id, name: 'Blue', token: welcome.token });
    const back = await resumed.wait(m => m.type === 'welcome');
    assert.equal(back.team, 0);
    const continued = await resumed.wait(m => m.type === 'state' && !m.paused);
    assert.equal(continued.match, 1);
    assert.equal(continued.peers[0].id, welcome.id);
  } finally { await app.close(); }
});
