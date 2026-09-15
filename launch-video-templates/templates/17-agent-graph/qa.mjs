import {execFileSync} from 'node:child_process';
import console from 'node:console';
import {mkdirSync, readFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import process from 'node:process';
import {fileURLToPath} from 'node:url';

const directory = dirname(fileURLToPath(import.meta.url));
const root = resolve(directory, '../..');
const out = resolve(root, 'out');
const framesDirectory = resolve(out, '17-agent-graph-qa');
mkdirSync(framesDirectory, {recursive: true});
const samples = [...readFileSync(resolve(directory, 'qa-config.ts'), 'utf8').matchAll(/\[(\d+),/g)].map((match) => Number(match[1]));
const video = resolve(out, '17-agent-graph.mp4');
execFileSync('ffmpeg', [
  '-hide_banner', '-loglevel', 'error', '-y', '-i', video,
  '-vf', `select='${samples.map((frame) => `eq(n,${frame})`).join('+')}'`,
  '-fps_mode', 'vfr', resolve(framesDirectory, 'frame-%03d.png'),
], {stdio: 'inherit'});
execFileSync('ffmpeg', [
  '-hide_banner', '-loglevel', 'error', '-y', '-i', video,
  '-vf', "select='eq(n,90)'", '-frames:v', '1', '-update', '1',
  resolve(out, '17-agent-graph-poster.png'),
], {stdio: 'inherit'});
execFileSync(process.execPath, [
  resolve(root, 'node_modules/@remotion/cli/remotion-cli.js'), 'still',
  resolve(directory, 'contact-sheet.tsx'), 'ContactSheet',
  resolve(out, '17-agent-graph-contact-sheet.png'), '--public-dir', out,
], {cwd: root, stdio: 'inherit'});
console.log(`Extracted ${samples.length} scene/transition frames, poster, and contact sheet.`);
