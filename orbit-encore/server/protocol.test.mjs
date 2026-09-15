import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { WebSocket } from 'ws';
import { createServer } from './server.mjs';
import { target } from './charts.mjs';

async function peer(url) {
  const ws = new WebSocket(url);
  const messages = [];
  ws.on('message', raw => messages.push(JSON.parse(raw)));
  await once(ws, 'open');
  return {
    ws, messages, send: data => ws.send(JSON.stringify(data)),
    wait: async predicate => {
      const until = Date.now() + 3000;
      while (Date.now() < until) {
        const index = messages.findIndex(predicate);
        if (index >= 0) return messages.splice(index, 1)[0];
        await new Promise(resolve => setTimeout(resolve, 5));
      }
      throw new Error('Timed out waiting for protocol message');
    },
  };
}

test('real WebSocket peers: room limits, common start, independent input, reconnect, result and rematch', async () => {
  let time = Date.now();
  const events = [];
  const server = createServer({ port: 0, now: () => time, log: row => events.push(JSON.parse(row)) });
  await once(server.httpServer, 'listening');
  const url = `ws://127.0.0.1:${server.httpServer.address().port}`;
  const a = await peer(url);
  const b = await peer(url);
  const outsider = await peer(url);
  try {
    a.send({ type: 'join', name: 'Nova' });
    const joinedA = await a.wait(m => m.type === 'joined');
    b.send({ type: 'join', name: 'Lumi', room: joinedA.room });
    const joinedB = await b.wait(m => m.type === 'joined');
    assert.notEqual(joinedA.id, joinedB.id);
    outsider.send({ type: 'join', name: 'Third', room: joinedA.room });
    assert.match((await outsider.wait(m => m.type === 'error')).message, /full/);
    b.send({ type: 'select', songID: 'neon' });
    assert.match((await b.wait(m => m.type === 'error')).message, /host/);
    a.send({ type: 'ready', ready: true });
    b.send({ type: 'ready', ready: true });
    const startA = await a.wait(m => m.phase === 'playing');
    const startB = await b.wait(m => m.phase === 'playing');
    assert.equal(startA.startAt, startB.startAt);
    assert.equal(startA.songID, startB.songID);
    const first = joinedA.charts[0].notes[0];
    time = startA.startAt + first.time * 1000;
    a.send({ type: 'input', matchID: startA.matchID, seq: 1, at: time, pointer: 1, phase: 'down', ...target(first.lane) });
    b.send({ type: 'input', matchID: startA.matchID, seq: 1, at: time + 75, pointer: 1, phase: 'down', ...target(first.lane) });
    const scored = await a.wait(m => m.phase === 'playing' && m.players.every(p => p.score > 0));
    assert.ok(scored.players[0].score > scored.players[1].score);
    b.ws.close();
    await once(b.ws, 'close');
    const resumed = await peer(url);
    resumed.send({ type: 'join', room: joinedA.room, token: joinedB.token, name: 'Lumi' });
    const resumeAck = await resumed.wait(m => m.type === 'joined');
    assert.equal(resumeAck.id, joinedB.id);
    const resumeState = await resumed.wait(m => m.phase === 'playing');
    assert.equal(resumeState.players[1].score, scored.players[1].score);
    time = startA.startAt + (joinedA.charts[0].duration + 1) * 1000;
    const resultA = await a.wait(m => m.phase === 'results');
    const resultB = await resumed.wait(m => m.phase === 'results');
    assert.deepEqual(resultA.players.map(p => p.score), resultB.players.map(p => p.score));
    a.send({ type: 'rematch' });
    resumed.send({ type: 'rematch' });
    const lobby = await a.wait(m => m.phase === 'lobby' && m.matchID === 1 && m.players.every(p => p.score === 0));
    assert.ok(lobby.players.every(p => !p.ready));
    assert.ok(events.some(e => e.event === 'results'));
    resumed.ws.close();
  } finally {
    a.ws.close(); b.ws.close(); outsider.ws.close();
    await server.close();
  }
});

test('input bursts preserve scoring without amplifying snapshot traffic', async () => {
  let time = Date.now();
  const server = createServer({ port: 0, now: () => time, log: () => {} });
  await once(server.httpServer, 'listening');
  const url = `ws://127.0.0.1:${server.httpServer.address().port}`;
  const a = await peer(url);
  const b = await peer(url);
  try {
    a.send({ type: 'join', name: 'Nova' });
    const joined = await a.wait(m => m.type === 'joined');
    b.send({ type: 'join', name: 'Lumi', room: joined.room });
    await b.wait(m => m.type === 'joined');
    a.send({ type: 'ready', ready: true });
    b.send({ type: 'ready', ready: true });
    const start = await a.wait(m => m.phase === 'playing');
    await b.wait(m => m.phase === 'playing');
    a.messages.length = 0;
    const first = joined.charts[0].notes[0];
    time = start.startAt + first.time * 1000;
    for (let seq = 1; seq <= 100; seq++) {
      a.send({ type: 'input', matchID: start.matchID, seq, at: time, pointer: 1,
        phase: seq === 1 ? 'down' : 'move', ...target(first.lane) });
    }
    a.send({ type: 'ping', sentAt: time });
    await a.wait(m => m.type === 'pong');
    assert.ok(a.messages.filter(m => m.type === 'state').length < 10);
    const scored = await b.wait(m => m.phase === 'playing' && m.players[0].score > 0);
    assert.equal(scored.players[0].counts.PERFECT, 1);
  } finally {
    a.ws.close(); b.ws.close();
    await server.close();
  }
});
