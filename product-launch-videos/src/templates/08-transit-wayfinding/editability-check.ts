import assert from 'node:assert/strict';
import {mkdir, writeFile} from 'node:fs/promises';
import {makeTimeline, timelineDuration} from '../../shared/timeline';
import {config} from './config';

const edited = structuredClone(config);
edited.durations = {opening: 2, environment: 2, agent: 1, iphone: 2, webQa: 2, ipad: 2, closing: 2};
edited.copy.environment = 'Choose your hosted Mac environment.';
edited.route.stations[0].name = 'Hosted Mac';
edited.motion.arrivalFrames = 12;
edited.motion.lineTraceFrames = 28;

assert.equal(timelineDuration(config.durations), 1200);
assert.equal(timelineDuration(edited.durations), 390);
assert.equal(makeTimeline(edited.durations).find((scene) => scene.id === 'agent')?.from, 120);
assert.equal(edited.media.agent.sourceStartSeconds, 0);
assert.equal(edited.media.webQa.sourceStartSeconds, 0);
assert.notEqual(edited.copy.environment, config.copy.environment);

const directory = 'out/08-transit-wayfinding/editability';
await mkdir(directory, {recursive: true});
await writeFile(`${directory}/props.json`, JSON.stringify({config: edited}, null, 2) + '\n');
console.log(`PASS: default 1200 frames; diagnostic 390 frames; changed caption/station/motion. Wrote ${directory}/props.json`);
