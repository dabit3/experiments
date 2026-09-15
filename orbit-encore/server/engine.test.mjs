import test from 'node:test';
import assert from 'node:assert/strict';
import { charts, target } from './charts.mjs';
import { grade, createPerformance, input, advance, publicPerformance } from './engine.mjs';

const note = (kind = 'tap', extra = {}) => ({ id: 0, time: 1, lane: 0, kind, duration: 0, path: [], ...extra });
const play = notes => ({ notes, duration: 5 });
const event = (seq, phase = 'down', point = target(0), pointer = 1) => ({ seq, phase, ...point, pointer });

test('timing boundaries preserve early/late symmetry and miss beyond 160ms', () => {
  for (const direction of [-1, 1]) {
    assert.equal(grade(0.05 * direction), 'PERFECT');
    assert.equal(grade(0.051 * direction), 'GREAT');
    assert.equal(grade(0.105 * direction), 'GREAT');
    assert.equal(grade(0.106 * direction), 'GOOD');
    assert.equal(grade(0.16 * direction), 'GOOD');
    assert.equal(grade(0.161 * direction), 'MISS');
  }
});

test('wrong lane, replayed sequence, nonfinite input and missed notes cannot add score', () => {
  const chart = play([note(), note('break', { id: 1, time: 2 })]);
  const perf = createPerformance(chart);
  input(perf, chart, event(1, 'down', target(4)), 1);
  assert.equal(perf.score, 0);
  assert.equal(input(perf, chart, event(1), 1), false);
  assert.equal(input(perf, chart, event(2, 'down', { x: NaN, y: 0 }), 1), false);
  advance(perf, chart, 1.17);
  assert.equal(perf.counts.MISS, 1);
  input(perf, chart, event(3), 2);
  assert.equal(perf.score, 833333);
  assert.equal(perf.combo, 1);
});

test('continuous holds require the original finger in its lane; early release fails', () => {
  for (const action of ['up', 'move']) {
    const chart = play([note('hold', { duration: 1 })]);
    const perf = createPerformance(chart);
    input(perf, chart, event(1), 1);
    input(perf, chart, event(2, action, target(4)), 1.4);
    advance(perf, chart, 2.2);
    assert.equal(perf.counts.MISS, 1);
  }
  const chart = play([note('hold', { duration: 1 })]);
  const perf = createPerformance(chart);
  input(perf, chart, event(1), 1);
  advance(perf, chart, 2);
  assert.equal(perf.score, 1000000);
});

test('slides require all ordered checkpoints and a timed endpoint', () => {
  const path = [target(0), { x: 0.3, y: 0.25 }, { x: -0.3, y: -0.25 }, target(4)];
  const chart = play([note('slide', { duration: 1.5, path })]);
  const skipped = createPerformance(chart);
  input(skipped, chart, event(1), 1);
  input(skipped, chart, event(2, 'move', path.at(-1)), 2.5);
  advance(skipped, chart, 2.7);
  assert.equal(skipped.counts.MISS, 1);
  const traced = createPerformance(chart);
  input(traced, chart, event(1), 1);
  input(traced, chart, event(2, 'move', path[1]), 1.5);
  input(traced, chart, event(3, 'move', path[2]), 2);
  input(traced, chart, event(4, 'move', path[3]), 2.5);
  assert.equal(traced.counts.PERFECT, 1);
  assert.equal(traced.score, 1000000);
});

test('paired notes need distinct down events and combo resets on a miss', () => {
  const chart = play([note('each'), note('each', { id: 1, lane: 4 }), note('tap', { id: 2, time: 2 })]);
  const perf = createPerformance(chart);
  input(perf, chart, event(1), 1);
  input(perf, chart, event(2, 'down', target(4), 2), 1);
  assert.equal(perf.combo, 2);
  advance(perf, chart, 2.2);
  assert.equal(perf.combo, 0);
  assert.equal(perf.maxCombo, 2);
});

test('authored charts cover all eight lanes and all mechanics on a consistent beat grid', () => {
  for (const chart of charts) {
    assert.deepEqual(new Set(chart.notes.map(n => n.lane)), new Set([0, 1, 2, 3, 4, 5, 6, 7]));
    assert.deepEqual(new Set(chart.notes.map(n => n.kind)), new Set(['tap', 'hold', 'break', 'slide', 'each']));
    assert.ok(chart.notes.length > 60);
    for (const n of chart.notes) {
      const halfBeat = n.time * chart.bpm / 30;
      assert.ok(Math.abs(halfBeat - Math.round(halfBeat)) < 0.00001);
      assert.ok(n.time + n.duration < chart.duration);
    }
  }
});

test('an all-perfect complete chart reaches exactly one million with no unjudged notes', () => {
  for (const chart of charts) {
    const perf = createPerformance(chart);
    const actions = [];
    for (const n of chart.notes) {
      actions.push({ at: n.time, phase: 'down', point: target(n.lane), pointer: n.id });
      if (n.kind === 'slide') {
        n.path.slice(1).forEach((point, index) => actions.push({
          at: n.time + n.duration * (index + 1) / (n.path.length - 1), phase: 'move', point, pointer: n.id,
        }));
      }
      actions.push({ at: n.time + Math.max(0.08, n.duration) + 0.001, phase: 'up',
        point: n.path.at(-1) ?? target(n.lane), pointer: n.id });
    }
    actions.sort((a, b) => a.at - b.at);
    actions.forEach((a, i) => input(perf, chart, event(i, a.phase, a.point, a.pointer), a.at));
    advance(perf, chart, chart.duration);
    assert.equal(perf.score, 1000000);
    assert.equal(perf.counts.MISS, 0);
    assert.equal(perf.judged, chart.notes.length);
    assert.equal(publicPerformance(perf).accuracy, 100);
  }
});
