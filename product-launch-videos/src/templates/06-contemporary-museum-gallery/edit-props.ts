import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {timelineDuration} from '../../shared/timeline';
import {config} from './config';

const output = fileURLToPath(new URL('../../../out/06-contemporary-museum-gallery/edited-props.json', import.meta.url));
const edited = structuredClone(config);
edited.durations.opening = 2;
edited.copy.opening = 'Devin on Mac.';
await mkdir(path.dirname(output), {recursive: true});
await writeFile(output, JSON.stringify({config: edited}, null, 2) + '\n');
console.log(`${output}\n${timelineDuration(edited.durations, 30)} frames at 30 fps`);
