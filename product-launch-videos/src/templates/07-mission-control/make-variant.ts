import {mkdir, writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {config} from './config';

const edited = structuredClone(config);
edited.durations = {
  opening: 2, environment: 2, agent: 2, iphone: 4, webQa: 2, ipad: 2, closing: 2,
};
edited.copy.environment = 'Choose macOS for this session.';
edited.media.agent.sourceStartSeconds = 1;
edited.media.webQa.sourceStartSeconds = 3;
edited.motion.apertureFrames = 12;
edited.motion.baySettleFrames = 10;
edited.motion.bayStaggerFrames = 2;
edited.motion.consolidationFrames = 12;
const directory = new URL('../../../out/07-mission-control/editability/', import.meta.url);
await mkdir(directory, {recursive: true});
const output = new URL('props.json', directory);
await writeFile(output, JSON.stringify({config: edited}, null, 2) + '\n');
console.log(fileURLToPath(output));
