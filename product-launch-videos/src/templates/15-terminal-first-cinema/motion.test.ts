import assert from 'node:assert/strict';
import {test} from 'node:test';
import {timelineDuration} from '../../shared/timeline';
import {config} from './config';
import {cursorVisible, phase, revealFrames, splitFrame, typedLength} from './motion';

test('scene timing edits change the composition and preserve useful reading holds', () => {
  assert.equal(timelineDuration(config.durations), 1200);
  assert.equal(timelineDuration({...config.durations, opening: 5, closing: 6}), 1260);
  assert.equal(revealFrames(40, 30), 7);
  assert.equal(splitFrame(270, 0.5), 135);
  assert.equal(splitFrame(60, 0.65), 39);
});

test('line progression is frame deterministic, bounded and disableable', () => {
  assert.equal(typedLength('Devin on Mac', -1, 20), 0);
  assert.equal(typedLength('Devin on Mac', 10, 20), 6);
  assert.equal(typedLength('Devin on Mac', 100, 20), 12);
  assert.equal(typedLength('Devin on Mac', 0, 0), 12);
  assert.equal(phase(4, 5, 0), 0);
  assert.equal(phase(5, 5, 0), 1);
});

test('default caption caret stays still during product holds', () => {
  for (const frame of [0, 20, 30, 150, 599]) {
    assert.equal(cursorVisible(frame, 20, 15, false), true);
  }
  assert.equal(cursorVisible(35, 20, 15, true), false);
  assert.equal(cursorVisible(50, 20, 15, true), true);
  assert.equal(cursorVisible(35, 20, 0, true), true);
});
