// Renders review stills into out/frames/ with a single bundle.
// Usage: node scripts/stills.mjs 60 200 350   (frame numbers; defaults to 8 evenly spaced)
import path from 'node:path';
import fs from 'node:fs';
import {bundle} from '@remotion/bundler';
import {renderStill, selectComposition} from '@remotion/renderer';

const root = path.dirname(new URL(import.meta.url).pathname);
const project = path.resolve(root, '..');
const outDir = path.join(project, 'out', 'frames');
fs.mkdirSync(outDir, {recursive: true});

const serveUrl = await bundle({
  entryPoint: path.join(project, 'src', 'index.ts'),
  publicDir: path.join(project, '..', '..', 'assets'),
});
const composition = await selectComposition({serveUrl, id: 'Main'});

const requested = process.argv.slice(2).map(Number);
const frames =
  requested.length > 0
    ? requested
    : Array.from({length: 8}, (_, i) => Math.round(((i + 0.5) * composition.durationInFrames) / 8));

for (const frame of frames) {
  const output = path.join(outDir, `frame-${String(frame).padStart(4, '0')}.png`);
  await renderStill({composition, serveUrl, frame, output, imageFormat: 'png'});
  console.log(output);
}
