import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {timelineDuration} from '../../shared/timeline';
import {config} from './config';

const edited = structuredClone(config);
edited.durations.opening = 3;
edited.durations.environment = 6;
edited.durations.iphone = 10;
edited.durations.closing = 5.5;
edited.copy.environment = 'Choose a hosted Mac environment. Your next session starts here.';
edited.layout.grid.captionSize = 40;
edited.motion.shutterAxis = 'vertical';
edited.motion.shutterFrames = 18;
edited.motion.edgeLightTravel = 40;

const target = path.resolve(process.argv[2] ?? 'out/17-cinematic-noir/editability/props.json');
await mkdir(path.dirname(target), {recursive: true});
await writeFile(target, JSON.stringify({config: edited}, null, 2) + '\n');
console.log(JSON.stringify({
  props: target,
  expectedFrames: timelineDuration(edited.durations),
  expectedSeconds: timelineDuration(edited.durations) / 30,
  changedCaptionFrame: 180,
}, null, 2));
