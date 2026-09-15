import { target } from './charts.mjs';

export const WINDOWS = { perfect: 0.050, great: 0.105, good: 0.160 };
const weights = { tap: 1, each: 1, break: 5, hold: 2, slide: 3 };
export const grade = delta => Math.abs(delta) <= WINDOWS.perfect ? 'PERFECT'
  : Math.abs(delta) <= WINDOWS.great ? 'GREAT' : Math.abs(delta) <= WINDOWS.good ? 'GOOD' : 'MISS';
const value = { PERFECT: 1, GREAT: 0.75, GOOD: 0.4, MISS: 0 };
const dist = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);

export function createPerformance(chart) {
  return { score: 0, combo: 0, maxCombo: 0, judged: 0, earned: 0,
    total: chart.notes.reduce((s, n) => s + weights[n.kind], 0),
    counts: { PERFECT: 0, GREAT: 0, GOOD: 0, MISS: 0 },
    notes: chart.notes.map(() => ({ state: 'pending', checkpoint: 0 })),
    touches: new Map(), lastSeq: -1, lastTime: -1, lastJudgment: null };
}

function finish(perf, note, judgment, at) {
  const state = perf.notes[note.id];
  if (state.state === 'done') return;
  state.state = 'done';
  state.judgment = judgment;
  perf.judged++;
  perf.counts[judgment]++;
  perf.earned += weights[note.kind] * value[judgment];
  perf.score = Math.round(perf.earned / perf.total * 1000000);
  perf.combo = judgment === 'MISS' ? 0 : perf.combo + 1;
  perf.maxCombo = Math.max(perf.maxCombo, perf.combo);
  perf.lastJudgment = { id: note.id, text: judgment, at, lane: note.lane };
}

export function advance(perf, chart, time) {
  for (const note of chart.notes) {
    const state = perf.notes[note.id];
    if (state.state === 'pending' && time > note.time + WINDOWS.good) finish(perf, note, 'MISS', time);
    if (state.state === 'active' && note.kind === 'hold') {
      if (time >= note.time + note.duration && perf.touches.has(state.pointer)) {
        finish(perf, note, state.headGrade, time);
      } else if (!perf.touches.has(state.pointer)) finish(perf, note, 'MISS', time);
    }
    if (state.state === 'active' && note.kind === 'slide' && time > note.time + note.duration + WINDOWS.good) {
      finish(perf, note, 'MISS', time);
    }
  }
}

export function input(perf, chart, event, time) {
  if (!Number.isInteger(event.seq) || event.seq <= perf.lastSeq ||
    !Number.isFinite(event.x) || !Number.isFinite(event.y) ||
    Math.abs(event.x) > 1.25 || Math.abs(event.y) > 1.25 ||
    !Number.isInteger(event.pointer) || !['down', 'move', 'up'].includes(event.phase) ||
    time < perf.lastTime - 0.003) return false;
  perf.lastSeq = event.seq;
  perf.lastTime = time;
  advance(perf, chart, time);
  const pos = { x: event.x, y: event.y };
  if (event.phase === 'up') {
    perf.touches.delete(event.pointer);
    for (const note of chart.notes) {
      const state = perf.notes[note.id];
      if (state.state === 'active' && state.pointer === event.pointer && note.kind === 'hold') {
        finish(perf, note, time >= note.time + note.duration - 0.07 ? state.headGrade : 'MISS', time);
      }
    }
    return true;
  }
  if (event.phase === 'move' && !perf.touches.has(event.pointer)) return false;
  perf.touches.set(event.pointer, pos);
  for (const note of chart.notes) {
    const state = perf.notes[note.id];
    if (state.state === 'active' && state.pointer === event.pointer && note.kind === 'hold' &&
      dist(pos, target(note.lane)) > 0.30) finish(perf, note, 'MISS', time);
    if (state.state === 'active' && state.pointer === event.pointer && note.kind === 'slide') {
      const next = state.checkpoint + 1;
      const radius = next === note.path.length - 1 ? 0.10 : 0.23;
      if (next < note.path.length && dist(pos, note.path[next]) < radius) {
        state.checkpoint = next;
        if (next === note.path.length - 1) {
          const tailGrade = grade(time - note.time - note.duration);
          const result = value[tailGrade] < value[state.headGrade] ? tailGrade : state.headGrade;
          finish(perf, note, result, time);
        }
      }
    }
  }
  if (event.phase !== 'down') return true;
  const candidate = chart.notes.filter(n => perf.notes[n.id].state === 'pending' &&
    Math.abs(time - n.time) <= WINDOWS.good && dist(pos, target(n.lane)) <= 0.28)
    .sort((a, b) => Math.abs(time - a.time) - Math.abs(time - b.time))[0];
  if (!candidate) return true;
  const judgment = grade(time - candidate.time);
  if (candidate.kind === 'hold' || candidate.kind === 'slide') {
    Object.assign(perf.notes[candidate.id], { state: 'active', pointer: event.pointer,
      checkpoint: 0, headGrade: judgment });
    perf.lastJudgment = { id: candidate.id, text: candidate.kind === 'hold' ? 'HOLD' : 'TRACE', at: time, lane: candidate.lane };
  } else finish(perf, candidate, judgment, time);
  return true;
}

export function publicPerformance(perf) {
  return { score: perf.score, combo: perf.combo, maxCombo: perf.maxCombo,
    accuracy: perf.judged ? perf.earned / perf.total * 100 : 0,
    judged: perf.judged, counts: perf.counts, lastJudgment: perf.lastJudgment,
    notes: perf.notes.map(n => ({ state: n.state, checkpoint: n.checkpoint, judgment: n.judgment ?? '' })) };
}
