import assert from 'node:assert/strict';
import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {makeTimeline, timelineDuration} from '../../shared/timeline';
import {videoTrim} from '../../shared/video-timing';
import {config} from './config';

const edited = structuredClone(config);
edited.copy.opening = 'Devin on Mac';
edited.copy.agent = 'Choose your agent with Devin.';
edited.durations = {opening: 2, environment: 3, agent: 2, iphone: 4, webQa: 3, ipad: 2, closing: 2};
edited.motion.iphoneSwitchAt = 0.4;
edited.motion.dividerFrames = 10;
edited.pairings.environment.activeRatio = 0.32;
edited.pairings.iphone[0].activeRatio = 0.40;

assert.equal(timelineDuration(config.durations), 1200);
assert.equal(timelineDuration(edited.durations), 540);
const timeline = makeTimeline(edited.durations);
assert.equal(timeline.find((scene) => scene.id === 'agent')?.from, 150);
assert.equal(timeline.find((scene) => scene.id === 'webQa')?.from, 330);
assert.notEqual(edited.copy.agent, config.copy.agent);
videoTrim({sourceStartSeconds: edited.media.agent.sourceStartSeconds, durationInFrames: 60}, 30, 9.166667);
videoTrim({sourceStartSeconds: edited.media.webQa.sourceStartSeconds, durationInFrames: 90}, 30, 59.133333);

const directory = fileURLToPath(new URL('../../../out/14-cause-and-effect-diptych/validation/', import.meta.url));
await mkdir(directory, {recursive: true});
const filename = path.join(directory, 'props.json');
await writeFile(filename, JSON.stringify({config: edited}, null, 2) + '\n');
console.log(`Validated edited timeline: 18 seconds / 540 frames. Props: ${filename}`);
