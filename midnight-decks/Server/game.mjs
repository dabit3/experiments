export const WINDOWS = Object.freeze([25, 55, 95, 140]);
export const NETWORK_GRACE = 250;

export function freshStats(notes) {
  return {
    score: 0, combo: 0, maxCombo: 0, gauge: 22, judged: 0,
    counts: { perfect: 0, great: 0, good: 0, bad: 0, poor: 0 },
    heads: notes.map(() => 0), tails: notes.map(n => n.duration ? 0 : 1),
    active: {}, last: { text: 'STAND BY', delta: 0, lane: -1, serial: 0 },
  };
}

export function judgment(delta) {
  const d = Math.abs(delta);
  return d <= 25 ? 'perfect' : d <= 55 ? 'great' : d <= 95 ? 'good' : d <= 140 ? 'bad' : 'poor';
}

function award(stats, result, delta, lane) {
  const ex = { perfect: 2, great: 1, good: 0, bad: 0, poor: 0 };
  const gain = { perfect: 1.2, great: .8, good: .3, bad: -3, poor: -5 };
  stats.score += ex[result];
  stats.counts[result]++;
  stats.judged++;
  stats.combo = ['bad', 'poor'].includes(result) ? 0 : stats.combo + 1;
  stats.maxCombo = Math.max(stats.maxCombo, stats.combo);
  stats.gauge = Math.round(Math.max(2, Math.min(100, stats.gauge + gain[result])) * 10) / 10;
  stats.last = {
    text: { perfect: 'PERFECT GREAT', great: 'GREAT', good: 'GOOD', bad: 'BAD', poor: 'POOR' }[result],
    delta: Math.round(delta), lane, serial: stats.last.serial + 1,
  };
}

export function processInput(stats, chart, { lane, down, time }) {
  if (!Number.isInteger(lane) || lane < 0 || lane > 7 || typeof down !== 'boolean' || !Number.isFinite(time)) return false;
  if (!down) {
    const id = stats.active[lane];
    if (id === undefined) return false;
    const note = chart.notes[id];
    const delta = time - note.time - note.duration;
    const result = judgment(delta);
    stats.tails[id] = result === 'poor' ? 2 : 1;
    delete stats.active[lane];
    award(stats, result, delta, lane);
    return true;
  }
  if (stats.active[lane] !== undefined) return false;
  const note = chart.notes.find(n => n.lane === lane && stats.heads[n.id] === 0 && Math.abs(n.time - time) <= 140);
  if (!note) return false;
  const delta = time - note.time;
  const result = judgment(delta);
  stats.heads[note.id] = 1;
  if (note.duration) stats.active[lane] = note.id;
  award(stats, result, delta, lane);
  return true;
}

export function expireNotes(stats, chart, songTime) {
  for (const note of chart.notes) {
    if (stats.heads[note.id] === 0 && songTime > note.time + 140 + NETWORK_GRACE) {
      stats.heads[note.id] = 2;
      award(stats, 'poor', 141, note.lane);
    }
    if (note.duration && stats.tails[note.id] === 0 && songTime > note.time + note.duration + 140 + NETWORK_GRACE) {
      stats.tails[note.id] = 2;
      delete stats.active[note.lane];
      award(stats, 'poor', 141, note.lane);
    }
  }
}

export function winner(players) {
  const sorted = [...players].sort((a, b) => b.stats.score - a.stats.score);
  return sorted.length === 2 && sorted[0].stats.score !== sorted[1].stats.score ? sorted[0].id : 'draw';
}
