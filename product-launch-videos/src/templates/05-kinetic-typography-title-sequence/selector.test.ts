import assert from 'node:assert/strict';
import test from 'node:test';
import {selectorDefaults, selectorState} from './selector';

test('selector starts on Ubuntu, moves continuously, then checks and holds macOS', () => {
  assert.deepEqual(selectorState(0, 150, selectorDefaults), {position: 0, selected: 'Ubuntu'});
  assert.deepEqual(selectorState(36, 150, selectorDefaults), {position: 0, selected: 'Ubuntu'});
  assert.deepEqual(selectorState(48, 150, selectorDefaults), {position: 0.5, selected: 'Ubuntu'});
  assert.deepEqual(selectorState(60, 150, selectorDefaults), {position: 1, selected: 'macOS'});
  let previous = 0;
  for (let frame = 0; frame < 150; frame++) {
    const state = selectorState(frame, 150, selectorDefaults);
    assert.ok(state.position >= previous && state.position <= 1);
    if (frame >= 60) assert.equal(state.selected, 'macOS');
    previous = state.position;
  }
});

test('short scenes and edited timing leave the final macOS state visible', () => {
  for (const duration of [1, 2, 3, 15, 60]) {
    assert.deepEqual(selectorState(duration - 1, duration, selectorDefaults),
      {position: 1, selected: 'macOS'});
  }
  const custom = {...selectorDefaults, holdFrames: 10, moveFrames: 8};
  assert.equal(selectorState(14, 150, custom).position, 0.5);
  assert.equal(selectorState(18, 150, custom).selected, 'macOS');
  assert.deepEqual(selectorState(0, 150, {...custom, holdFrames: 0, moveFrames: 0}),
    {position: 1, selected: 'macOS'});
});
