import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const path = process.argv[2];
if (!path) throw new Error('Usage: node Scripts/assert-evidence.mjs /path/to/server.jsonl');
const snapshots = readFileSync(path, 'utf8').trim().split('\n').map(line => JSON.parse(line));
const results = [];
function check(name, predicate) {
  assert.ok(predicate, name);
  results.push({ name, passed: true });
}
const victory = snapshots.find(s => s.phase === 'victory');
check('shared victory is present', victory);
check('two distinct connected human peers', victory.players.length === 2 &&
  new Set(victory.players.map(p => p.id)).size === 2 && victory.players.every(p => p.connected));
check('three traversed stages completed', victory.completedStages === 3 &&
  [1, 2, 3].every(stage => snapshots.some(s => s.stage === stage && s.phase === 'playing')));
for (const player of victory.players) {
  const states = snapshots.flatMap(s => s.players.filter(p => p.id === player.id));
  check(`${player.name}: significant traversal`, Math.max(...states.map(p => p.x)) - Math.min(...states.map(p => p.x)) > 40);
  check(`${player.name}: melee and ranged attacks with registered hits`,
    player.stats.melee > 0 && player.stats.ranged > 0 && player.stats.hits > 0);
  check(`${player.name}: dodge and equipment choices`, player.stats.dodge > 0 && player.stats.equipment >= 1);
}
check('both peers ready and rematch begins', snapshots.some(s => s.round > victory.round && s.phase === 'playing'));
console.log(JSON.stringify({ room: victory.code, round: victory.round, tick: victory.tick, results }, null, 2));
