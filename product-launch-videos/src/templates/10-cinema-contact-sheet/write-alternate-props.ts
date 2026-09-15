import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {config} from './config';

const alternate = structuredClone(config);
alternate.durations = {opening: 3, environment: 4, agent: 3, iphone: 6, webQa: 4, ipad: 4, closing: 3};
alternate.copy.environment = 'Choose a hosted Mac environment. Your next session starts here.';
alternate.motion.iphoneSplit = 0.6;
alternate.media.agent.sourceStartSeconds = 1;
const directory = path.resolve('out/10-cinema-contact-sheet/alternate');
await mkdir(directory, {recursive: true});
const output = path.join(directory, 'props.json');
await writeFile(output, JSON.stringify({config: alternate}, null, 2) + '\n');
console.log(output);
