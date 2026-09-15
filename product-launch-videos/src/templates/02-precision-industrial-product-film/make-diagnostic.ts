import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {config} from './config';

const edited = structuredClone(config);
edited.durations = {opening: 2, environment: 2, agent: 2, iphone: 3, webQa: 3, ipad: 2, closing: 2};
edited.copy.environment = 'Choose a Mac workspace.';
edited.copy.cta = 'Start your next Mac session.';
edited.lighting.shadowOpacity = 0.09;
edited.motion.transitionTiltDegrees = 0;
edited.motion.iphoneSplit = 0.4;

const directory = path.resolve('out/02-precision-industrial-product-film/diagnostic');
await mkdir(directory, {recursive: true});
await writeFile(path.join(directory, 'props.json'), JSON.stringify({config: edited}, null, 2) + '\n');
console.log(path.join(directory, 'props.json'));
