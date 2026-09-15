import assert from 'node:assert/strict';
import test from 'node:test';
import {makeTimeline, timelineDuration, videoTrim, assets} from '../../shared';
import {config} from './config';
import {iphoneSplitFrame, revealAmount} from './Template';

test('duration edits preserve the seven-scene order and independent source trims', () => {
  const durations = {opening: 2, environment: 2, agent: 1, iphone: 2, webQa: 1, ipad: 1, closing: 3};
  const timeline = makeTimeline(durations, 30);
  assert.equal(timelineDuration(durations, 30), 360);
  assert.deepEqual(timeline.map(({from}) => from), [0, 60, 120, 150, 210, 240, 270]);
  for (const id of ['agent', 'webQa'] as const) {
    const selected = config.media[id];
    const scene = timeline.find((item) => item.id === id);
    assert.ok(scene);
    const trim = videoTrim({
      sourceStartSeconds: selected.sourceStartSeconds,
      durationInFrames: scene.durationInFrames,
    }, 30, assets[selected.asset].durationSeconds);
    assert.equal(trim.trimBefore, 0);
    assert.equal(trim.trimAfter, 30);
  }
});

test('short scenes settle their reveals and retain both iPhone stills', () => {
  assert.equal(revealAmount(2, 18, 3), 1);
  assert.equal(revealAmount(0, 0, 30), 1);
  assert.equal(iphoneSplitFrame(270, 0.5), 135);
  assert.equal(iphoneSplitFrame(2, 0.9), 1);
  assert.equal(timelineDuration(config.durations, 30), 1200);
});
