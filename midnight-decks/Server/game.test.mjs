import test from 'node:test';
import assert from 'node:assert/strict';
import { WebSocket } from 'ws';
import { freshStats, processInput, expireNotes, judgment } from './game.mjs';
import { createServer } from './server.mjs';

test('calibrated judgment boundaries are inclusive and symmetric', () => {
  for (const sign of [-1, 1]) {
    for (const [ms, result] of [[25, 'perfect'], [26, 'great'], [55, 'great'], [56, 'good'], [95, 'good'], [96, 'bad'], [140, 'bad'], [141, 'poor']]) {
      assert.equal(judgment(ms * sign), result);
    }
  }
});
test('a charge needs both endpoints, duplicate heads cannot score, early release breaks combo', () => {
  const chart = { notes: [{ id: 0, lane: 3, time: 1000, duration: 1000 }] };
  const s = freshStats(chart.notes);
  assert.ok(processInput(s, chart, { lane: 3, down: true, time: 1000 }));
  assert.equal(processInput(s, chart, { lane: 3, down: true, time: 1000 }), false);
  processInput(s, chart, { lane: 3, down: false, time: 1500 });
  assert.equal(s.score, 2); assert.equal(s.counts.poor, 1); assert.equal(s.combo, 0);
  expireNotes(s, chart, 10000);
  assert.equal(s.judged, 2);
});
test('chords score independently and silence exhausts all endpoints exactly once', () => {
  const chart = { notes: [{ id: 0, lane: 1, time: 1000, duration: 0 }, { id: 1, lane: 7, time: 1000, duration: 500 }] };
  const s = freshStats(chart.notes);
  processInput(s, chart, { lane: 1, down: true, time: 1000 });
  processInput(s, chart, { lane: 7, down: true, time: 1025 });
  processInput(s, chart, { lane: 7, down: false, time: 1500 });
  assert.equal(s.score, 6); assert.equal(s.maxCombo, 3);
  const silent = freshStats(chart.notes);
  expireNotes(silent, chart, 10000); expireNotes(silent, chart, 11000);
  assert.equal(silent.counts.poor, 3);
});

function peer(url) {
  const socket = new WebSocket(url);
  const messages = [];
  socket.on('message', raw => messages.push(JSON.parse(raw)));
  const send = data => socket.send(JSON.stringify(data));
  const wait = async predicate => {
    const until = Date.now() + 4000;
    while (Date.now() < until) {
      const m = messages.find(predicate);
      if (m) return m;
      await new Promise(r => setTimeout(r, 10));
    }
    throw Error('Message timeout');
  };
  return { socket, messages, send, wait, open: new Promise(r => socket.on('open', r)) };
}

test('real sockets: unique peers, room cap, common start, ordered scoring, result, rematch, token rejoin', async () => {
  const app = createServer({ port: 0, host: '127.0.0.1', log: () => {}, startDelay: 50 });
  await new Promise(r => app.server.on('listening', r));
  const url = `ws://127.0.0.1:${app.server.address().port}`;
  const a = peer(url), b = peer(url), extra = peer(url);
  try {
    await Promise.all([a.open, b.open, extra.open]);
    a.send({ type: 'join', create: true, room: 'TEST', name: 'Nova' });
    const first = await a.wait(m => m.type === 'joined');
    b.send({ type: 'join', room: 'TEST', name: 'Echo' });
    const second = await b.wait(m => m.type === 'joined');
    assert.notEqual(first.you, second.you);
    extra.send({ type: 'join', room: 'TEST', name: 'Third' });
    assert.match((await extra.wait(m => m.type === 'error')).message, /two DJs/);
    a.send({ type: 'ready' }); b.send({ type: 'ready' });
    const startedA = await a.wait(m => m.state?.phase === 'playing');
    const startedB = await b.wait(m => m.state?.phase === 'playing');
    assert.equal(startedA.state.startAt, startedB.state.startAt);
    const room = app.rooms.get('TEST');
    // Advance only the test clock to exercise a real WebSocket input at note one.
    room.startAt = Date.now() - 2000;
    a.send({ type: 'input', seq: 1, lane: 1, down: true, time: 2000 });
    a.send({ type: 'input', seq: 1, lane: 1, down: true, time: 2000 });
    b.send({ type: 'input', seq: 1, lane: 1, down: true, time: 2040 });
    await a.wait(m => m.state?.players.every(p => p.stats.score > 0));
    assert.equal(room.players[0].stats.score, 2);
    assert.equal(room.players[1].stats.score, 1);
    a.send({ type: 'input', seq: 2, lane: 3, down: true, time: 50000 });
    await new Promise(r => setTimeout(r, 60));
    assert.equal(room.players[0].stats.score, 2);
    room.startAt = Date.now() - 65000;
    const result = await b.wait(m => m.state?.phase === 'result');
    assert.equal(result.state.winner, first.you);
    a.send({ type: 'ready' }); b.send({ type: 'ready' });
    await a.wait(m => m.state?.round === 2);
    assert.equal(room.players[0].stats.score, 0);
    b.socket.close();
    await new Promise(r => b.socket.on('close', r));
    const rejoined = peer(url); await rejoined.open;
    rejoined.send({ type: 'join', name: 'Echo', room: 'TEST', token: second.token });
    const resumed = await rejoined.wait(m => m.type === 'joined');
    assert.equal(resumed.you, second.you);
    assert.equal(resumed.state.round, 2);
    rejoined.socket.close();
  } finally { await app.close(); }
});
