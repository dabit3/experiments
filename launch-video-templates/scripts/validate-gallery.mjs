import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {existsSync, readFileSync} from 'node:fs';
import {dirname, resolve, sep} from 'node:path';
import {fileURLToPath} from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const gallery = resolve(process.argv[2] ?? resolve(root, 'gallery'));
const html = readFileSync(resolve(gallery, 'index.html'), 'utf8');
const rows = JSON.parse(readFileSync(resolve(root, 'out/media-validation.json'), 'utf8'));
assert.equal(rows.length, 20);
assert.equal([...html.matchAll(/<article\b/g)].length, 20);
assert.equal([...html.matchAll(/<video\b/g)].length, 20);
assert.equal([...html.matchAll(/<video controls playsinline preload="none"/g)].length, 20);
assert(!/<script\b|<iframe\b|<video[^>]*\bautoplay\b|\bdata:/i.test(html), 'Gallery must remain offline and opt-in');
for (const [, link] of html.matchAll(/(?:href|src|poster)="([^"]+)"/g)) {
  assert(!/^(?:[a-z]+:|\/\/|\/)/i.test(link), `Nonlocal gallery URL: ${link}`);
  if (link.startsWith('#')) {
    assert(html.includes(`id="${link.slice(1)}"`), `Missing anchor ${link}`);
  } else {
    const target = resolve(gallery, link.split('#')[0]);
    assert(target.startsWith(`${gallery}${sep}`), `Path escapes gallery: ${link}`);
    assert(existsSync(target), `Missing gallery target: ${link}`);
  }
}
for (const {id, title, videoSeconds, sha256} of rows) {
  assert(html.includes(`id="${id}"`) && html.includes(title), `Missing card: ${id}`);
  assert(html.includes(`${videoSeconds} seconds`), `Missing duration: ${id}`);
  assert(html.includes(`href="videos/${id}.mp4" download`), `Missing download: ${id}`);
  const video = readFileSync(resolve(gallery, 'videos', `${id}.mp4`));
  assert.equal(createHash('sha256').update(video).digest('hex'), sha256, `${id}: preview changed`);
  assert(readFileSync(resolve(gallery, 'posters', `${id}.png`)).equals(
    readFileSync(resolve(root, 'out', `${id}-poster.png`))), `${id}: poster changed`);
  const guide = readFileSync(resolve(gallery, 'guides', `${id}.html`), 'utf8');
  assert(guide.includes(`../index.html#${id}`) && guide.includes('npm run render'), `${id}: missing editing guide`);
}
const css = readFileSync(resolve(gallery, 'style.css'), 'utf8');
assert(!/@import\b|url\(/i.test(css), 'Styles must not load external assets');
console.log('PASS: 20 local cards, controls, guides, downloads, matching MP4 hashes and posters; no remote gallery dependencies');
