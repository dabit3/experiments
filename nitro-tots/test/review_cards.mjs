// Renders the review video's title cards, chapter cards and caption
// lower-thirds to PNG with headless Chromium (this ffmpeg build has no
// drawtext, and the cards want the game's own Fredoka/Nunito faces).
//
//   node review_cards.mjs <spec.json> <outDir>
//
// spec.json: { "width": 1280, "height": 720, "cards": [ {id, kind, ...} ] }
//   kind "title"   : { title, subtitle, lines[] }
//   kind "chapter" : { eyebrow, title, subtitle }
//   kind "caption" : { text, detail, verdict } (transparent lower-third; verdict
//                     is an optional PASS / FAIL / FIXED chip)
//   kind "label"   : { text }                  (transparent corner tag)
//   kind "notice"  : { title, lines[] }        (opaque card, e.g. Android)
//   kind "summary" : { title, rows: [[k, v, tone]] }
import { chromium } from 'playwright';
import { readFileSync, mkdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const [specPath, outDir] = process.argv.slice(2);
if (!specPath || !outDir) {
  console.error('usage: node review_cards.mjs <spec.json> <outDir>');
  process.exit(2);
}
const spec = JSON.parse(readFileSync(specPath, 'utf8'));
mkdirSync(outDir, { recursive: true });
const here = dirname(fileURLToPath(import.meta.url));
const fonts = resolve(here, '../app/assets/fonts');
const fontUrl = (name) => `http://review.local/fonts/${name}`;

const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

const css = `
@font-face { font-family: Fredoka; src: url('${fontUrl('Fredoka.ttf')}'); }
@font-face { font-family: Nunito; src: url('${fontUrl('Nunito.ttf')}'); }
html, body { margin: 0; width: ${spec.width}px; height: ${spec.height}px; overflow: hidden; }
body { font-family: Nunito, sans-serif; color: #F2F8F7; -webkit-font-smoothing: antialiased; }
.card { position: relative; width: 100%; height: 100%; box-sizing: border-box;
  background: linear-gradient(135deg, #193B4D 0%, #071722 60%, #153E49 100%); }
.transparent { background: transparent; }
.confetti { position: absolute; border-radius: 2px; opacity: .1; }
.wrap { position: absolute; inset: 0; display: flex; flex-direction: column; justify-content: center; padding: 0 120px; }
.brand { font-family: Fredoka; font-weight: 700; font-size: 26px; letter-spacing: .12em; color: #FF6B35; text-transform: uppercase; }
.title { font-family: Fredoka; font-weight: 700; font-size: 84px; line-height: 1.02; color: #F2F8F7; margin: 10px 0 8px; }
.subtitle { font-size: 30px; font-weight: 700; color: #A5C7D1; }
.lines { margin-top: 34px; display: grid; gap: 10px; font-size: 24px; font-weight: 700; color: #CDE0E5; }
.lines div::before { content: ''; display: inline-block; width: 14px; height: 6px; border-radius: 3px; background: #FF6B35; margin-right: 14px; vertical-align: middle; }
.eyebrow { font-family: Fredoka; font-weight: 700; font-size: 24px; letter-spacing: .14em; color: #3DB7FF; text-transform: uppercase; }
.chapter .title { font-size: 76px; }
.lower { position: absolute; left: 40px; right: 40px; bottom: 36px; display: flex; align-items: flex-end; gap: 16px; }
.pill { background: rgba(7,23,34,.94); color: #fff; border-left: 4px solid #4FE3C1; border-radius: 12px; padding: 16px 26px; box-shadow: 0 6px 0 rgba(0,0,0,.18); max-width: 900px; }
.pill .text { font-family: Fredoka; font-weight: 700; font-size: 34px; line-height: 1.1; }
.pill .detail { font-size: 20px; font-weight: 700; color: #C9D1E0; margin-top: 6px; }
.verdict { font-family: Fredoka; font-weight: 700; font-size: 26px; letter-spacing: .08em; color: #fff; padding: 12px 18px;
  border-radius: 14px; margin-bottom: 4px; box-shadow: 0 5px 0 rgba(0,0,0,.18); }
.verdict.pass { background: #2E9E4F; } .verdict.fail { background: #D94E1F; } .verdict.fixed { background: #1C86D6; }
.tag { position: absolute; top: 28px; left: 40px; background: #FF6B35; color: #fff; font-family: Fredoka; font-weight: 700;
  font-size: 24px; letter-spacing: .08em; text-transform: uppercase; padding: 10px 18px; border-radius: 14px; box-shadow: 0 5px 0 #D94E1F; }
.notice { background: #071722; color: #fff; }
.notice .title { color: #fff; font-size: 64px; }
.notice .lines { color: #C9D1E0; }
.notice .lines div::before { background: #FFD23F; }
.rows { margin-top: 36px; display: grid; grid-template-columns: 1fr auto; gap: 14px 40px; font-size: 26px; font-weight: 700; }
.rows .k { color: #CDE0E5; }
.rows .v { text-align: right; font-family: Fredoka; }
.ok { color: #4FE3C1; } .warn { color: #FF9C72; } .info { color: #78CEFF; }
.badge { position: absolute; right: 60px; top: 48px; width: 112px; height: 112px; border-radius: 32px; background: #FF6B35;
  box-shadow: 0 8px 0 #D94E1F; display: grid; place-items: center; }
.badge span { font-family: Fredoka; font-weight: 700; color: #fff; font-size: 30px; line-height: .95; text-align: center; }
`;

const confetti = () => {
  const cols = ['#FF6B35', '#FF5DA2', '#3DB7FF', '#8BE04A', '#FFD23F', '#9B6DFF', '#4FE3C1'];
  let s = 0x2545f491;
  const rnd = () => ((s = (s * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff);
  let html = '';
  for (let i = 0; i < 36; i++) {
    const w = 10 + rnd() * 22, h = 8 + rnd() * 14;
    html += `<div class="confetti" style="left:${rnd() * 100}%;top:${rnd() * 100}%;width:${w}px;height:${h}px;background:${cols[i % cols.length]};transform:rotate(${rnd() * 360}deg)"></div>`;
  }
  return html;
};

function render(card) {
  switch (card.kind) {
    case 'title':
      return `<div class="card">${confetti()}<div class="badge"><span>NITRO<br>TOTS</span></div><div class="wrap">
        <div class="brand">Nitro Tots · review</div>
        <div class="title">${esc(card.title)}</div>
        <div class="subtitle">${esc(card.subtitle)}</div>
        <div class="lines">${(card.lines || []).map((l) => `<div>${esc(l)}</div>`).join('')}</div></div></div>`;
    case 'chapter':
      return `<div class="card chapter">${confetti()}<div class="wrap">
        <div class="eyebrow">${esc(card.eyebrow)}</div>
        <div class="title">${esc(card.title)}</div>
        <div class="subtitle">${esc(card.subtitle)}</div></div></div>`;
    case 'caption':
      return `<div class="card transparent"><div class="lower"><div class="pill">
        <div class="text">${esc(card.text)}</div>${card.detail ? `<div class="detail">${esc(card.detail)}</div>` : ''}</div>${
        card.verdict ? `<div class="verdict ${esc(String(card.verdict).toLowerCase())}">${esc(card.verdict)}</div>` : ''}</div></div>`;
    case 'label':
      return `<div class="card transparent"><div class="tag">${esc(card.text)}</div></div>`;
    case 'notice':
      return `<div class="card notice"><div class="wrap">
        <div class="eyebrow">${esc(card.eyebrow || 'Not verified live')}</div>
        <div class="title">${esc(card.title)}</div>
        <div class="lines">${(card.lines || []).map((l) => `<div>${esc(l)}</div>`).join('')}</div></div></div>`;
    case 'summary':
      return `<div class="card">${confetti()}<div class="wrap">
        <div class="brand">Nitro Tots · review</div>
        <div class="title" style="font-size:64px">${esc(card.title)}</div>
        <div class="rows">${(card.rows || []).map(([k, v, tone]) => `<div class="k">${esc(k)}</div><div class="v ${esc(tone || '')}">${esc(v)}</div>`).join('')}</div></div></div>`;
    default:
      throw new Error(`unknown card kind ${card.kind}`);
  }
}

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: spec.width, height: spec.height }, deviceScaleFactor: 1 });
await page.route('http://review.local/fonts/*', async (route) => {
  const name = new URL(route.request().url()).pathname.split('/').pop();
  if (!['Fredoka.ttf', 'Nunito.ttf'].includes(name)) return route.abort();
  await route.fulfill({ path: resolve(fonts, name), contentType: 'font/ttf', headers: { 'Access-Control-Allow-Origin': '*' } });
});
for (const card of spec.cards) {
  await page.setContent(`<!doctype html><html><head><style>${css}</style></head><body>${render(card)}</body></html>`, { waitUntil: 'load' });
  await page.evaluate(() => document.fonts.ready);
  const transparent = card.kind === 'caption' || card.kind === 'label';
  await page.screenshot({ path: `${outDir}/${card.id}.png`, omitBackground: transparent });
}
await browser.close();
console.log(`[cards] rendered ${spec.cards.length} cards -> ${outDir}`);
