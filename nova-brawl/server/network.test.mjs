import test from 'node:test';
import assert from 'node:assert/strict';
import { WebSocket } from 'ws';
import { createGameServer } from './server.mjs';

function peer(url) {
  return new Promise(resolve => {
    const ws = new WebSocket(url);
    const messages = [];
    ws.on('message', raw => messages.push(JSON.parse(raw)));
    ws.on('open', () => resolve({ ws, messages, send: msg => ws.send(JSON.stringify(msg)) }));
  });
}
async function until(fn, ms = 5000) {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    const value = fn();
    if (value) return value;
    await new Promise(resolve => setTimeout(resolve, 20));
  }
  throw new Error('Network assertion timed out');
}
test('real sockets: room cap, ready, shared damage, resume identity and malformed payload', async () => {
  const server = createGameServer({ port: 0, host: '127.0.0.1', log: () => {} });
  const addr = await server.start();
  const url = `ws://127.0.0.1:${addr.port}`;
  try {
    const a = await peer(url), b = await peer(url), c = await peer(url);
    a.send({ type: 'join', create: true, code: 'NOVA', name: 'Flare' });
    const wa = await until(() => a.messages.find(m => m.type === 'welcome'));
    b.send({ type: 'join', code: 'NOVA', name: 'Ion' });
    const wb = await until(() => b.messages.find(m => m.type === 'welcome'));
    assert.notEqual(wa.id, wb.id);
    c.send({ type: 'join', code: 'NOVA', name: 'Third' });
    assert.match((await until(() => c.messages.find(m => m.type === 'error'))).message, /full/);
    a.send({ type: 'ready' }); b.send({ type: 'ready' });
    await until(() => b.messages.find(m => m.phase === 'playing'));
    a.send({ type: 'input', seq: 1, x: 0, z: 0, lift: 0, actions: ['shot'] });
    const damaged = await until(() => b.messages.find(m => m.type === 'state' && m.players[1].hp < 300));
    assert.equal(damaged.players[1].hp, 290);
    assert.ok(await until(() => a.messages.find(m => m.type === 'state' && m.players[1]?.hp === 290)));
    a.ws.close();
    await until(() => server.rooms.get('NOVA').players[0].connected === false);
    const resume = await peer(url);
    resume.send({ type: 'join', code: 'NOVA', name: 'Flare', token: wa.token });
    const welcome = await until(() => resume.messages.find(m => m.type === 'welcome'));
    assert.equal(welcome.id, wa.id);
    assert.equal(server.rooms.get('NOVA').players[1].hp, 290);
    resume.ws.send('{');
    assert.equal((await until(() => resume.messages.find(m => m.type === 'error'))).message, 'Invalid JSON');
  } finally { await server.close(); }
});
