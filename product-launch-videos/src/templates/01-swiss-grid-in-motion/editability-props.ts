import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {config} from './config';

const edited = structuredClone(config);
edited.durations = {opening: 2, environment: 2, agent: 1, iphone: 2, webQa: 1, ipad: 1, closing: 3};
edited.copy.opening = 'Build iOS apps with Devin.';
edited.copy.environment = 'Select your Mac environment.';
edited.copy.cta = 'Start a Mac session.';
edited.layout.grid.railWidth = 250;
edited.brand.typography.headingSize = 148;
edited.media.environment.framing.anchorX = 0.45;
edited.motion.panelRevealFrames = 8;
edited.motion.typeRevealFrames = 8;
edited.motion.typeTravel = 20;
edited.motion.panelTravel = 24;

const directory = path.resolve('out/01-swiss-grid-in-motion');
await mkdir(directory, {recursive: true});
const output = path.join(directory, 'editability-props.json');
await writeFile(output, JSON.stringify({config: edited}, null, 2) + '\n');
console.log(output);
