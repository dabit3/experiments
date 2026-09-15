import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {config} from './config';

const variant = structuredClone(config);
variant.durations = {opening: 2, environment: 1.5, agent: 1, iphone: 2, webQa: 1, ipad: 1.5, closing: 2};
variant.copy.environment = 'Choose your hosted Mac.';
variant.copy.cta = 'Begin your next Mac session.';
variant.motion.iphoneSplit = 0.6;
variant.motion.typingFrames = 10;
variant.motion.baselineRevealFrames = 10;
variant.motion.closingResultFrames = 6;
variant.layout.margin = 64;
const directory = path.resolve('out/15-terminal-first-cinema/variant');
await mkdir(directory, {recursive: true});
const output = path.join(directory, 'props.json');
await writeFile(output, JSON.stringify({config: variant}, null, 2) + '\n');
console.log(output);
