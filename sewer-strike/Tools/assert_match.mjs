import { writeFile } from 'node:fs/promises';

const [url = 'http://127.0.0.1:8767/rooms/STRIKE', output = 'match-assertions.json'] = process.argv.slice(2);
const states = [];
const seenSectors = new Set();
const ids = new Set();
const deadline = Date.now() + 240_000;
let clear;
while (Date.now() < deadline) {
  const response = await fetch(url).catch(() => null);
  if (response?.ok) {
    const state = await response.json();
    states.push(state);
    state.players.forEach(p => ids.add(p.id));
    if (state.phase === 'playing') seenSectors.add(state.sector);
    if (state.phase === 'clear') { clear = state; break; }
    if (state.phase === 'gameover') break;
  }
  await new Promise(resolve => setTimeout(resolve, 500));
}
const checks = {
  distinctPeers: ids.size >= 2,
  allSectors: seenSectors.size === 3,
  sharedClear: clear?.phase === 'clear',
  bossAndWavesDefeated: clear?.defeated === 18,
  bothContributed: clear?.players.length >= 2 && clear.players.every(p =>
    p.stats.damage > 0 && p.stats.attacks > 0 && p.stats.jumps > 0 && p.stats.specials > 0 && p.stats.distance > 1000),
};
const report = { capturedAt: new Date().toISOString(), url, checks, passed: Object.values(checks).every(Boolean), states };
await writeFile(output, JSON.stringify(report, null, 2));
console.log(JSON.stringify({ checks, passed: report.passed, output }));
if (!report.passed) process.exitCode = 1;
