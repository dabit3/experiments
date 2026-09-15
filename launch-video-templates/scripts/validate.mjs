import assert from 'node:assert/strict';
import {existsSync, readdirSync, readFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const folders = readdirSync(resolve(root, 'templates')).filter((name) => /^\d{2}-/.test(name));
assert(folders.length > 0, 'No templates have been added');
for (const slug of folders) {
  const dir = resolve(root, 'templates', slug);
  const manifest = JSON.parse(readFileSync(resolve(dir, 'template.json'), 'utf8'));
  assert.equal(manifest.id, slug);
  assert.equal(typeof manifest.title, 'string');
  assert.equal(manifest.compositionId, 'Launch');
  assert.equal(manifest.width, 1920);
  assert.equal(manifest.height, 1080);
  assert.equal(manifest.fps, 30);
  assert(manifest.durationSeconds >= 28 && manifest.durationSeconds <= 50);
  assert(existsSync(resolve(dir, 'index.tsx')));
  assert(existsSync(resolve(dir, 'README.md')));
  console.log(`${slug}: manifest valid`);
}
console.log(`${folders.length} templates validated`);
