import test from 'node:test';
import assert from 'node:assert/strict';
import { WebSocket } from 'ws';
import { once } from 'node:events';
import { fighter, room, input, step, resetRound } from './combat.mjs';
import { startServer } from './server.mjs';

function duel() {
  const r = room('TEST');
  r.players = [fighter('a', 'A', 'rook', 0), fighter('b', 'B', 'vesper', 1)];
  r.phase = 'fight';
  return r;
}
function ticks(r, count) { for (let i = 0; i < count; i++) step(r); }
function press(r, p, action, value = 0) { input(r, p, { seq: p.seq + 1, action, value }); }

test('ordered inputs, startup/range, whiff recovery and guard chip', () => {
  const r = duel(), [a, b] = r.players;
  press(r, a, 'heavy');
  ticks(r, 60);
  assert.equal(b.hp, 100, 'a long range whiff cannot damage');
  a.x = b.x - 100;
  press(r, b, 'guard', 1);
  press(r, a, 'slash');
  ticks(r, 5);
  assert.equal(b.hp, 100, 'startup is not active');
  ticks(r, 15);
  assert.equal(b.hp, 98, 'guard reduces damage to chip');
  assert.equal(input(r, a, { seq: a.seq, action: 'jump' }), false, 'replayed input rejected');
});

test('air dash is limited until landing; cancels spend meter and release recovery', () => {
  const r = duel(), [a, b] = r.players;
  press(r, a, 'jump'); ticks(r, 7);
  press(r, a, 'dash'); ticks(r, 17);
  assert(a.y > 0); assert(a.airDash);
  press(r, a, 'dash'); ticks(r, 1);
  assert.equal(a.dash, 0, 'second air dash rejected');
  ticks(r, 90);
  assert.equal(a.airDash, false);
  a.meter = 65; a.x = 400; b.x = 800;
  press(r, a, 'heavy'); ticks(r, 4);
  press(r, a, 'cancel'); ticks(r, 1);
  assert.equal(a.attack, '');
  assert.equal(a.meter, 15);
  assert(b.slow > 0);
  assert(r.events.some(e => e.color === 'PURPLE'));
});

test('projectile travels, scores shared damage, and best of three resolves', () => {
  const r = duel(), [a, b] = r.players;
  press(r, a, 'special'); ticks(r, 22);
  assert.equal(b.hp, 100);
  assert.equal(r.projectiles.length, 1);
  ticks(r, 60);
  assert.equal(b.hp, 87);
  a.hp = 70; b.hp = 12; r.seconds = 0.01;
  ticks(r, 1);
  assert.equal(r.phase, 'roundEnd'); assert.equal(a.wins, 1);
  resetRound(r); ticks(r, 150);
  a.hp = 70; b.hp = 12; r.seconds = 0.01;
  ticks(r, 1);
  assert.equal(r.winner, a.id); assert.equal(r.phase, 'result');
});

function inbox(ws) {
  const buffer = [], waiters = [];
  ws.on('message', raw => {
    const msg = JSON.parse(raw);
    buffer.push(msg);
    for (const wake of waiters.splice(0)) wake();
  });
  return async predicate => {
    for (let tries = 0; tries < 200; tries++) {
      const index = buffer.findIndex(predicate);
      if (index >= 0) return buffer.splice(index, 1)[0];
      await new Promise(resolve => {
        const timer = setTimeout(resolve, 50);
        waiters.push(() => { clearTimeout(timer); resolve(); });
      });
    }
    throw new Error('Network assertion timed out');
  };
}

test('real WebSocket peers: room limits, shared state, pause, token reconnect and rematch', async () => {
  const app = startServer(0, '127.0.0.1');
  await once(app.server, 'listening');
  const url = `ws://127.0.0.1:${app.server.address().port}`;
  const sockets = [];
  async function client() {
    const ws = new WebSocket(url); sockets.push(ws);
    const read = inbox(ws);
    await once(ws, 'open');
    return { ws, read, send: msg => ws.send(JSON.stringify(msg)) };
  }
  try {
    const a = await client();
    a.send({ type: 'join', name: 'Rook' });
    const welcomeA = await a.read(m => m.type === 'welcome');
    const b = await client();
    b.send({ type: 'join', name: 'Vesper', code: welcomeA.code, style: 'vesper' });
    const welcomeB = await b.read(m => m.type === 'welcome');
    assert.notEqual(welcomeA.id, welcomeB.id);
    const c = await client();
    c.send({ type: 'join', code: welcomeA.code });
    assert.match((await c.read(m => m.type === 'error')).message, /full/);
    a.send({ type: 'ready' }); b.send({ type: 'ready' });
    const stateA = await a.read(m => m.phase === 'fight');
    const stateB = await b.read(m => m.phase === 'fight' && m.tick === stateA.tick);
    assert.deepEqual(stateA.players, stateB.players);
    b.ws.close(); await once(b.ws, 'close');
    await a.read(m => m.paused);
    const reconnect = await client();
    reconnect.send({ type: 'join', token: welcomeB.token });
    assert.equal((await reconnect.read(m => m.type === 'welcome')).id, welcomeB.id);
    await a.read(m => m.type === 'state' && !m.paused && m.players.every(p => p.connected));
    const game = app.rooms.get(welcomeA.code);
    game.phase = 'result'; game.winner = welcomeA.id;
    a.send({ type: 'rematch' }); reconnect.send({ type: 'rematch' });
    const rematch = await a.read(m => m.matches === 1);
    assert.equal(rematch.round, 1); assert(rematch.players.every(p => p.hp === 100));
  } finally {
    for (const ws of sockets) ws.terminate();
    await app.close();
  }
});
