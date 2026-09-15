import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {timelineDuration} from '../../shared/timeline';
import {config} from './config';

const variant = structuredClone(config);
variant.durations = {
  opening: 1.5, environment: 1.5, agent: 1, iphone: 2, webQa: 2, ipad: 1.5, closing: 2.5,
};
variant.copy.environment = 'Select a hosted Mac environment.';
variant.copy.agent = 'Select your agent.';
variant.storyboard.readingOrder = 'right-to-left';
variant.storyboard.arrangements.environment = 'stack';
variant.motion.gutterFrames = 10;
variant.motion.iphoneSplit = 0.6;

const output = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '../../../out/19-graphic-storyboard/validation/props.json',
);
await mkdir(path.dirname(output), {recursive: true});
await writeFile(output, `${JSON.stringify({config: variant}, null, 2)}\n`);
console.log(JSON.stringify({
  output, durationInFrames: timelineDuration(variant.durations, 30),
  changedCaption: variant.copy.environment, readingOrder: variant.storyboard.readingOrder,
}, null, 2));
