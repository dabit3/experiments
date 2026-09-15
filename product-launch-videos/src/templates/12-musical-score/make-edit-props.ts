import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {config} from './config';

const edited = structuredClone(config);
edited.durations = {opening: 1, environment: 1, agent: 2, iphone: 2, webQa: 4, ipad: 1, closing: 1};
edited.copy.opening = 'Devin on Mac.';
edited.copy.environment = 'Choose your hosted Mac.';
edited.copy.cta = 'Start your Mac session with Devin.';
edited.motion.playheadTravelFrames = 8;
edited.motion.iphoneSplit = 0.6;
edited.score.tracks = ['Choose', 'See', 'Review'];

const directory = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..', 'out/12-musical-score');
await mkdir(directory, {recursive: true});
const output = path.join(directory, 'edited-props.json');
await writeFile(output, JSON.stringify({config: edited}, null, 2) + '\n');
console.log(output);
