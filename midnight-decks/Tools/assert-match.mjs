import fs from 'node:fs';
import assert from 'node:assert/strict';

const [aPath, bPath] = process.argv.slice(2);
if (!aPath || !bPath) throw Error('Usage: node Tools/assert-match.mjs a.jsonl b.jsonl');
const read = file => fs.readFileSync(file, 'utf8').trim().split('\n').map(line => JSON.parse(line));
const a = read(aPath), b = read(bPath);
const resultA = a.find(e => e.event === 'result' && e.room.round === 1);
const resultB = b.find(e => e.event === 'result' && e.room.round === 1);
assert.ok(resultA && resultB, 'Both devices must reach round-one result');
assert.notEqual(resultA.you, resultB.you, 'Distinct native peer IDs');
assert.equal(resultA.room.room, resultB.room.room, 'Same room');
assert.equal(resultA.room.startAt, resultB.room.startAt, 'Same authoritative song start');
assert.equal(resultA.room.winner, resultB.room.winner, 'Shared outcome');
const counts = player => Object.values(player.stats.counts).reduce((sum, n) => sum + n, 0);
for (const p of resultA.room.players) {
  const other = resultB.room.players.find(q => q.id === p.id);
  assert.ok(p.stats.score > 0, 'Each peer scored real notes');
  assert.ok(p.stats.counts.perfect + p.stats.counts.great > 100, 'Meaningful full-song performance');
  assert.equal(counts(p), 191, 'Every chart endpoint judged exactly once');
  assert.equal(p.stats.score, other.stats.score, 'Both displays agree on score');
}
for (const rows of [a, b]) {
  assert.ok(rows.some(e => e.room.round === 2 && e.room.phase === 'playing'), 'Rematch started');
  const audio = rows.filter(e => e.room.round === 1 && e.room.phase === 'playing' && e.songTime > 1000 && e.songTime < 62000);
  assert.ok(audio.length > 40, 'Moving gameplay telemetry spans the match');
  const errors = audio.map(e => Math.abs(e.audioTime - e.songTime)).sort((x, y) => x - y);
  assert.ok(errors[Math.floor(errors.length / 2)] < 150, 'Median audio/song clock deviation under 150ms');
}
console.log(JSON.stringify({
  passed: true, room: resultA.room.room, startAt: resultA.room.startAt, winner: resultA.room.winner,
  peers: resultA.room.players.map(p => ({ id: p.id, score: p.stats.score, judgments: counts(p) })),
  checks: ['distinct native peers', 'common song start', 'both score >100 accurate notes', '191 endpoints each', 'shared outcome', 'rematch', 'audio clock'],
}, null, 2));
