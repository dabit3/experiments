import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { WebSocket } from 'ws';
import { startServer, charts } from './server.mjs';

test('complete real-time two-peer battle and mutual rematch', { timeout: 65000 }, async () => {
  const running = startServer(0, '127.0.0.1');
  await once(running.server, 'listening');
  const url = `ws://127.0.0.1:${running.server.address().port}`;
  const peers = [];
  let driver;
  async function waitFor(predicate, timeout = 3000) {
    const end = Date.now() + timeout;
    while (Date.now() < end) {
      if (predicate()) return;
      await new Promise((resolve) => setTimeout(resolve, 10));
    }
    throw new Error('Timed out waiting for protocol assertion');
  }
  try {
    for (const name of ['Protocol Aria', 'Protocol Nova']) {
      const ws = new WebSocket(url);
      const peer = { ws, joined: null, state: null, seq: 0, started: new Set(), ended: new Set() };
      ws.on('message', (data) => {
        const m = JSON.parse(data);
        if (m.type === 'joined') peer.joined = m;
        if (m.type === 'state') peer.state = m;
      });
      await once(ws, 'open');
      ws.send(JSON.stringify({ type: 'join', name, create: peers.length === 0, room: peers[0]?.joined.room }));
      await waitFor(() => peer.joined);
      peers.push(peer);
    }
    for (const peer of peers) peer.ws.send(JSON.stringify({ type: 'ready', ready: true }));
    await waitFor(() => peers.every((p) => p.state?.phase === 'playing'));
    assert.equal(peers[0].state.startAt, peers[1].state.startAt);
    const chart = charts[0];
    const start = peers[0].state.startAt;
    driver = setInterval(() => {
      for (const [index, peer] of peers.entries()) {
        const time = (Date.now() - start) / 1000 - index * 0.06;
        const send = (note, action, x, y) => peer.ws.send(JSON.stringify({
          type: 'input', seq: ++peer.seq, at: Date.now(), pointer: `chart-${note.id}`, action, x, y,
        }));
        for (const note of chart.notes) {
          const elapsed = time - note.time;
          if (elapsed >= (note.kind === 'air' ? -0.055 : 0) && !peer.started.has(note.id)) {
            peer.started.add(note.id);
            send(note, 'down', note.lane + note.width / 2, 0.9);
          }
          if (!peer.started.has(note.id) || peer.ended.has(note.id)) continue;
          if (note.kind === 'air') {
            if (elapsed >= 0) {
              send(note, 'move', note.lane + note.width / 2, 0.65);
              send(note, 'up', note.lane + note.width / 2, 0.65);
              peer.ended.add(note.id);
            }
          } else if (note.duration && elapsed <= note.duration + 0.03) {
            const lane = note.lane + (note.endLane - note.lane) * Math.min(1, Math.max(0, elapsed / note.duration));
            send(note, 'move', lane + note.width / 2, 0.9);
          } else {
            send(note, 'up', note.endLane + note.width / 2, 0.9);
            peer.ended.add(note.id);
          }
        }
      }
    }, 16);
    await waitFor(() => peers.every((p) => p.state.phase === 'results'), 57000);
    clearInterval(driver);
    const a = peers[0].state;
    const b = peers[1].state;
    assert.deepEqual(a.players, b.players);
    assert.equal(a.players.length, 2);
    assert.ok(a.players[0].score > 900000);
    assert.ok(a.players[1].score > 850000);
    assert.ok(a.players[0].score > a.players[1].score);
    assert.ok(a.players[0].counts.critical > 100);
    assert.ok(a.players[1].counts.justice > 20);
    assert.equal(peers[0].started.size, chart.notes.length);
    assert.equal(peers[1].started.size, chart.notes.length);
    for (const peer of peers) peer.ws.send(JSON.stringify({ type: 'ready', ready: true }));
    await waitFor(() => peers.every((p) => p.state.round === 2 && p.state.phase === 'playing'));
    assert.ok(peers.every((p) => p.state.players.every((player) => player.score === 0)));
    assert.equal(peers[0].state.startAt, peers[1].state.startAt);
  } finally {
    clearInterval(driver);
    await running.close();
  }
});
