import {execFileSync} from 'node:child_process';
import {existsSync, mkdirSync, readFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const [slug, ...extra] = process.argv.slice(2);
if (!slug || !/^\d{2}-[a-z0-9-]+$/.test(slug)) {
  throw new Error('Usage: npm run render -- 01-keynote-minimal [Remotion options]');
}
const entry = resolve(root, 'templates', slug, 'index.tsx');
if (!existsSync(entry)) throw new Error(`Missing entry: ${entry}`);
const manifest = JSON.parse(readFileSync(resolve(root, 'templates', slug, 'template.json'), 'utf8'));
mkdirSync(resolve(root, 'out'), {recursive: true});
execFileSync(process.execPath, [
  resolve(root, 'node_modules/@remotion/cli/remotion-cli.js'),
  'render', entry, manifest.compositionId,
  resolve(root, 'out', `${slug}.mp4`),
  '--codec=h264', '--pixel-format=yuv420p', '--crf=18', '--concurrency=2',
  ...extra,
], {cwd: root, stdio: 'inherit'});
