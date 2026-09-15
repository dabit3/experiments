import assert from 'node:assert/strict';
import test from 'node:test';
import {mediaGeometry} from '../../shared/geometry';
import {config} from './config';
import {editTimeline, environmentFraming, iphoneSplit} from './edit';

test('duration edits reposition all cuts and preserve both iPhone stills', () => {
  const custom = structuredClone(config);
  custom.durations.opening = 1;
  custom.durations.environment = 2;
  custom.durations.iphone = 3;
  const timeline = editTimeline(custom, 30);
  assert.deepEqual(timeline.map(({from}) => from), [0, 30, 90, 210, 300, 510, 690]);
  assert.equal(timeline.at(-1)!.from + timeline.at(-1)!.durationInFrames, 840);
  assert.equal(iphoneSplit(90, 0.5), 45);
  assert.equal(iphoneSplit(2, 0.01), 1);
  assert.throws(() => iphoneSplit(1, 0.5), /two frames/);
  assert.throws(() => iphoneSplit(90, 1), /strictly/);
});

test('environment reframe is bounded and settles before the latter half of the scene', () => {
  for (const duration of [2, 15, 150, 300]) {
    const end = environmentFraming(config, duration - 1, duration, 30);
    const settled = environmentFraming(config, Math.ceil(duration / 2), duration, 30);
    assert.deepEqual(end, settled);
    for (let frame = 0; frame < duration; frame++) {
      const framing = environmentFraming(config, frame, duration, 30);
      const geometry = mediaGeometry({width: 2988, height: 1622}, {width: 1848, height: 890}, framing);
      assert.ok(geometry.mediaWidth > 0);
      assert.ok(framing.crop!.x >= config.media.environment.framing.crop!.x);
      assert.ok(framing.crop!.width <= config.media.environment.framing.crop!.width);
    }
  }
});

test('zoom can be disabled and invalid motion cannot fabricate an out-of-bounds view', () => {
  const custom = structuredClone(config);
  custom.motion.environmentZoom = 1;
  assert.deepEqual(environmentFraming(custom, 100, 150, 30), custom.media.environment.framing);
  custom.motion.environmentZoom = Number.NaN;
  assert.throws(() => environmentFraming(custom, 100, 150, 30), /zoom/);
  custom.motion.environmentZoom = 1.16;
  custom.motion.environmentAnchorX = 2;
  assert.throws(() => environmentFraming(custom, 100, 150, 30), /anchors/);
});
