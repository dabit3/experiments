import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import fs from 'node:fs';
import { WebSocket } from 'ws';
import { newPerformance, hit, sweep } from './game.mjs';
import { startServer } from './server.mjs';

const chart = [
  { id: 0, cell: 0, time: 1 },
  { id: 1, cell: 15, time: 1 },
  { id: 2, cell: 5, time: 2 },
];
const player = () => ({ performance: newPerformance() });
test('simultaneous opposite corners score independently, with duplicate protection', () => {
  const p = player();
  assert.equal(hit(p, chart, 100, { cell: 0, seq: 1, at: 101 }, 101).label, 'PERFECT');
  assert.equal(hit(p, chart, 100, { cell: 15, seq: 2, at: 101 }, 101).label, 'PERFECT');
  assert.equal(p.performance.combo, 2);
  assert.equal(hit(p, chart, 100, { cell: 15, seq: 2, at: 101 }, 101), null);
  assert.equal(p.performance.perfect, 2);
});
test('timing boundaries are symmetric and missed notes cannot score twice', () => {
  for (const [offset, label] of [[0, 'PERFECT'], [.045, 'PERFECT'], [.046, 'GREAT'], [.09, 'GREAT'], [.091, 'GOOD'], [.14, 'GOOD']]) {
    for (const sign of [-1, 1]) {
      const p = player();
      assert.equal(hit(p, chart, 100, { cell: 0, seq: 1, at: 101 + sign * offset }, 101 + sign * offset).label, label);
    }
  }
  const p = player();
  sweep(p, chart, 100, 103);
  assert.equal(p.performance.miss, 3);
  assert.equal(hit(p, chart, 100, { cell: 0, seq: 1, at: 101 }, 103), null);
  assert.equal(p.performance.score, 0);
});
test('perfect finish equals one million; incorrect cells and forged time cannot add points', () => {
  const p = player();
  let seq = 0;
  for (const n of chart) hit(p, chart, 100, { cell: n.cell, seq: ++seq, at: 100 + n.time }, 100 + n.time);
  assert.equal(p.performance.score, 1000000);
  assert.equal(p.performance.accuracy, 100);
  const q = player();
  for (const input of [{ cell: 2, at: 101 }, { cell: 0, at: 101 }, { cell: 19, at: 105 }, { cell: 0, at: NaN }]) {
    assert.equal(hit(q, chart, 100, { ...input, seq: ++seq }, 105), null);
  }
  assert.equal(q.performance.score, 0);
});
test('authored charts cover all cells, have simultaneous notes and align with PCM duration', () => {
  const catalog = JSON.parse(fs.readFileSync(new URL('../Resources/catalog.json', import.meta.url)));
  for (const song of catalog) {
    const wav = fs.readFileSync(new URL(`../Resources/${song.id}.wav`, import.meta.url));
    assert.equal(wav.toString('ascii', 0, 4), 'RIFF');
    assert.ok(Math.abs((wav.length - 44) / 88200 - song.duration) < .001);
    for (const notes of Object.values(song.charts)) {
      assert.equal(new Set(notes.map(n => n.cell)).size, 16);
      assert.ok(notes.some((n, i) => i > 0 && n.time === notes[i - 1].time));
      assert.equal(new Set(notes.map(n => `${n.cell}:${n.time}`)).size, notes.length);
      assert.ok(notes.every(n => n.time > 0 && n.time < song.duration));
    }
  }
});

async function peer(port) {
  const ws = new WebSocket(`ws://127.0.0.1:${port}`);
  const messages = [];
  ws.on('message', raw => messages.push(JSON.parse(raw)));
  await once(ws, 'open');
  return {
    ws, messages,
    send: value => ws.send(JSON.stringify(value)),
    wait: async predicate => {
      for (let i = 0; i < 150; i++) {
        const found = messages.find(predicate);
        if (found) return found;
        await new Promise(resolve => setTimeout(resolve, 10));
      }
      assert.fail(`Expected message missing: ${messages.map(m => m.type).join(',')}`);
    },
  };
}
test('real WebSocket room: capacity, host selection, ready gate, shared outcome, token rejoin and rematch', async () => {
  let now = 1000;
  const app = startServer({ port: 0, now: () => now, logger: () => {} });
  await once(app.server, 'listening');
  const port = app.server.address().port;
  try {
    const a = await peer(port), b = await peer(port), outsider = await peer(port);
    a.send({ type: 'create', code: 'TEST', playerID: 'player-one', name: 'A' });
    const welcome = await a.wait(m => m.type === 'welcome');
    b.send({ type: 'join', code: 'TEST', playerID: 'player-two', name: 'B' });
    await b.wait(m => m.type === 'welcome');
    outsider.send({ type: 'join', code: 'TEST', playerID: 'player-three', name: 'C' });
    assert.match((await outsider.wait(m => m.type === 'error')).message, /full/);
    b.send({ type: 'select', songID: 'afterglow', difficulty: 'BASIC' });
    assert.match((await b.wait(m => m.type === 'error')).message, /host/);
    a.send({ type: 'ready', ready: true });
    await a.wait(m => m.room?.players[0].ready);
    assert.equal(app.rooms.get('TEST').phase, 'lobby');
    b.send({ type: 'ready', ready: true });
    const start = await b.wait(m => m.room?.phase === 'playing');
    const first = JSON.parse(fs.readFileSync(new URL('../Resources/catalog.json', import.meta.url)))[0].charts.ADVANCED[0];
    now = start.room.startAt + first.time;
    a.send({ type: 'tap', cell: first.cell, seq: 1, at: now, round: 1, source: 'touch' });
    b.send({ type: 'tap', cell: first.cell, seq: 1, at: now - .08, round: 1, source: 'driver' });
    assert.equal((await a.wait(m => m.type === 'judgment')).label, 'PERFECT');
    assert.equal((await b.wait(m => m.type === 'judgment')).label, 'GREAT');
    now += 100;
    const ar = await a.wait(m => m.room?.phase === 'results');
    const br = await b.wait(m => m.room?.phase === 'results');
    assert.deepEqual(ar.room.players, br.room.players);
    assert.ok(ar.room.players[0].score > ar.room.players[1].score);
    a.ws.close();
    await once(a.ws, 'close');
    const bad = await peer(port);
    bad.send({ type: 'join', code: 'TEST', playerID: 'player-one', name: 'Imposter', token: 'bad' });
    assert.match((await bad.wait(m => m.type === 'error')).message, /token/);
    const rejoin = await peer(port);
    rejoin.send({ type: 'join', code: 'TEST', playerID: 'player-one', name: 'A', token: welcome.token });
    await rejoin.wait(m => m.type === 'welcome');
    rejoin.send({ type: 'ready', ready: true });
    b.send({ type: 'ready', ready: true });
    const second = await rejoin.wait(m => m.room?.round === 2);
    assert.equal(second.room.players[0].score, 0);
    assert.equal(second.room.players[1].score, 0);
  } finally { await app.close(); }
});

test('completed outcome survives the winner leaving, with results cleared only on rematch', async () => {
  let now = 2000;
  const app = startServer({ port: 0, now: () => now, logger: () => {} });
  await once(app.server, 'listening');
  const port = app.server.address().port;
  try {
    const a = await peer(port), b = await peer(port);
    a.send({ type: 'create', code: 'KEEP', playerID: 'winner-one', name: 'Winner' });
    await a.wait(m => m.type === 'welcome');
    b.send({ type: 'join', code: 'KEEP', playerID: 'runner-two', name: 'Runner' });
    await b.wait(m => m.type === 'welcome');
    a.send({ type: 'ready', ready: true });
    b.send({ type: 'ready', ready: true });
    const start = await a.wait(m => m.room?.phase === 'playing');
    const note = JSON.parse(fs.readFileSync(new URL('../Resources/catalog.json', import.meta.url)))[0].charts.ADVANCED[0];
    now = start.room.startAt + note.time;
    a.send({ type: 'tap', cell: note.cell, seq: 1, at: now, round: 1 });
    await a.wait(m => m.type === 'judgment');
    now += 100;
    const first = await b.wait(m => m.room?.phase === 'results');
    assert.deepEqual(first.room.results, first.room.players);
    assert.ok(first.room.results[0].score > first.room.results[1].score);
    a.send({ type: 'ready', ready: true });
    b.send({ type: 'ready', ready: true });
    const rematch = await a.wait(m => m.room?.round === 2);
    assert.deepEqual(rematch.room.results, []);
    now = rematch.room.startAt + note.time;
    a.send({ type: 'tap', cell: note.cell, seq: 2, at: now, round: 2 });
    await a.wait(m => m.type === 'judgment' && m.at === now);
    now += 100;
    const second = await b.wait(m => m.room?.phase === 'results' && m.room.round === 2);
    a.send({ type: 'leave' });
    const departed = await b.wait(m => m.room?.phase === 'results' && m.room.players.length === 1);
    assert.equal(departed.room.hostID, 'runner-two');
    assert.equal(departed.room.players[0].id, 'runner-two');
    assert.deepEqual(departed.room.results, second.room.results);
    assert.ok(departed.room.results[0].score > departed.room.results[1].score);
  } finally { await app.close(); }
});
