import assert from 'node:assert/strict';
import {test} from 'node:test';
import {frames, makeTimeline, sampleDurations, timelineDuration} from './timeline';
import {videoTrim} from './video-timing';
import {assets} from './assets';

test('the comparable seven-part edit is contiguous and exactly 40 seconds at 30 fps', () => {
  const timeline = makeTimeline(sampleDurations);
  assert.deepEqual(timeline.map((scene) => scene.from), [0, 120, 270, 390, 660, 870, 1050]);
  assert.deepEqual(timeline.map((scene) => scene.durationInFrames), [120, 150, 120, 270, 210, 180, 150]);
  assert.equal(timelineDuration(sampleDurations), 1200);
  assert.equal(timelineDuration({...sampleDurations, opening: 2}), 1140);
});

test('durations round independently and reject empty, negative and nonfinite scenes', () => {
  assert.equal(frames(0.05, 30), 2);
  for (const opening of [0, -1, Infinity, NaN]) {
    assert.throws(() => makeTimeline({...sampleDurations, opening}));
  }
});

test('source trims remain independent of destination offsets and use composition fps', () => {
  const timing = {sourceStartSeconds: 2, durationInFrames: 90};
  for (const destination of [0, 120, 660]) {
    const source = videoTrim(timing, 30, assets['devin-testing-2.mp4'].durationSeconds);
    assert.equal(source.trimBefore, 60);
    assert.equal(source.trimBefore + ((destination + 15) - destination), 75);
    assert.equal(source.trimAfter, 150);
  }
  assert.deepEqual(videoTrim({...timing, durationInFrames: 60}, 60, 59), {
    trimBefore: 120, trimAfter: 180,
  });
});

test('the fixed source selections contain the full requested 1x intervals', () => {
  assert.deepEqual(videoTrim({sourceStartSeconds: 0, durationInFrames: 120}, 30,
    assets['agent-selector-cloud.mp4'].durationSeconds), {trimBefore: 0, trimAfter: 120});
  assert.deepEqual(videoTrim({sourceStartSeconds: 0, durationInFrames: 210}, 30,
    assets['devin-testing-2.mp4'].durationSeconds), {trimBefore: 0, trimAfter: 210});
  assert.throws(() => videoTrim({sourceStartSeconds: 8, durationInFrames: 120}, 30, 9.166667));
  assert.throws(() => videoTrim({sourceStartSeconds: -1, durationInFrames: 30}, 30, 9));
  assert.throws(() => videoTrim({sourceStartSeconds: 0, durationInFrames: 0}, 30, 9));
});
