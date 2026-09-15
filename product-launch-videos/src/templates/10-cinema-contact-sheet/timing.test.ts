import assert from 'node:assert/strict';
import test from 'node:test';
import {timelineDuration} from '../../shared';
import {config} from './config';
import {createEdit, frozenFrame} from './timing';

test('both recordings play their entire selected clip at large size, without index transitions', () => {
  const edit = createEdit(config, 30);
  for (const shot of edit.shots.filter((candidate) => candidate.kind === 'video')) {
    assert.equal(shot.media.sourceStartSeconds, 0);
    assert.equal(shot.durationInFrames, shot.index === 1 ? 120 : 210);
    for (const transition of edit.transitions) {
      const intersection = Math.min(shot.from + shot.durationInFrames, transition.from + transition.duration)
        - Math.max(shot.from, transition.from);
      assert.ok(intersection <= 0, `Transition interrupts recording ${shot.index}`);
    }
    const exit = edit.transitions.find((item) => item.outgoing.index === shot.index);
    assert.equal(exit?.from, shot.from + shot.durationInFrames);
    assert.equal(frozenFrame(shot, true), shot.durationInFrames - 1);
  }
});

test('alternate durations move the actual timeline and retain uninterrupted video trims', () => {
  const alternate = structuredClone(config);
  alternate.durations = {opening: 3, environment: 4, agent: 3, iphone: 6, webQa: 4, ipad: 4, closing: 3};
  alternate.copy.environment = 'Choose a hosted Mac environment. Your next session starts here.';
  alternate.motion.iphoneSplit = 0.6;
  alternate.media.agent.sourceStartSeconds = 1;
  const edit = createEdit(alternate, 30);
  assert.equal(timelineDuration(alternate.durations, 30), 810);
  assert.equal(edit.closing.from + edit.closing.durationInFrames, 810);
  assert.equal(edit.shots[0].caption, alternate.copy.environment);
  assert.equal(edit.shots[2].durationInFrames, 108);
  const agent = edit.shots[1];
  assert.equal(agent.kind, 'video');
  if (agent.kind === 'video') {
    assert.equal(agent.media.sourceStartSeconds, 1);
    assert.equal(frozenFrame(agent, true), 89);
  }
  for (const transition of edit.transitions) {
    assert.ok(transition.duration <= 32);
  }
});

test('invalid frozen frames and iPhone split fail rather than silently substituting content', () => {
  const invalidFrame = structuredClone(config);
  invalidFrame.archive.agentIndexFrame = 120;
  assert.throws(() => createEdit(invalidFrame, 30), /outside its selected clip/);
  const invalidSplit = structuredClone(config);
  invalidSplit.motion.iphoneSplit = 0;
  assert.throws(() => createEdit(invalidSplit, 30), /between 0 and 1/);
});
