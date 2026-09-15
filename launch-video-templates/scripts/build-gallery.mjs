import assert from 'node:assert/strict';
import {copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const gallery = resolve(root, 'gallery');
const media = resolve(process.argv[2] ?? resolve(root, 'out'));
const directions = JSON.parse(readFileSync(resolve(gallery, 'directions.json'), 'utf8'));
const ids = readdirSync(resolve(root, 'templates')).filter((id) => /^\d{2}-/.test(id)).sort();
assert.deepEqual(ids, Object.keys(directions).sort(), 'Every template needs a gallery direction');
assert.equal(ids.length, 20);
const escape = (text) => String(text).replace(/[&<>"']/g, (char) => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
})[char]);
const templates = ids.map((id) => ({
  ...JSON.parse(readFileSync(resolve(root, 'templates', id, 'template.json'), 'utf8')), id,
}));
for (const {id} of templates) {
  for (const suffix of ['.mp4', '-poster.png']) {
    assert(existsSync(resolve(media, `${id}${suffix}`)), `Missing ${id}${suffix} in ${media}`);
  }
}
for (const dir of ['videos', 'posters', 'guides']) mkdirSync(resolve(gallery, dir), {recursive: true});
const cards = templates.map(({id, title, durationSeconds}) => {
  copyFileSync(resolve(media, `${id}.mp4`), resolve(gallery, 'videos', `${id}.mp4`));
  copyFileSync(resolve(media, `${id}-poster.png`), resolve(gallery, 'posters', `${id}.png`));
  const guide = readFileSync(resolve(root, 'templates', id, 'README.md'), 'utf8');
  writeFileSync(resolve(gallery, 'guides', `${id}.html`), `<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${escape(title)} — editing guide</title><link rel="stylesheet" href="../style.css">
<main class="guide"><p><a href="../index.html#${id}">Back to the collection</a></p>
<h1>${escape(title)}</h1><pre class="readme">${escape(guide)}</pre></main></html>\n`);
  return `<article class="card" id="${id}" aria-labelledby="title-${id}">
  <video controls playsinline preload="none" poster="posters/${id}.png" aria-label="${escape(title)} preview">
    <source src="videos/${id}.mp4" type="video/mp4">
    Your browser cannot play this video. Use the MP4 download below.
  </video>
  <div class="card-body"><p class="eyebrow">${id.slice(0, 2)} / ${durationSeconds} seconds</p>
    <h2 id="title-${id}">${escape(title)}</h2><p>${escape(directions[id])}</p>
    <p class="sound">${id === '06-kinetic-type' ? 'Original beat · audio on playback' : 'Silent · source audio muted'}</p>
    <div class="actions"><a href="videos/${id}.mp4" download>Download / open MP4</a><a href="guides/${id}.html">Editing guide</a></div>
    <details><summary>Edit and render this direction</summary>
      <p>In the editable source package, change <code>templates/${id}/config.ts</code> for copy and timing;
      use <code>index.tsx</code> for layout and motion. See the editing guide for direction-specific files.</p>
      <pre>npm run render -- ${id}</pre>
    </details>
  </div></article>`;
}).join('\n');
writeFileSync(resolve(gallery, 'index.html'), `<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="description" content="Twenty editable Devin macOS and iOS launch video directions.">
<title>Devin — Native launch collection</title><link rel="stylesheet" href="style.css"></head>
<body><a class="skip" href="#collection">Skip to videos</a>
<header><p class="eyebrow">Devin / macOS + iOS / Launch collection</p>
<h1>One story.<br>Twenty directions.</h1>
<p class="intro">Build. Run. See it. Explore twenty independent motion systems for native app development.</p>
<div class="facts"><span>20 editable templates</span><span>1920 × 1080 · 30 fps</span><span>40–44 seconds</span><span>Offline previews</span></div>
<p class="hint">Choose a poster and press play. Videos load only when requested. Kinetic Type includes an original beat; the other directions are silent.</p>
<p class="hint">MP4 links download in supporting browsers and open in a player otherwise. The extracted gallery already contains every original in its <code>videos</code> folder.</p>
<nav><a href="#collection">Browse the collection</a><a href="#source">Use the editable sources</a><a href="#notes">Read the production notes</a></nav></header>
<main><section class="collection" id="collection" aria-label="Twenty launch videos">${cards}</section>
<section class="notes" id="source"><p class="eyebrow">Make it yours</p><h2>Edit the source. Render a new film.</h2>
<p>Unzip the separate editable-source package and open its <code>launch-video-templates</code> directory.
Install Node.js 22 or newer, then run:</p>
<pre>npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 01-keynote-minimal</pre>
<p>Rendering uses Remotion and downloads its headless browser on first use. The result is
<code>out/&lt;template-id&gt;.mp4</code>. Each card has its exact render command and a local copy of the source README.
To update this gallery after rendering, produce each poster with its template QA helper, then run
<code>node scripts/build-gallery.mjs</code> from the source project.</p></section>
<section class="notes" id="notes"><p class="eyebrow">Production notes</p><h2>Read the evidence in context.</h2>
<p>Native iPhone sequences use supplied screenshots and illustrative motion mockups. They are not newly recorded native tests.
Every direction also includes actual muted web-app QA footage, labeled as generic web QA.
Failed and untested source checks are retained; no passing retest is invented.</p>
<p>The supplied desktop model-selector recording is not a cloud Mac VM selector. “20+ minutes” is prior CI context, not a measured speedup.
The stated Linux VM price parity comes from the launch brief.</p>
<p>Licensed NB International Pro and Inter font files were not supplied; documented system fallbacks were used.
Re-rendering on another system may change typography. Video-stream durations are exact; silent AAC padding can slightly extend a container.
These MP4 previews need no server, account, CDN or internet connection after extraction.</p></section></main>
<footer>Devin · Native launch collection · Twenty independent directions</footer></body></html>\n`);
console.log(`Populated twenty local previews, posters and editing guides in ${gallery}`);
