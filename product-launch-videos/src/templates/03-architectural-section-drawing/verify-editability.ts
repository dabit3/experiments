import assert from 'node:assert/strict';
import {mkdir, writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {makeTimeline, timelineDuration} from '../../shared/timeline';
import {videoTrim} from '../../shared/video-timing';
import {assets} from '../../shared/assets';
import {config} from './config';

const edited = structuredClone(config);
edited.durations = {opening: 2, environment: 3, agent: 2, iphone: 4, webQa: 3, ipad: 3, closing: 3};
edited.copy.opening = 'Devin on Mac.';
edited.copy.environment = 'Choose your Mac environment.';
edited.copy.cta = 'Start your Mac session.';
edited.motion.planeSeparation = 38;
edited.motion.sectionRevealFrames = 12;
edited.motion.iphoneSplit = 0.6;
edited.media.agent.sourceStartSeconds = 1;
edited.media.webQa.sourceStartSeconds = 2;
assert.equal(timelineDuration(edited.durations, 30), 600);
assert.equal(timelineDuration(config.durations, 30), 1200);
for (const scene of makeTimeline(edited.durations, 30)) {
  if (scene.id === 'agent' || scene.id === 'webQa') {
    const media = edited.media[scene.id];
    videoTrim({sourceStartSeconds: media.sourceStartSeconds, durationInFrames: scene.durationInFrames},
      30, assets[media.asset].durationSeconds);
  }
}
const directory = fileURLToPath(new URL('../../../out/03-architectural-section-drawing/edited/', import.meta.url));
await mkdir(directory, {recursive: true});
const filename = `${directory}props.json`;
await writeFile(filename, JSON.stringify({config: edited}, null, 2) + '\n');
console.log(`PASS: duration and source trims; wrote full editable props to ${filename}`);
