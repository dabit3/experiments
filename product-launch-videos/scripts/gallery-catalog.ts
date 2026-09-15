import {mkdir, readFile, readdir, writeFile, copyFile} from 'node:fs/promises';
import {existsSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
import type {GalleryDescriptor} from '../src/shared/contract';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
type RecordEntry = {
  number: number; slug: string; name: string; description: string; branch: string;
  commit: string; status?: string; producerChecks: string; limitations?: string;
  checks?: {source?: string; decode?: string; error?: string};
};
type Collection = {templates: RecordEntry[]; expected: {count: number}; completedCount?: number};
const manifest = JSON.parse(await readFile(path.join(root, 'gallery-manifest.json'), 'utf8')) as Collection;
const ids = new Set<string>();
const directories = await readdir(path.join(root, 'src/templates'), {withFileTypes: true});
const slugs = directories.filter((entry) => entry.isDirectory()).map((entry) => entry.name).sort();
if (JSON.stringify(slugs) !== JSON.stringify(manifest.templates.map((entry) => entry.slug).sort())) {
  throw new Error('Manifest and source directories differ');
}
const templates = [];
for (const entry of manifest.templates) {
  const {template} = await import(pathToFileURL(path.join(root, 'src/templates', entry.slug, 'index.ts')).href) as {template: GalleryDescriptor};
  if (template.slug !== entry.slug || template.name !== entry.name || ids.has(template.compositionId)) {
    throw new Error(`Invalid or duplicate descriptor: ${entry.slug}`);
  }
  ids.add(template.compositionId);
  const {width, height, fps, durationInFrames} = template.metadata;
  if (width !== 1920 || height !== 1080 || fps !== 30 || durationInFrames !== 1200) {
    throw new Error(`Default composition metadata mismatch: ${entry.slug}`);
  }
  const output = path.join(root, 'public/renders', entry.slug);
  await mkdir(output, {recursive: true});
  await writeFile(path.join(output, 'default-props.json'), JSON.stringify({config: template.defaultConfig}, null, 2) + '\n');
  templates.push({
    number: entry.number, slug: entry.slug, name: entry.name, description: entry.description,
    branch: entry.branch, commit: entry.commit, compositionId: template.compositionId,
    status: entry.status ?? 'pending', checks: {source: entry.checks?.source ?? '', decode: entry.checks?.decode ?? '', error: entry.checks?.error ?? ''},
    producerChecks: entry.producerChecks, limitations: entry.limitations ?? '',
    controls: template.controls, defaultConfig: template.defaultConfig, metadata: template.metadata,
  });
}
await mkdir(path.join(root, '.cache'), {recursive: true});
await writeFile(path.join(root, '.cache/gallery-catalog.json'), JSON.stringify({templates}, null, 2) + '\n');
await copyFile(path.join(root, 'gallery-manifest.json'), path.join(root, 'public/gallery-manifest.json'));
const font = path.join(root, 'public/assets/NBInternationalPro-Regular.woff2');
if (existsSync(font)) {
  await mkdir(path.join(root, 'public/brand'), {recursive: true});
  await copyFile(font, path.join(root, 'public/brand/NBInternationalPro-Regular.woff2'));
}
const comparison = path.join(root, 'out/comparison/comparison.png');
if (existsSync(comparison)) {
  await copyFile(comparison, path.join(root, 'public/comparison.png'));
}
console.log(`Catalog: ${templates.length} unique compositions with 40-second / 1080p30 defaults`);
