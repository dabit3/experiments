import assert from 'node:assert/strict';
import {test} from 'node:test';
import {config} from './config';
import {cameraAt, planJourney} from './journey';

test('both source recordings remain motionless throughout their complete source actions', () => {
  const {stops, scene, totalFrames} = planJourney(config, 30);
  assert.equal(totalFrames, 1200);
  for (const id of ['agent', 'webQa'] as const) {
    const timing = scene(id);
    for (let frame = timing.from; frame < timing.from + timing.durationInFrames; frame++) {
      assert.deepEqual(cameraAt(frame, stops, config.motion.travelPullback), {
        ...config.canvas.stops[id], scale: 1,
      });
    }
  }
});

test('camera travels monotonically and continuously without sudden zoom changes', () => {
  const {stops} = planJourney(config, 30);
  for (let index = 0; index < stops.length - 1; index++) {
    const start = stops[index].departure;
    const end = stops[index + 1].arrival;
    let previous = cameraAt(start, stops, config.motion.travelPullback).x;
    for (let step = 1; step <= 100; step++) {
      const camera = cameraAt(start + (end - start) * step / 100, stops, config.motion.travelPullback);
      assert.ok(camera.x >= previous);
      assert.ok(camera.scale >= 0.975 && camera.scale <= 1);
      previous = camera.x;
    }
    assert.deepEqual(cameraAt(end, stops, config.motion.travelPullback), {
      ...stops[index + 1].position, scale: 1,
    });
  }
});

test('edited durations and camera positions derive new stopping points and total duration', () => {
  const edited = structuredClone(config);
  edited.durations.opening = 5;
  edited.durations.environment = 6;
  edited.durations.closing = 6;
  edited.canvas.stops.agent.y = 80;
  edited.copy.environment = 'Choose your hosted Mac.';
  const {totalFrames, stops, scene} = planJourney(edited, 30);
  assert.equal(totalFrames, 1290);
  assert.equal(scene('agent').from, 330);
  assert.deepEqual(cameraAt(330, stops, edited.motion.travelPullback), {x: 4200, y: 80, scale: 1});
  assert.equal(edited.copy.environment, 'Choose your hosted Mac.');
});
