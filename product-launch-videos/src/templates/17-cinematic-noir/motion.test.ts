import assert from 'node:assert/strict';
import test from 'node:test';
import {config} from './config';
import {environmentSelectionState} from './motion';

test('Ubuntu stays selected until the pointer arrives and commits macOS', () => {
  const initial = environmentSelectionState(35, 150, config.motion);
  const moving = environmentSelectionState(51, 150, config.motion);
  const arrived = environmentSelectionState(60, 150, config.motion);
  const committed = environmentSelectionState(68, 150, config.motion);
  const final = environmentSelectionState(149, 150, config.motion);
  assert.equal(initial.move, 0);
  assert.equal(initial.selectedMac, false);
  assert.ok(moving.move > 0 && moving.move < 1);
  assert.equal(moving.selectedMac, false);
  assert.equal(arrived.move, 1);
  assert.equal(arrived.selectedMac, false);
  assert.equal(committed.move, 1);
  assert.equal(committed.selectedMac, true);
  assert.equal(final.move, 1);
  assert.equal(final.selectedMac, true);
  assert.equal(final.cursorOpacity, 0);
});

test('short scenes and oversized animation settings still finish on macOS', () => {
  const motion = {
    ...config.motion,
    shutterFrames: 60,
    environmentHoldFrames: 60,
    environmentMoveFrames: 60,
    environmentClickFrames: 30,
  };
  for (const duration of [1, 2, 15, 30, 60, 150]) {
    let previousMove = 0;
    for (let frame = 0; frame < duration; frame++) {
      const state = environmentSelectionState(frame, duration, motion);
      assert.ok(state.move >= previousMove && state.move <= 1);
      if (state.selectedMac) assert.equal(state.move, 1);
      previousMove = state.move;
    }
    const final = environmentSelectionState(duration - 1, duration, motion);
    assert.equal(final.selectedMac, true);
    assert.equal(final.move, 1);
  }
});

test('disabled animation keeps the corrected state without a pointer', () => {
  const motion = {...config.motion, environmentAnimationEnabled: false};
  for (const frame of [0, 35, 51, 149]) {
    assert.deepEqual(environmentSelectionState(frame, 150, motion),
      {move: 1, selectedMac: true, cursorOpacity: 0, press: 0});
  }
});

test('zero-length transitions commit immediately after the shutter', () => {
  const state = environmentSelectionState(24, 150, {
    ...config.motion, environmentHoldFrames: 0, environmentMoveFrames: 0,
    environmentClickFrames: 0,
  });
  assert.equal(state.move, 1);
  assert.equal(state.selectedMac, true);
  assert.equal(state.press, 0);
});

test('older configurations retain the default animation', () => {
  const motion = {...config.motion};
  delete motion.environmentAnimationEnabled;
  delete motion.environmentHoldFrames;
  delete motion.environmentMoveFrames;
  delete motion.environmentClickFrames;
  for (const frame of [0, 35, 51, 68, 149]) {
    assert.deepEqual(environmentSelectionState(frame, 150, motion),
      environmentSelectionState(frame, 150, config.motion));
  }
});
