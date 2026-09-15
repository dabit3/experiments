// Programmatic review edit of a multiplayer e2e run.
//
//   node review_video.mjs <runDir> [--extra <runDir>]... [--out review.mp4]
//
// Reads report.json (phase timeline, recording start times, screenshots,
// visual-parity summary) and cuts an edited review video: title and chapter
// cards, per-phase clips of the per-platform recordings laid out side by side
// on one canvas with platform labels and captions, screenshot slides, a
// visual-parity slide and a verdict card. Chapters are written as MP4 chapter
// metadata and the full edit decision list is saved next to the video as
// review-edl.json. Overlays are rendered with Playwright (ffmpeg here has no
// drawtext), composited with ffmpeg.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..', '..');
const fontsDir = path.join(root, 'app', 'assets', 'fonts');

const W = 1920;
const H = 1080;
const FPS = 30;
const HEADER = 72;
const CAPTION = 96;
const GAP = 16;

const platformMeta = {
  web: { title: 'Web', sub: 'Chrome · Playwright' },
  ios: { title: 'iOS', sub: 'iOS Simulator · xcrun simctl' },
  android: { title: 'Android', sub: 'Android emulator · adb' },
  macos: { title: 'macOS', sub: 'native window' },
};

const experienceNames = {
  obby: 'Skyline Obby',
  tycoon: 'Brick Tycoon',
  tag: 'Freeze Tag Arena',
};

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);
let runDir = null;
const extras = [];
let out = null;
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--extra') extras.push(path.resolve(args[++i]));
  else if (args[i] === '--out') out = path.resolve(args[++i]);
  else runDir ??= args[i];
}
if (!runDir) {
  console.error('usage: node review_video.mjs <runDir> [--extra <runDir>]... [--out file.mp4]');
  process.exit(2);
}
const run = path.resolve(runDir);
out ??= path.join(run, 'review.mp4');
const work = path.join(run, 'review-parts');
fs.rmSync(work, { recursive: true, force: true });
fs.mkdirSync(work, { recursive: true });

const report = JSON.parse(await fsp.readFile(path.join(run, 'report.json'), 'utf8'));
const platforms = report.platforms;
const ffmpeg = ['/opt/homebrew/bin/ffmpeg', 'ffmpeg'].find((f) => f.includes('/') ? fs.existsSync(f) : true);
const ffprobe = ffmpeg.replace(/ffmpeg$/, 'ffprobe');

function log(msg) {
  console.log(`[review] ${msg}`);
}

function exec(cmd, argv) {
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, argv, { stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '';
    let stderr = '';
    p.stdout.on('data', (d) => (stdout += d));
    p.stderr.on('data', (d) => (stderr += d));
    p.on('close', (code) => {
      if (code === 0) resolve(stdout);
      else reject(new Error(`${path.basename(cmd)} exited ${code}\n${stderr.slice(-1200)}`));
    });
  });
}

async function probe(file) {
  const outp = await exec(ffprobe, [
    '-v', 'error', '-select_streams', 'v:0',
    '-show_entries', 'stream=width,height:format=duration',
    '-of', 'json', file,
  ]);
  const j = JSON.parse(outp);
  return {
    width: j.streams[0].width,
    height: j.streams[0].height,
    duration: Number(j.format.duration),
  };
}

// ---------------------------------------------------------------------------
// Layout: landscape recordings stack in a left column, portrait ones stand to
// the right; everything is centred in the zone between header and caption.
// ---------------------------------------------------------------------------

function layoutTiles(sources) {
  const zoneY = HEADER + 36;
  const zoneH = H - zoneY - CAPTION - 16;
  const landscape = sources.filter((s) => s.width >= s.height);
  const portrait = sources.filter((s) => s.width < s.height);
  const boxes = [];
  if (portrait.length === 0 && landscape.length === 2) {
    const w = (W - 2 * 48 - GAP) / 2;
    for (const [i, s] of landscape.entries()) {
      const h = Math.min(zoneH, Math.round(w / (s.width / s.height)));
      boxes.push({ ...s, x: 48 + i * (w + GAP), y: zoneY + Math.round((zoneH - h) / 2), w: Math.round(w) - (Math.round(w) % 2), h: h - (h % 2) });
    }
    return boxes;
  }
  let x = 0;
  if (landscape.length) {
    const vGap = 44; // room for the next tile's label
    const h = Math.floor((zoneH - vGap * (landscape.length - 1)) / landscape.length);
    const w = Math.round(Math.max(...landscape.map((s) => h * (s.width / s.height))));
    for (const [i, s] of landscape.entries()) {
      boxes.push({ ...s, x, y: zoneY + i * (h + vGap), w, h });
    }
    x += w + GAP;
  }
  for (const s of portrait) {
    const w = Math.round(zoneH * (s.width / s.height));
    boxes.push({ ...s, x, y: zoneY, w, h: zoneH });
    x += w + GAP;
  }
  const total = x - GAP;
  const shift = Math.round((W - total) / 2);
  for (const b of boxes) {
    b.x += shift;
    b.w -= b.w % 2;
    b.h -= b.h % 2;
  }
  return boxes;
}

// ---------------------------------------------------------------------------
// Overlay rendering (Playwright → PNG)
// ---------------------------------------------------------------------------

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });

const css = `
  @font-face { font-family: Inter; src: url('file://${fontsDir}/Inter-Regular.ttf'); font-weight: 400; }
  @font-face { font-family: Inter; src: url('file://${fontsDir}/Inter-Medium.ttf'); font-weight: 500; }
  @font-face { font-family: Inter; src: url('file://${fontsDir}/Inter-SemiBold.ttf'); font-weight: 600; }
  @font-face { font-family: Inter; src: url('file://${fontsDir}/Inter-Bold.ttf'); font-weight: 700; }
  @font-face { font-family: Inter; src: url('file://${fontsDir}/Inter-ExtraBold.ttf'); font-weight: 800; }
  * { box-sizing: border-box; margin: 0; }
  html, body { width: ${W}px; height: ${H}px; overflow: hidden; font-family: Inter, system-ui, sans-serif;
    color: #fff; -webkit-font-smoothing: antialiased; }
  body.solid { background: #191A1F; }
  .header { position: absolute; left: 0; right: 0; top: 0; height: ${HEADER}px; background: #191A1F;
    display: flex; align-items: center; padding: 0 40px; gap: 20px; }
  .logo { width: 36px; height: 36px; border-radius: 8px; background: #fff; display: grid; place-items: center; }
  .logo span { width: 18px; height: 18px; border-radius: 3px; background: #191A1F;
    background-image: linear-gradient(#191A1F, #191A1F); }
  .brand { font-weight: 800; font-size: 24px; letter-spacing: -0.3px; }
  .chapter { font-weight: 500; font-size: 20px; color: #BDBEBE; }
  .chapter b { color: #fff; font-weight: 700; }
  .spacer { flex: 1; }
  .meta { font-size: 15px; color: #8F9092; font-weight: 500; font-variant-numeric: tabular-nums; }
  .caption { position: absolute; left: 0; right: 0; bottom: 0; height: ${CAPTION}px;
    background: linear-gradient(rgba(25,26,31,0), rgba(25,26,31,.92) 35%); display: flex; align-items: flex-end;
    padding: 0 40px 22px; gap: 16px; }
  .caption .num { min-width: 40px; height: 40px; border-radius: 8px; background: #335FFF; display: grid; place-items: center;
    font-weight: 800; font-size: 20px; }
  .caption .text { font-size: 24px; font-weight: 600; line-height: 1.2; }
  .caption .note { font-size: 16px; color: #BDBEBE; font-weight: 500; margin-top: 2px; }
  .label { position: absolute; display: flex; align-items: baseline; gap: 10px; }
  .label .t { font-weight: 800; font-size: 18px; }
  .label .s { font-weight: 500; font-size: 13px; color: #BDBEBE; }
  .frame { position: absolute; border-radius: 10px; box-shadow: 0 0 0 2px #35363D inset; }
  .card { position: absolute; inset: 0; background: #191A1F; padding: 120px 140px; }
  .card h1 { font-size: 72px; font-weight: 800; letter-spacing: -1.5px; line-height: 1.05; }
  .card h2 { font-size: 30px; font-weight: 500; color: #BDBEBE; margin-top: 18px; }
  .card .kicker { font-size: 20px; font-weight: 700; letter-spacing: 3px; color: #335FFF; text-transform: uppercase; }
  .pills { display: flex; gap: 12px; margin-top: 44px; flex-wrap: wrap; }
  .pill { padding: 12px 20px; border-radius: 999px; background: #2A2B32; font-size: 20px; font-weight: 600; }
  .pill.ok { background: #00B06F; }
  .pill.bad { background: #E8455C; }
  .grid { position: absolute; left: 40px; right: 40px; top: ${HEADER + 40}px; bottom: ${CAPTION + 8}px; display: flex;
    flex-direction: column; align-items: center; justify-content: center; }
  .row { display: flex; gap: 24px; align-items: flex-end; justify-content: center; }
  .shot { display: flex; flex-direction: column; gap: 10px; align-items: flex-start; flex: none; }
  .shot img { display: block; border-radius: 10px; box-shadow: 0 0 0 2px #35363D; }
  .pairs { position: absolute; left: 40px; right: 40px; top: ${HEADER + 34}px; bottom: ${CAPTION + 8}px;
    display: grid; grid-template-columns: repeat(2, 1fr); grid-auto-rows: 1fr; gap: 14px 40px; }
  .pair { display: grid; grid-template-columns: 1fr 1fr auto; gap: 12px; align-items: center; }
  .pair img { width: 100%; border-radius: 6px; box-shadow: 0 0 0 1px #35363D; }
  .pair .res { width: 210px; font-size: 15px; color: #BDBEBE; font-weight: 500; line-height: 1.35; }
  .pair .res b { display: block; color: #fff; font-size: 17px; font-weight: 700; margin-bottom: 4px; }
  .pair .res .ok { color: #00B06F; }
  .pair .res .bad { color: #E8455C; }
  table { border-collapse: collapse; margin-top: 36px; font-size: 24px; }
  th { text-align: left; color: #8F9092; font-weight: 600; padding: 10px 40px 10px 0; border-bottom: 1px solid #35363D; }
  td { padding: 14px 40px 14px 0; border-bottom: 1px solid #2A2B32; font-variant-numeric: tabular-nums; }
  td.rank { color: #F5C04A; font-weight: 800; }
`;

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

async function render(body, file, { solid }) {
  // Loaded from disk (not setContent) so file:// images and fonts resolve.
  const html = file.replace(/\.png$/, '.html');
  await fsp.writeFile(html, `<!doctype html><html><head><style>${css}</style></head><body class="${solid ? 'solid' : ''}">${body}</body></html>`);
  await page.goto(`file://${html}`);
  await page.evaluate(() => document.fonts.ready);
  await page.evaluate(() => Promise.all([...document.images].map((im) => im.decode().catch(() => null))));
  await page.screenshot({ path: file, omitBackground: !solid });
  return file;
}

const runId = path.basename(run);
const header = (chapter) =>
  `<div class="header"><div class="logo"><span></span></div><div class="brand">Brickfolk</div>` +
  `<div class="chapter">${chapter}</div><div class="spacer"></div><div class="meta">${esc(runId)}</div></div>`;
const caption = (num, text, note) =>
  `<div class="caption"><div class="num">${num}</div><div><div class="text">${esc(text)}</div>` +
  (note ? `<div class="note">${esc(note)}</div>` : '') + `</div></div>`;

let overlayIndex = 0;
async function clipOverlay(chapter, boxes, num, text, note) {
  const labels = boxes
    .map(
      (b) =>
        `<div class="frame" style="left:${b.x}px;top:${b.y}px;width:${b.w}px;height:${b.h}px"></div>` +
        `<div class="label" style="left:${b.x + 2}px;top:${b.y - 30}px"><span class="t">${platformMeta[b.platform].title}</span>` +
        `<span class="s">${platformMeta[b.platform].sub}${b.player ? ` · ${esc(b.player)}` : ''}${b.still ? ' · recording ended, screenshot' : ''}</span></div>`,
    )
    .join('');
  return render(header(`Chapter ${num} · <b>${chapter}</b>`) + labels + caption(num, text, note), path.join(work, `overlay-${overlayIndex++}.png`), { solid: false });
}

// ---------------------------------------------------------------------------
// Segment encoders
// ---------------------------------------------------------------------------

const parts = [];
const edl = [];
const encode = ['-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-preset', 'veryfast', '-crf', '22', '-r', String(FPS), '-an'];

function fade(dur) {
  return `fade=t=in:st=0:d=0.35,fade=t=out:st=${Math.max(0, dur - 0.45).toFixed(3)}:d=0.45`;
}

async function stillPart(png, dur, chapter, description) {
  const file = path.join(work, `part-${String(parts.length).padStart(2, '0')}.mp4`);
  await exec(ffmpeg, [
    '-y', '-v', 'error', '-loop', '1', '-framerate', String(FPS), '-t', dur.toFixed(3), '-i', png,
    '-vf', `format=yuv420p,${fade(dur)}`, ...encode, file,
  ]);
  parts.push({ file, chapter, dur });
  edl.push({ type: 'still', source: path.relative(run, png), seconds: dur, chapter, description });
  log(`still  ${path.basename(file)} ${dur.toFixed(1)}s  ${description}`);
}

// A clip shows every platform recording between two wall-clock instants,
// aligned by each recording's own start time. A recording that ended before
// the window is stood in for by the platform's screenshot of that phase (or
// its last frame), and the tile says so.
async function clipPart({ from, to, speed = 1, chapter, num, text, note, sources, startedAt, phase }) {
  const dur = (to - from) / 1000;
  if (dur < 1.5) return;
  const boxes = layoutTiles(sources).map((b) => {
    const ss = Math.max(0, (from - startedAt[b.platform]) / 1000);
    if (ss < b.duration - 0.1) return { ...b, ss };
    const shot = phase ? path.join(run, `${b.platform}-${phase}.png`) : null;
    const still = shot && fs.existsSync(shot) ? shot : null;
    log(`${b.platform} recording ends at ${b.duration.toFixed(1)}s, before ${ss.toFixed(1)}s; using ${still ? path.basename(still) : 'its last frame'}`);
    return { ...b, ss, still: still ?? 'last-frame' };
  });
  const overlay = await clipOverlay(chapter, boxes, num, text, note);
  const outDur = dur / speed;
  const inputs = [];
  const filters = [];
  let chain = `color=c=0x191A1F:s=${W}x${H}:r=${FPS}:d=${outDur.toFixed(3)}[base]`;
  filters.push(chain);
  let last = 'base';
  boxes.forEach((b, i) => {
    if (b.still === 'last-frame') inputs.push('-sseof', '-0.2', '-i', b.file);
    else if (b.still) inputs.push('-loop', '1', '-framerate', String(FPS), '-t', dur.toFixed(3), '-i', b.still);
    else inputs.push('-ss', b.ss.toFixed(3), '-t', dur.toFixed(3), '-i', b.file);
    const setpts = speed === 1 ? '' : `setpts=PTS/${speed},`;
    filters.push(
      `[${i}:v]${setpts}fps=${FPS},scale=${b.w}:${b.h}:force_original_aspect_ratio=decrease:force_divisible_by=2,` +
        `pad=${b.w}:${b.h}:(ow-iw)/2:(oh-ih)/2:color=0x232529,setsar=1,` +
        `tpad=stop_mode=clone:stop_duration=${outDur.toFixed(3)}[t${i}]`,
    );
    filters.push(`[${last}][t${i}]overlay=${b.x}:${b.y}:eof_action=repeat[o${i}]`);
    last = `o${i}`;
  });
  inputs.push('-loop', '1', '-framerate', String(FPS), '-t', outDur.toFixed(3), '-i', overlay);
  filters.push(`[${last}][${boxes.length}:v]overlay=0:0:eof_action=repeat,${fade(outDur)}[out]`);
  const file = path.join(work, `part-${String(parts.length).padStart(2, '0')}.mp4`);
  await exec(ffmpeg, [
    '-y', '-v', 'error', ...inputs, '-filter_complex', filters.join(';'), '-map', '[out]',
    '-t', outDur.toFixed(3), ...encode, file,
  ]);
  parts.push({ file, chapter, dur: outDur });
  edl.push({
    type: 'clip', chapter, caption: text, note, speed,
    wallClock: { from: new Date(from).toISOString(), to: new Date(to).toISOString() },
    seconds: outDur,
    tiles: boxes.map((b) => ({
      platform: b.platform, source: path.relative(run, b.file), inSeconds: b.ss,
      ...(b.still ? { still: b.still === 'last-frame' ? 'last-frame' : path.relative(run, b.still), recordingSeconds: b.duration } : {}),
      box: { x: b.x, y: b.y, w: b.w, h: b.h },
    })),
  });
  log(`clip   ${path.basename(file)} ${outDur.toFixed(1)}s x${speed}  ${text}`);
}

// ---------------------------------------------------------------------------
// Build the edit
// ---------------------------------------------------------------------------

const exp = experienceNames[report.experience] ?? report.experience;
const verdict = report.passed ? 'PASSED' : 'FAILED';

// Player names per platform from the server snapshot (best effort).
let playerByPlatform = {};
try {
  const state = JSON.parse(await fsp.readFile(path.join(run, 'server-state.json'), 'utf8'));
  const room = state.rooms.find((r) => r.code === report.room);
  for (const m of room?.members ?? []) if (!m.player.isBot) playerByPlatform[m.player.platform] = m.player.name;
} catch {
  playerByPlatform = {};
}

const sources = [];
for (const p of platforms) {
  const file = report.recordings[p];
  if (!file || !fs.existsSync(file)) continue;
  sources.push({ platform: p, file, player: playerByPlatform[p], ...(await probe(file)) });
}
const startedAt = report.recordingStartedAt ?? {};
const timeline = report.timeline ?? {};
const min = (phase) => {
  const v = platforms.map((p) => timeline[p]?.[phase]).filter((t) => typeof t === 'number');
  return v.length ? Math.min(...v) : null;
};
const max = (phase) => {
  const v = platforms.map((p) => timeline[p]?.[phase]).filter((t) => typeof t === 'number');
  return v.length ? Math.max(...v) : null;
};
const haveClips = sources.length === platforms.length && sources.every((s) => typeof startedAt[s.platform] === 'number') && min('lobby') != null;
if (!haveClips) log('no aligned recordings/timeline in report.json; the review will use screenshots only');

// 1 · Title
await stillPart(
  await render(
    `<div class="card"><div class="kicker">Automated cross-platform review</div>` +
      `<h1>Brickfolk<br>${esc(exp)} · ${platforms.length}-way multiplayer</h1>` +
      `<h2>${platforms.map((p) => platformMeta[p].title).join(' · ')} join one party and one room, play a full match with scripted inputs, and must agree on the final leaderboard.</h2>` +
      `<div class="pills"><div class="pill">seed ${esc(report.seed)}</div><div class="pill">party ${esc(report.party)}</div><div class="pill">room ${esc(report.room)}</div>` +
      `<div class="pill">${esc(runId)}</div><div class="pill ${report.passed ? 'ok' : 'bad'}">${verdict}</div></div></div>`,
    path.join(work, 'title.png'), { solid: true },
  ),
  5, 'Intro', 'title card',
);

// 2 · Hub visual parity
if (report.visual?.screens?.length) {
  const v = report.visual;
  const pairs = v.screens
    .map((s) => {
      const ref = s.metrics?.reference_source;
      const act = s.metrics?.actual_source;
      if (!ref || !act || !fs.existsSync(ref) || !fs.existsSync(act)) return '';
      const diff = s.metrics?.different_pixels;
      return (
        `<div class="pair"><img src="file://${ref}"><img src="file://${act}"><div class="res"><b>${esc(s.screen)}</b>` +
        `<span class="${s.passed ? 'ok' : 'bad'}">${s.passed ? 'match' : 'mismatch'}</span> · ${diff ?? '?'} px differ` +
        `<br>${esc(v.reference)} reference · ${esc(v.actual)} actual</div></div>`
      );
    })
    .join('');
  const passed = v.screens.filter((s) => s.passed).length;
  await stillPart(
    await render(
      header(`Chapter 1 · <b>Hub & visual parity</b>`) + `<div class="pairs">${pairs}</div>` +
        caption(1, `Same signed-in player, same hub screens: ${v.reference} (reference) vs ${v.actual}`,
          `${passed}/${v.screens.length} screens match after normalisation (window chrome cropped, platform chip masked)`),
      path.join(work, 'parity.png'), { solid: true },
    ),
    7, 'Hub & visual parity', 'web vs macOS hub tour comparison',
  );
}

// Screenshot grid slide helper. Screenshots share one row height, chosen so
// the row fits the zone between header and caption in both dimensions
// (native screenshots are far larger than the slide).
async function gridSlide(phase, num, chapter, text, note, dir = run, plats = platforms, file = `${phase}.png`) {
  const files = plats.map((p) => [p, path.join(dir, `${p}-${phase}.png`)]).filter(([, f]) => fs.existsSync(f));
  const dims = await Promise.all(files.map(([, f]) => probe(f)));
  const labelH = 34;
  const rowGap = 28;
  const zoneH = H - (HEADER + 40) - (CAPTION + 8);
  // One or two rows, whichever shows the screenshots larger.
  const rowHeightFor = (rows) => {
    const perRow = Math.ceil(files.length / rows);
    const maxH = (zoneH - rowGap * (rows - 1)) / rows - labelH;
    let h = maxH;
    for (let r = 0; r < rows; r++) {
      const chunk = dims.slice(r * perRow, (r + 1) * perRow);
      const zoneW = W - 80 - 24 * Math.max(0, chunk.length - 1);
      const aspectSum = chunk.reduce((a, d) => a + d.width / d.height, 0);
      if (aspectSum) h = Math.min(h, zoneW / aspectSum);
    }
    return { rows, perRow, h: Math.floor(h) };
  };
  const layout = [rowHeightFor(1), ...(files.length > 1 ? [rowHeightFor(2)] : [])].sort((a, b) => b.h - a.h)[0];
  const rowsHtml = [];
  for (let r = 0; r < layout.rows; r++) {
    const shots = files
      .slice(r * layout.perRow, (r + 1) * layout.perRow)
      .map(([p, f], j) => {
        const d = dims[r * layout.perRow + j];
        const w = Math.round(layout.h * (d.width / d.height));
        return `<div class="shot"><div class="label" style="position:static"><span class="t">${platformMeta[p].title}</span><span class="s">${platformMeta[p].sub}</span></div><img src="file://${f}" style="width:${w}px;height:${layout.h}px"></div>`;
      })
      .join('');
    rowsHtml.push(`<div class="row">${shots}</div>`);
  }
  return stillPart(
    await render(header(`Chapter ${num} · <b>${chapter}</b>`) + `<div class="grid" style="gap:${rowGap}px">${rowsHtml.join('')}</div>` + caption(num, text, note),
      path.join(work, file), { solid: true }),
    5, chapter, `${phase} screenshots`,
  );
}

// 3 · Lobby
const lobbyAt = min('lobby');
const countdownAt = min('countdown') ?? (lobbyAt != null ? lobbyAt + 8000 : null);
const gameplayAt = min('gameplay');
const resultsAt = min('results');
const resultsAllAt = max('results');
const allRecording = haveClips ? Math.max(...sources.map((s) => startedAt[s.platform])) : null;

await gridSlide('lobby', 2, 'Lobby', `Every client joins party ${report.party} and lands in room ${report.room}`,
  'Seats show platform chips; the harness readies each client once all are present');
if (haveClips && countdownAt) {
  await clipPart({
    from: Math.max(allRecording, lobbyAt, countdownAt - 8000), to: countdownAt + 500, chapter: 'Lobby', num: 2,
    text: 'Live: all four clients seated in the same room, readying up', note: 'Recordings aligned on wall-clock time',
    sources, startedAt, phase: 'lobby',
  });
}

// 4 · Countdown & gameplay
if (haveClips && gameplayAt) {
  await clipPart({
    from: countdownAt ?? gameplayAt - 5000, to: Math.min(gameplayAt + 9000, resultsAt ?? Infinity), chapter: 'Gameplay', num: 3,
    text: `Countdown, then ${exp} starts on all clients at the same server tick`,
    note: platforms.includes('android') ? 'Android runs on a software-accelerated emulator; its display trails the app' : undefined,
    sources, startedAt, phase: 'gameplay',
  });
  const midFrom = gameplayAt + 9000;
  const midTo = (resultsAt ?? gameplayAt + 60000) - 4000;
  if (midTo - midFrom > 6000) {
    await clipPart({
      from: midFrom, to: midTo, speed: midTo - midFrom > 30000 ? 4 : 2, chapter: 'Gameplay', num: 3,
      text: 'Scripted inputs drive every client through the course', note: `${midTo - midFrom > 30000 ? '4' : '2'}× speed · server-authoritative simulation at 30 ticks/s`,
      sources, startedAt, phase: 'gameplay',
    });
  }
}
await gridSlide('gameplay', 3, 'Gameplay', `${exp} · HUD with live player list, stage and timer on every platform`,
  'Screenshots taken by the harness once each client rasterised the playing phase');

// 5 · Results
if (haveClips && resultsAt) {
  await clipPart({
    from: resultsAt - 4000, to: Math.max(resultsAllAt, resultsAt) + 6000, chapter: 'Results', num: 4,
    text: 'Finish → results screen on every client', note: `Checksum ${report.checksum} reported by all ${platforms.length} clients and the server`,
    sources, startedAt, phase: 'results',
  });
}
await gridSlide('results', 4, 'Results', 'Identical leaderboard and podium across all platforms',
  `client checksum ${report.checksum} · server ${report.serverChecksum}`);

// 6 · Extra runs (e.g. tycoon / tag evidence)
let extraNum = 5;
for (const dir of extras) {
  try {
    const r = JSON.parse(await fsp.readFile(path.join(dir, 'report.json'), 'utf8'));
    const name = experienceNames[r.experience] ?? r.experience;
    await gridSlide('gameplay', extraNum, name, `${name} · ${r.platforms.map((p) => platformMeta[p].title).join(' + ')} · ${r.passed ? 'passed' : 'FAILED'}`,
      `room ${r.room} · checksum ${r.checksum} · ${path.basename(dir)}`, dir, r.platforms, `extra-${extraNum}-gameplay.png`);
    await gridSlide('results', extraNum, name, `${name} · results agree on ${r.platforms.length}/${r.platforms.length} clients`,
      r.leaderboard.slice(0, 3).map((e) => `#${e.rank} ${e.player} ${e.detail ?? e.score}`).join(' · '), dir, r.platforms, `extra-${extraNum}-results.png`);
    extraNum++;
  } catch (e) {
    log(`extra run ${dir} skipped: ${e.message}`);
  }
}

// 7 · Verdict
const rows = (report.leaderboard ?? [])
  .map((e) => `<tr><td class="rank">${e.rank}</td><td>${esc(e.player)}</td><td>${esc(e.detail ?? '')}</td><td>${esc(e.score)}</td></tr>`)
  .join('');
await stillPart(
  await render(
    `<div class="card"><div class="kicker">Verdict</div><h1>${verdict}</h1>` +
      `<h2>${platforms.length}/${platforms.length} clients report the same final state · checksum ${esc(report.checksum)} (server ${esc(report.serverChecksum)})` +
      (report.visual ? ` · hub parity ${report.visual.screens.filter((s) => s.passed).length}/${report.visual.screens.length}` : '') + `</h2>` +
      `<table><tr><th>#</th><th>Player</th><th>Detail</th><th>Score</th></tr>${rows}</table>` +
      (report.failures?.length ? `<div class="pills">${report.failures.map((f) => `<div class="pill bad">${esc(f)}</div>`).join('')}</div>` : '') +
      `</div>`,
    path.join(work, 'verdict.png'), { solid: true },
  ),
  6, 'Verdict', 'verdict card with leaderboard',
);

await browser.close();

// ---------------------------------------------------------------------------
// Concatenate + chapters
// ---------------------------------------------------------------------------

const listFile = path.join(work, 'concat.txt');
await fsp.writeFile(listFile, parts.map((p) => `file '${p.file.replace(/'/g, "'\\''")}'`).join('\n') + '\n');
const chapters = [];
let t = 0;
for (const p of parts) {
  const d = (await probe(p.file)).duration;
  const lastCh = chapters.at(-1);
  if (lastCh && lastCh.title === p.chapter) lastCh.end = t + d;
  else chapters.push({ title: p.chapter, start: t, end: t + d });
  t += d;
}
const meta = [';FFMETADATA1', `title=Brickfolk review · ${exp} · ${runId}`, `comment=${verdict}; checksum ${report.checksum}`, ''];
for (const c of chapters) {
  meta.push('[CHAPTER]', 'TIMEBASE=1/1000', `START=${Math.round(c.start * 1000)}`, `END=${Math.round(c.end * 1000)}`, `title=${c.title}`, '');
}
const metaFile = path.join(work, 'chapters.ffmeta');
await fsp.writeFile(metaFile, meta.join('\n'));
await exec(ffmpeg, [
  '-y', '-v', 'error', '-f', 'concat', '-safe', '0', '-i', listFile, '-i', metaFile,
  '-map_metadata', '1', '-c', 'copy', '-movflags', '+faststart', out,
]);
await fsp.writeFile(
  path.join(run, 'review-edl.json'),
  JSON.stringify({ output: path.relative(run, out), durationSec: t, chapters, segments: edl, generatedBy: 'test/e2e/review_video.mjs' }, null, 2),
);
log(`wrote ${out} (${t.toFixed(1)}s, ${chapters.length} chapters: ${chapters.map((c) => c.title).join(' › ')})`);
