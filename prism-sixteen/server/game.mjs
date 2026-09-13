export const WINDOWS = [0.045, 0.09, 0.14];
const values = { PERFECT: 1, GREAT: .7, GOOD: .4, MISS: 0 };

export function newPerformance() {
  return {
    score: 0, combo: 0, maxCombo: 0, accuracy: 100, shutter: 0,
    perfect: 0, great: 0, good: 0, miss: 0, ghost: 0,
    judged: {}, weight: 0, seq: -1, lastGhost: -Infinity, last: null,
  };
}

export function judge(player, note, label, error, count, now, source) {
  const p = player.performance;
  p.judged[note.id] = label;
  p[label.toLowerCase()]++;
  p.weight += values[label];
  p.combo = label === 'MISS' ? 0 : p.combo + 1;
  p.maxCombo = Math.max(p.combo, p.maxCombo);
  const delta = label === 'MISS' ? -8 : label === 'GOOD' ? 1 : 2;
  p.shutter = Math.max(0, Math.min(1, p.shutter + delta / Math.min(1024, count)));
  p.score = Math.floor(900000 * p.weight / count + 100000 * p.shutter);
  p.accuracy = 100 * p.weight / Object.keys(p.judged).length;
  p.last = { cell: note.cell, noteID: note.id, label, error, at: now, source };
  return p.last;
}

export function hit(player, chart, startAt, input, now) {
  const p = player.performance;
  if (!Number.isInteger(input.seq) || input.seq <= p.seq) return null;
  p.seq = input.seq;
  if (!Number.isInteger(input.cell) || input.cell < 0 || input.cell > 15 ||
      !Number.isFinite(input.at) || input.at > now + .06 || input.at < now - .25) return null;
  const time = input.at - startAt;
  if (time < 0) return null;
  const note = chart.filter(n => n.cell === input.cell && p.judged[n.id] === undefined)
    .sort((a, b) => Math.abs(a.time - time) - Math.abs(b.time - time))[0];
  const error = note ? time - note.time : Infinity;
  const magnitude = Math.abs(error);
  if (!note || magnitude > WINDOWS[2] + 1e-6) {
    if (now - p.lastGhost > .1) {
      p.ghost++;
      p.combo = 0;
      p.shutter = Math.max(0, p.shutter - 2 / chart.length);
      p.score = Math.floor(900000 * p.weight / chart.length + 100000 * p.shutter);
      p.lastGhost = now;
    }
    return null;
  }
  const label = magnitude <= WINDOWS[0] + 1e-6 ? 'PERFECT' :
    magnitude <= WINDOWS[1] + 1e-6 ? 'GREAT' : 'GOOD';
  return judge(player, note, label, error, chart.length, now, input.source === 'driver' ? 'driver' : 'touch');
}

export function sweep(player, chart, startAt, now, final = false) {
  for (const note of chart) {
    if (player.performance.judged[note.id] === undefined &&
        (final || now - startAt > note.time + .4)) {
      judge(player, note, 'MISS', 0, chart.length, now, 'timeout');
    }
  }
}

export function publicPlayer(player) {
  const { id, name, connected, ready, performance: p } = player;
  const { weight, seq, lastGhost, ...performance } = p;
  return { id, name, connected, ready, ...performance };
}
