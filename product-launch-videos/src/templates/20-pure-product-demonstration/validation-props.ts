import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {config} from './config';

const directory = path.resolve(path.dirname(fileURLToPath(import.meta.url)),
  '../../..', 'out/20-pure-product-demonstration/validation');
const custom = structuredClone(config);
custom.durations = {opening: 1, environment: 2, agent: 1, iphone: 3, webQa: 2, ipad: 2, closing: 2};
custom.copy.environment = 'Select your hosted Mac environment.';
custom.media.agent.sourceStartSeconds = 1;
custom.media.webQa.sourceStartSeconds = 2;
custom.motion.iphoneFirstFraction = 1 / 3;
custom.motion.environmentContextSeconds = 0.25;
custom.motion.environmentMoveSeconds = 0.25;
await mkdir(directory, {recursive: true});
await writeFile(path.join(directory, 'props.json'), JSON.stringify({config: custom}, null, 2) + '\n');
console.log(path.join(directory, 'props.json'));
