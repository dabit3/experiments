import {mkdir, writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {config} from './config';

const variant = structuredClone(config);
variant.durations = {
  opening: 3, environment: 4, agent: 3, iphone: 6, webQa: 4, ipad: 4, closing: 4,
};
variant.copy.agent = 'Choose your agent.\nBuild, run, and test iOS apps in the cloud.';
variant.copy.cta = 'Start a Mac session with Devin.\nChoose a hosted Mac environment.';
variant.motion.revealDirection = 'right';
variant.motion.revealFrames = 8;
variant.motion.iphoneSplit = 0.4;
const directory = fileURLToPath(new URL('../../../out/04-luxury-editorial-magazine/variant/', import.meta.url));
await mkdir(directory, {recursive: true});
await writeFile(`${directory}props.json`, JSON.stringify({config: variant}, null, 2) + '\n');
console.log(`${directory}props.json`);
