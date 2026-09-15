import test from 'node:test';
import assert from 'node:assert/strict';
import { chartFor, newPlayer, applyHit, advanceRoom, publicRoom, resetPlayer } from '../server/game.mjs';

function fixture(notes = [{ id: 0, at: 2000, kind: 'don', big: false, duration: 0 }]) {
  const player = newPlayer('Hana');
  return { player, room: { phase: 'playing', startAt: 10000, chart: { notes, duration: 10000 }, players: [player, newPlayer('Sora')] } };
}
function hit(room, player, at, extra = {}) {
  return applyHit(room, player, { seq: 0, at, kind: 'don', hand: 'left', ...extra }, at);
}
test('accurate, edge, wrong-color and late input produce different judgments', () => {
  for (const [offset, kind, expected] of [[0, 'don', 'GOOD'], [45, 'don', 'GOOD'], [46, 'don', 'OK'], [100, 'don', 'OK'], [101, 'don', 'BAD'], [0, 'ka', 'BAD']]) {
    const { room, player } = fixture();
    hit(room, player, 12000 + offset, { kind });
    assert.equal(player.judgment, expected);
  }
});
test('big notes require opposite hands, same color and a tight pair window', () => {
  for (const [hand, delta, kind, doubles] of [['right', 50, 'don', true], ['left', 20, 'don', false], ['right', 76, 'don', false], ['right', 20, 'ka', false]]) {
    const { room, player } = fixture([{ id: 0, at: 2000, kind: 'don', big: true, duration: 0 }]);
    hit(room, player, 12000);
    hit(room, player, 12000 + delta, { seq: 1, hand, kind });
    assert.equal(player.score, doubles ? 2000 : 1000);
    assert.equal(player.bigHits, doubles ? 1 : 0);
  }
});
test('rolls accept both colors with rate bounds without adding to combo', () => {
  const { room, player } = fixture([{ id: 0, at: 2000, kind: 'roll', big: false, duration: 500 }]);
  hit(room, player, 12000);
  hit(room, player, 12010, { seq: 1 });
  hit(room, player, 12050, { seq: 2, kind: 'ka' });
  hit(room, player, 12510, { seq: 3 });
  assert.equal(player.rolls, 2);
  assert.equal(player.score, 240);
  assert.equal(player.combo, 0);
});
test('replays, clock lies and invalid input cannot award points', () => {
  const { room, player } = fixture();
  assert.equal(applyHit(room, player, { seq: 0, at: 12000, kind: 'don', hand: 'left' }, 14000), false);
  assert.equal(applyHit(room, player, { seq: 1, at: 12000, kind: 'don', hand: 'left' }, 10000), false);
  hit(room, player, 12000, { seq: 2 });
  assert.equal(hit(room, player, 12000, { seq: 2 }), false);
  assert.equal(player.score, 1000);
});
test('misses finalize once, reset combo and produce the same authoritative winner', () => {
  const { room, player } = fixture();
  player.combo = 8;
  advanceRoom(room, 12389);
  assert.equal(player.bad, 0);
  advanceRoom(room, 12391);
  advanceRoom(room, 12392);
  assert.equal(player.bad, 1);
  assert.equal(player.combo, 0);
  room.players[1].score = 1000;
  advanceRoom(room, 20250);
  assert.equal(room.phase, 'results');
  assert.equal(room.winner, room.players[1].id);
});
test('public state never leaks resume credentials; rematch preserves identity', () => {
  const { room, player } = fixture();
  const token = player.token;
  assert.equal(JSON.stringify(publicRoom(room)).includes(token), false);
  player.score = 1200; player.consumed.add(0);
  resetPlayer(player);
  assert.equal(player.token, token);
  assert.equal(player.score, 0);
  assert.equal(player.consumed.size, 0);
});
test('authored charts are stable, playable, varied, and fit musical bar boundaries', () => {
  for (const id of ['lantern', 'moon']) {
    const chart = chartFor(id);
    assert.deepEqual(chartFor(id), chart);
    assert.ok(chart.notes.length > 90);
    assert.ok(chart.notes.some(note => note.kind === 'ka' && note.big));
    assert.ok(chart.notes.some(note => note.kind === 'roll'));
    assert.ok(chart.notes.every((note, index) => note.at < chart.duration && (index === 0 || note.at > chart.notes[index - 1].at)));
    assert.ok(chartFor(id, 'easy').notes.length < chart.notes.length);
    for (const roll of chart.notes.filter(note => note.kind === 'roll')) {
      assert.equal(chart.notes.filter(note => note.id !== roll.id && note.at >= roll.at && note.at <= roll.at + roll.duration).length, 0);
    }
  }
});
