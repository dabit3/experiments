import {bundle} from '@remotion/bundler';
import {renderMedia, renderStill, selectComposition} from '@remotion/renderer';
import {mkdir, readFile, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {parseArgs} from 'node:util';
import {discoverTemplates, projectRoot} from './discovery';

const {values, positionals} = parseArgs({
  allowPositionals: true,
  options: {
    template: {type: 'string'},
    entry: {type: 'string'},
    composition: {type: 'string'},
    props: {type: 'string'},
    output: {type: 'string'},
    frame: {type: 'string'},
    frames: {type: 'string'},
    scale: {type: 'string', default: '1'},
    concurrency: {type: 'string', default: '2'},
    help: {type: 'boolean'},
  },
});
const mode = positionals[0];
if (values.help || !['video', 'still'].includes(mode)) {
  console.log(`npm run render -- --template 01-swiss-grid
npm run still -- --template 01-swiss-grid --frame 150
npm run render -- --entry src/smoke/entry.tsx --composition FoundationSmoke
Options: --props <complete-props.json> --output <path> --scale 1 --concurrency 2
Still: --frame 150 OR --frames 0,150,330 (writes frame-000000.png etc.)`);
  process.exit(values.help ? 0 : 1);
}
if (values.template && (values.entry || values.composition)) {
  throw new Error('Choose --template or --entry plus --composition, not both');
}
const descriptor = values.template
  ? (await discoverTemplates()).find((item) => item.slug === values.template)
  : undefined;
if (values.template && !descriptor) throw new Error(`Unknown template ${values.template}`);
const entry = descriptor?.entry ?? (values.entry && path.resolve(projectRoot, values.entry));
const id = descriptor?.compositionId ?? values.composition;
if (!entry || !id) throw new Error('Pass --template or both --entry and --composition');
const slug = descriptor?.slug ?? id.replace(/[A-Z]/g, (c, i) => `${i ? '-' : ''}${c.toLowerCase()}`);
const outDirectory = path.join(projectRoot, 'out', slug);
let inputProps: Record<string, unknown> = {};
if (values.props) {
  const parsed: unknown = JSON.parse(await readFile(path.resolve(values.props), 'utf8'));
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error('Props must be a JSON object, normally {"config": <complete config>}');
  }
  inputProps = Object.fromEntries(Object.entries(parsed));
}
const scale = Number(values.scale);
const concurrency = Number(values.concurrency);
if (!Number.isFinite(scale) || scale <= 0 || !Number.isInteger(concurrency) || concurrency < 1) {
  throw new Error('Scale must be positive and concurrency must be a positive integer');
}
const serveUrl = await bundle({
  entryPoint: entry,
  publicDir: path.join(projectRoot, 'public'),
  outDir: path.join(projectRoot, '.cache', slug),
  onProgress: (percent) => {if (percent === 100) console.log(`Bundled ${id}`);},
});
const composition = await selectComposition({serveUrl, id, inputProps});
await mkdir(outDirectory, {recursive: true});
const metadata = {
  id, slug, entry: path.relative(projectRoot, entry),
  width: composition.width, height: composition.height, fps: composition.fps,
  durationInFrames: composition.durationInFrames,
  durationSeconds: composition.durationInFrames / composition.fps,
  outputScale: scale,
};
await writeFile(path.join(outDirectory, 'metadata.json'), JSON.stringify(metadata, null, 2) + '\n');
await writeFile(path.join(outDirectory, 'resolved-props.json'), JSON.stringify(composition.props, null, 2) + '\n');
console.log(JSON.stringify(metadata));
const rendering = {composition, serveUrl, inputProps, scale};
if (mode === 'video') {
  const outputLocation = path.resolve(values.output ?? path.join(outDirectory, `${slug}.mp4`));
  await mkdir(path.dirname(outputLocation), {recursive: true});
  let reported = -1;
  await renderMedia({
    ...rendering, outputLocation, codec: 'h264', pixelFormat: 'yuv420p',
    crf: 18, concurrency, muted: true, enforceAudioTrack: false,
    onProgress: ({progress}) => {
      const percent = Math.floor(progress * 20) * 5;
      if (percent !== reported) {
        reported = percent;
        console.log(`Rendering ${id}: ${percent}%`);
      }
    },
  });
  console.log(`\nRendered ${outputLocation}`);
} else {
  if (values.frames && values.frame) throw new Error('Use --frame or --frames, not both');
  const selected = (values.frames ?? values.frame ?? '0').split(',').map(Number);
  if (selected.some((frame) => !Number.isInteger(frame) || frame < 0 || frame >= composition.durationInFrames)) {
    throw new Error(`Frame must be within 0–${composition.durationInFrames - 1}`);
  }
  if (values.output && selected.length > 1) {
    throw new Error('--output names one image; omit it when using multiple frames');
  }
  for (const frame of selected) {
    const filename = selected.length > 1 ? `frame-${String(frame).padStart(6, '0')}.png` : 'poster.png';
    const output = path.resolve(values.output ?? path.join(outDirectory, filename));
    await mkdir(path.dirname(output), {recursive: true});
    await renderStill({...rendering, frame, output, imageFormat: 'png'});
    console.log(`Rendered ${output}`);
  }
}
