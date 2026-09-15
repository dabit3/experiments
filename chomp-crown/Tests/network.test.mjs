import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import WebSocket from '../Server/node_modules/ws/wrapper.mjs';
import { createServer } from '../Server/server.mjs';

async function peer(url) {
  const ws = new WebSocket(url);
  ws.messages = [];
  ws.on('message', raw => ws.messages.push(JSON.parse(raw)));
  await once(ws, 'open');
  return ws;
}
async function until(ws, predicate, timeout = 4000) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    const result = ws.messages.find(predicate);
    if (result) return result;
    await new Promise(resolve => setTimeout(resolve, 15));
  }
  throw new Error('Timed out waiting for protocol message');
}
const send = (ws, value) => ws.send(JSON.stringify(value));
test('real distinct peers join, ready, move, reject takeover and recover their own identity', async () => {
  const service = createServer({ port: 0, host: '127.0.0.1', logger: () => {} });
  await once(service.server, 'listening');
  const url = `ws://127.0.0.1:${service.server.address().port}`;
  try {
    const a = await peer(url), b = await peer(url);
    send(a, { type: 'join', create: true, playerId: 'network-a', name: 'Gold' });
    const joined = await until(a, m => m.type === 'joined');
    send(b, { type: 'join', code: joined.code, playerId: 'network-b', name: 'Rose' });
    await until(b, m => m.type === 'joined');
    send(a, { type: 'ready' }); send(b, { type: 'ready' });
    const state = await until(b, m => m.type === 'state' && m.phase === 'playing');
    assert.equal(state.players.length, 2);
    assert.notEqual(state.you, joined.you);
    assert.ok(state.players.every(p => !('token' in p)));
    send(a, { type: 'input', seq: 20, direction: 'up' });
    const moved = await until(b, m => m.type === 'state' && m.players[0].lastSeq === 20);
    assert.equal(moved.players[0].wanted, 'up');
    const intruder = await peer(url);
    send(intruder, { type: 'join', code: joined.code, playerId: 'network-a', name: 'Fake' });
    assert.match((await until(intruder, m => m.type === 'error')).message, /token/);
    intruder.close();
    a.close();
    await once(a, 'close');
    await until(b, m => m.type === 'state' && m.pauseReason.length > 0);
    const replacement = await peer(url);
    send(replacement, { type: 'join', code: joined.code, playerId: 'network-a', token: joined.token });
    const recovered = await until(replacement, m => m.type === 'joined');
    assert.equal(recovered.lastSeq, 20);
    assert.equal(recovered.you, joined.you);
    const resumed = await until(replacement, m => m.type === 'state' && !m.pauseReason);
    assert.equal(resumed.players.length, 2);
  } finally { await service.close(); }
});
test('unknown rooms, room capacity and malformed frames are handled explicitly', async () => {
  const service = createServer({ port: 0, host: '127.0.0.1', logger: () => {} });
  await once(service.server, 'listening');
  const url = `ws://127.0.0.1:${service.server.address().port}`;
  try {
    const a = await peer(url);
    a.send('{');
    assert.match((await until(a, m => m.type === 'error')).message, /Invalid/);
    send(a, { type: 'join', code: 'NOPE', playerId: 'unknown-a' });
    await until(a, m => m.type === 'error' && m.message.includes('not found'));
    send(a, { type: 'join', create: true, playerId: 'capacity-a' });
    const joined = await until(a, m => m.type === 'joined');
    for (let i = 0; i < 4; i++) {
      const p = await peer(url);
      send(p, { type: 'join', code: joined.code, playerId: `capacity-${i}` });
      const response = await until(p, m => ['joined', 'error'].includes(m.type));
      assert.equal(response.type, i < 3 ? 'joined' : 'error');
    }
  } finally { await service.close(); }
});

test('completed winner identity survives leaving the roster and resets on rematch', async () => {
  const service = createServer({ port: 0, host: '127.0.0.1', logger: () => {} });
  await once(service.server, 'listening');
  const url = `ws://127.0.0.1:${service.server.address().port}`;
  try {
    const a = await peer(url), b = await peer(url);
    send(a, { type: 'join', create: true, playerId: 'winner-a', name: 'Gold' });
    const joined = await until(a, m => m.type === 'joined');
    send(b, { type: 'join', code: joined.code, playerId: 'winner-b', name: 'Rose' });
    await until(b, m => m.type === 'joined');
    const game = service.rooms.get(joined.code);
    const winner = game.players[0];
    game.ready(winner.id); game.ready('winner-b');
    game.phase = 'playing'; winner.crowns = 1;
    game.endRound(winner, 'fixture');
    const completed = await until(b, m => m.type === 'state' && m.phase === 'matchOver');
    assert.deepEqual(completed.winner, { id: winner.id, name: 'Gold', color: 0 });
    game.ready(winner.id); game.ready('winner-b');
    assert.equal(game.snapshot().winner, null);
    game.phase = 'playing'; winner.crowns = 1;
    game.endRound(winner, 'fixture');
    send(a, { type: 'leave' });
    const departed = await until(b, m => m.type === 'state' && m.players.length === 1);
    assert.equal(departed.phase, 'matchOver');
    assert.equal(departed.winnerId, winner.id);
    assert.deepEqual(departed.winner, completed.winner);
  } finally { await service.close(); }
});
