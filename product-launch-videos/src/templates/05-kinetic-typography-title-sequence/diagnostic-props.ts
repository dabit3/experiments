import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {config} from './config';

const alternate = structuredClone(config);
alternate.durations = {opening: 2, environment: 2, agent: 2, iphone: 3, webQa: 2, ipad: 2, closing: 2};
alternate.copy.opening = 'Devin now runs on Mac. Build iOS apps in the cloud.';
alternate.copy.environment = 'Choose a hosted Mac environment to build, run, and test iOS apps in the cloud.';
alternate.copy.cta = 'Start a Mac session with Devin to build, run, and test your next iOS app in the cloud.';
alternate.layout.margin = 64;
alternate.motion.phraseDockFrames = 12;
alternate.motion.phraseTravel = 144;
alternate.motion.iphoneSplit = 0.6;

const output = path.resolve('out/05-kinetic-typography-title-sequence/diagnostic-props.json');
await mkdir(path.dirname(output), {recursive: true});
await writeFile(output, JSON.stringify({config: alternate}, null, 2) + '\n');
console.log(output);
