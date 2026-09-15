import assert from 'node:assert/strict';
import test from 'node:test';
import {makeTimeline, timelineDuration} from '../../shared/timeline';
import {config} from './config';
import {boundedFrames, fitPhrase, iphoneCut} from './phrase';

const measure = (text: string, size: number) => text.length * size * 0.5;

test('long phrases retain every word, wrap titles, and shrink captions without clipping', () => {
  const text = 'Build, run, and test iOS apps in the cloud.';
  const title = fitPhrase(text, 420, 96, 30, 3, measure);
  assert.equal(title.lines.join(' '), text);
  assert.ok(title.lines.length > 1 && title.lines.length <= 3);
  assert.ok(title.lines.every((line) => measure(line, title.fontSize) <= 420));
  const caption = fitPhrase(text, 680, 48, 30, 1, measure);
  assert.equal(caption.lines.length, 1);
  assert.ok(caption.fontSize < 48);
  assert.throws(() => fitPhrase('A'.repeat(120), 680, 48, 30, 1, measure), /does not fit/);
});

test('edited durations move the iPhone cut and shorten reveals while preserving source intervals', () => {
  const durations = {...config.durations, opening: 2, environment: 2, agent: 2,
    iphone: 3, webQa: 2, ipad: 2, closing: 2};
  const scenes = makeTimeline(durations);
  const iphone = scenes.find((scene) => scene.id === 'iphone');
  assert.ok(iphone);
  assert.equal(timelineDuration(durations), 450);
  assert.equal(iphone.from, 180);
  assert.equal(iphoneCut(iphone.durationInFrames, 0.6), 54);
  assert.equal(boundedFrames(26, 15), 5);
  assert.equal(boundedFrames(0, 15), 0);
  assert.equal(config.media.agent.sourceStartSeconds, 0);
  assert.equal(config.media.webQa.sourceStartSeconds, 0);
});
