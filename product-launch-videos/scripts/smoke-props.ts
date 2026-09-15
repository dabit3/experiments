import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {defaultLaunchConfig} from '../src/shared/config';
import {projectRoot} from './discovery';

const config = structuredClone(defaultLaunchConfig);
config.durations = {opening: 1, environment: 1, agent: 1, iphone: 2, webQa: 1, ipad: 1, closing: 1};
config.media.agent.sourceStartSeconds = 1;
config.media.webQa.sourceStartSeconds = 2;
const directory = path.join(projectRoot, 'out', 'foundation-smoke');
await mkdir(directory, {recursive: true});
const output = path.join(directory, 'short-props.json');
await writeFile(output, JSON.stringify({config}, null, 2) + '\n');
console.log(output);
