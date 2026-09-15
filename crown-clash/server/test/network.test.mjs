import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { WebSocket } from 'ws';
import { startServer } from '../server.mjs';

function waitFor(socket, predicate) {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => { socket.off('message', handler); reject(new Error('Timed out')); }, 6000);
    const handler = (raw) => {
      const message = JSON.parse(raw);
      if (predicate(message)) {
        clearTimeout(timeout); socket.off('message', handler); resolve(message);
      }
    };
    socket.on('message', handler);
  });
}
const send = (socket, message) => socket.send(JSON.stringify(message));

test('real socket peers share snapshots, reject third player, and resume paused roster', async () => {
  const service = startServer(0, '127.0.0.1', () => {});
  await once(service.http, 'listening');
  const url = `ws://127.0.0.1:${service.http.address().port}`;
  const sockets = [];
  const connect = async () => {
    const socket = new WebSocket(url);
    sockets.push(socket);
    await once(socket, 'open');
    return socket;
  };
  try {
    const a = await connect();
    const aWelcome = waitFor(a, (message) => message.type === 'welcome');
    send(a, { type: 'hello', id: 'alpha', name: 'Alpha', code: 'NET123', create: true, roster: ['rook', 'vesper', 'atlas'] });
    const welcome = await aWelcome;
    const b = await connect();
    const bWelcome = waitFor(b, (message) => message.type === 'welcome');
    send(b, { type: 'hello', id: 'bravo', name: 'Bravo', code: 'NET123', roster: ['sora', 'kestrel', 'jin'] });
    await bWelcome;
    const third = await connect();
    const rejected = waitFor(third, (message) => message.type === 'error');
    send(third, { type: 'hello', id: 'third', code: 'NET123', roster: ['rook', 'vesper', 'atlas'] });
    assert.match((await rejected).message, /full/);
    send(a, { type: 'ready', roster: ['rook', 'vesper', 'atlas'] });
    send(b, { type: 'ready', roster: ['sora', 'kestrel', 'jin'] });
    const [stateA, stateB] = await Promise.all([
      waitFor(a, (message) => message.phase === 'fight'),
      waitFor(b, (message) => message.phase === 'fight'),
    ]);
    assert.deepEqual(stateA.peers.map((peer) => peer.id), ['alpha', 'bravo']);
    assert.deepEqual(stateA.peers, stateB.peers);
    const paused = waitFor(b, (message) => message.paused);
    a.close();
    await paused;
    const resumed = await connect();
    const resumedWelcome = waitFor(resumed, (message) => message.type === 'welcome');
    send(resumed, { type: 'hello', id: 'alpha', token: welcome.token, code: 'NET123' });
    await resumedWelcome;
    const live = await waitFor(b, (message) => message.type === 'state' && !message.paused);
    assert.equal(live.peers[0].id, 'alpha');
    assert.equal(live.peers[0].roster.length, 3);
    assert.ok(live.events.some((event) => event.kind === 'reconnected'));
  } finally {
    for (const socket of sockets) socket.terminate();
    await service.close();
  }
});
