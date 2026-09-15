#!/usr/bin/env node
// Brickfolk cross-platform multiplayer test.
//
// Starts the authoritative server in deterministic test mode, launches four
// real clients (web via Playwright, iOS via simctl, Android via adb, macOS as
// a native app), waits for all of them to join the same party, play a full
// match on autopilot and report results, then asserts the final state,
// leaderboard and checksum are identical on every platform. Screenshots of the
// lobby, gameplay and results on each platform plus a four-way recording are
// written to the evidence directory.
//
// When both web and macOS take part, a visual tour follows the match: the
// same player is signed in on each in turn, shown the same hub screens, and
// the captures are compared pixel-by-pixel after documented normalisation
// (web is the reference).
//
// Usage: node run.mjs [--platforms web,ios,android,macos] [--no-build]
//                     [--experience obby] [--seed 1234] [--party BRIK]
//                     [--out <dir>] [--timeout 300] [--no-visual]
//                     [--match-length-scale 2.5] [--visual-only] [--no-review]

import { spawn, execFile, execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { promisify } from 'node:util';
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import http from 'node:http';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const execFileP = promisify(execFile);
const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..', '..');
const appDir = path.join(root, 'app');
const serverDir = path.join(root, 'server');

// ---------------------------------------------------------------------------
// Arguments
// ---------------------------------------------------------------------------

const args = parseArgs(process.argv.slice(2));
const platforms = (args.platforms ?? 'web,ios,android,macos').split(',').filter(Boolean);
const build = !args['no-build'];
const experience = args.experience ?? 'obby';
const seed = Number(args.seed ?? 1234);
const partyCode = (args.party ?? 'BRIK').toUpperCase();
const serverPort = Number(args['server-port'] ?? 8080);
const webPort = Number(args['web-port'] ?? 8090);
const timeoutSec = Number(args.timeout ?? (platforms.includes('android') ? 900 : 360));
const bots = Number(args.bots ?? Math.max(0, 4 - platforms.length));
const visualOnly = Boolean(args['visual-only']);
const visual =
  visualOnly || (!args['no-visual'] && platforms.includes('web') && platforms.includes('macos'));
// A software-emulated Android client renders a few frames per second, so its
// autopilot needs more wall-clock time to finish the same course.
const matchLengthScale = Number(
  args['match-length-scale'] ?? (platforms.includes('android') ? 2.5 : 1),
);
const stamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
const outDir = path.resolve(
  args.out ??
    path.join(root, '.devin', 'clone-this', 'brickfolk', 'evidence', 'tests', `multiplayer-${stamp}`),
);
const androidHome =
  process.env.ANDROID_HOME ??
  process.env.ANDROID_SDK_ROOT ??
  '/opt/homebrew/share/android-commandlinetools';
const adb = path.join(androidHome, 'platform-tools', 'adb');
const emulatorBin = process.env.BRICKFOLK_EMULATOR ?? path.join(androidHome, 'emulator', 'emulator');
const avdName = process.env.BRICKFOLK_AVD ?? 'brickfolk';
const emulatorExtraArgs = (process.env.BRICKFOLK_EMULATOR_ARGS ?? '').split(/\s+/).filter(Boolean);
// Without hardware virtualization the emulator cannot paint 60 fps, so the
// Android client is built with a frame cap that leaves CPU for the network.
const androidFrameMs = Number(
  process.env.BRICKFOLK_ANDROID_FRAME_MS ?? (emulatorExtraArgs.includes('-accel') ? 250 : 0),
);
// How Android screenshots are timed. Both grab the emulator's display from
// the host. `display` grabs when the client reports a state rendered. A
// software emulator's display trails the app by tens of seconds to minutes,
// so `marker` instead watches the display continuously and keeps the first
// frame whose phase marker (a colour block the client paints at its left edge
// in this mode, see PhaseMarker) names the wanted state; the lobby is held
// open (client auto-ready off, `test.control ready` after the capture) and
// the room's results phase stretched so the display has time to catch up.
const androidCapture = process.env.BRICKFOLK_ANDROID_CAPTURE ?? (androidFrameMs > 0 ? 'marker' : 'display');
if (!['display', 'marker'].includes(androidCapture)) {
  throw new Error(`BRICKFOLK_ANDROID_CAPTURE must be display or marker, got ${androidCapture}`);
}
const markerResultsMs = 240_000;
const markerPollMs = 3000;
const markerWaitMs = 300_000;
// PhaseMarker.colors in the app, RGB.
const markerColors = {
  hub: [0xf0, 0xc8, 0x00],
  lobby: [0x00, 0x50, 0xff],
  countdown: [0x00, 0xc8, 0xff],
  gameplay: [0x00, 0xdc, 0x28],
  results: [0xe6, 0x00, 0xe6],
};
const iosBundleId = 'dev.brickfolk.brickfolkApp';
const androidPackage = 'dev.brickfolk.brickfolk_app';

const names = { web: 'WebWren', ios: 'IosIvy', android: 'DroidDax', macos: 'MacMia' };
const hostPlatform = platforms[0];

fs.mkdirSync(outDir, { recursive: true });
const logFile = fs.createWriteStream(path.join(outDir, 'harness.log'), { flags: 'a' });
const started = Date.now();

function log(msg) {
  const line = `[${((Date.now() - started) / 1000).toFixed(1).padStart(6)}s] ${msg}`;
  console.log(line);
  logFile.write(line + '\n');
}

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith('--')) continue;
    const key = a.slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith('--')) {
      out[key] = true;
    } else {
      out[key] = next;
      i++;
    }
  }
  return out;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function waitFor(desc, fn, { timeoutMs = 60_000, intervalMs = 500 } = {}) {
  const until = Date.now() + timeoutMs;
  let last;
  while (Date.now() < until) {
    try {
      const v = await fn();
      if (v) return v;
    } catch (e) {
      last = e;
    }
    await sleep(intervalMs);
  }
  throw new Error(`Timed out waiting for ${desc}${last ? `: ${last.message}` : ''}`);
}

function run(cmd, cmdArgs, opts = {}) {
  return execFileP(cmd, cmdArgs, { maxBuffer: 64 * 1024 * 1024, ...opts });
}

function spawnLogged(name, cmd, cmdArgs, opts = {}) {
  const out = fs.createWriteStream(path.join(outDir, `${name}.log`), { flags: 'a' });
  const child = spawn(cmd, cmdArgs, { stdio: ['ignore', 'pipe', 'pipe'], ...opts });
  child.stdout.pipe(out);
  child.stderr.pipe(out);
  child.on('exit', (code, sig) => log(`${name} exited (code=${code} signal=${sig})`));
  return child;
}

async function portFree(port) {
  // A bind probe is not enough: sockets with SO_REUSEADDR (Node, Dart) can
  // bind 127.0.0.1 next to a stale 0.0.0.0 listener, so also probe over HTTP.
  const bound = await new Promise((resolve) => {
    const s = net.createServer();
    s.once('error', () => resolve(false));
    s.once('listening', () => s.close(() => resolve(true)));
    s.listen(port, '127.0.0.1');
  });
  if (!bound) return false;
  try {
    await fetch(`http://127.0.0.1:${port}/health`, { signal: AbortSignal.timeout(1500) });
    return false;
  } catch {
    return true;
  }
}

async function fetchJson(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${url} -> ${res.status}`);
  return res.json();
}

async function postJson(url, body) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`${url} -> ${res.status}`);
  return res.json();
}

const testState = () => fetchJson(`http://127.0.0.1:${serverPort}/test/state`);

function findFfmpeg() {
  return ['/opt/homebrew/bin/ffmpeg', 'ffmpeg'].find((f) => {
    try {
      execFileSync('which', [f], { stdio: 'ignore' });
      return true;
    } catch {
      return false;
    }
  });
}

// ---------------------------------------------------------------------------
// Cleanup registry
// ---------------------------------------------------------------------------

const cleanups = [];
function onCleanup(fn) {
  cleanups.push(fn);
}
async function cleanup() {
  while (cleanups.length) {
    const fn = cleanups.pop();
    try {
      await fn();
    } catch (e) {
      log(`cleanup error: ${e.message}`);
    }
  }
}

// ---------------------------------------------------------------------------
// Server
// ---------------------------------------------------------------------------

async function startServer() {
  // `dart run` forks the VM that actually serves; an interrupted run can leave
  // it listening, so stop any orphaned Brickfolk server first.
  await run('pkill', ['-f', 'bin/server.dart --port']).catch(() => {});
  await waitFor('server port', () => portFree(serverPort), { timeoutMs: 10_000 }).catch(() => {
    throw new Error(`Port ${serverPort} is busy; stop the other server or pass --server-port.`);
  });
  const db = path.join(outDir, 'brickfolk-test.db');
  const child = spawnLogged('server', 'dart', [
    'run',
    'bin/server.dart',
    '--port',
    String(serverPort),
    '--test-mode',
    '--seed',
    String(seed),
    '--db',
    db,
    '--match-length-scale',
    String(matchLengthScale),
    ...(platforms.includes('android') && androidCapture === 'marker'
      ? ['--results-ms', String(markerResultsMs)]
      : []),
  ], { cwd: serverDir, detached: true });
  onCleanup(() => {
    try {
      process.kill(-child.pid, 'SIGTERM');
    } catch {
      child.kill('SIGTERM');
    }
  });
  await waitFor(
    'server health',
    async () => (await fetch(`http://127.0.0.1:${serverPort}/health`)).ok,
    { timeoutMs: 90_000 },
  );
  log(`server ready on :${serverPort} (seed ${seed}, db ${path.basename(db)})`);
}

// ---------------------------------------------------------------------------
// Builds
// ---------------------------------------------------------------------------

// Test configuration for a native client. iOS and Android only see it as
// compile-time --dart-define values (Dart's Platform.environment is empty on
// iOS, and the emulator has no launch environment), so with --no-build those
// two must come from an earlier harness build with the same options. macOS
// additionally reads the same keys from the process environment at launch, so
// a plain `flutter build macos` works with --no-build.
function clientConfig(platform) {
  const server =
    platform === 'android'
      ? `ws://10.0.2.2:${serverPort}/ws`
      : `ws://localhost:${serverPort}/ws`;
  return {
    BRICKFOLK_SERVER: server,
    BRICKFOLK_TEST: 'true',
    BRICKFOLK_NAME: names[platform],
    BRICKFOLK_PARTY: partyCode,
    BRICKFOLK_HOST: String(platform === hostPlatform),
    BRICKFOLK_PLAYERS: String(platforms.length),
    BRICKFOLK_BOTS: String(bots),
    BRICKFOLK_EXPERIENCE: experience,
    BRICKFOLK_THEME: 'light',
    ...(platform === 'android' && androidFrameMs > 0
      ? { BRICKFOLK_FRAME_INTERVAL_MS: String(androidFrameMs) }
      : {}),
    ...(platform === 'android' && androidCapture === 'marker'
      ? { BRICKFOLK_PHASE_MARKER: 'true', BRICKFOLK_AUTO_READY: 'false' }
      : {}),
  };
}

function defines(platform) {
  return Object.entries(clientConfig(platform)).flatMap(([k, v]) => ['--dart-define', `${k}=${v}`]);
}

async function flutterBuild(platform) {
  const targets = {
    web: ['build', 'web', '--release'],
    ios: ['build', 'ios', '--simulator', '--debug', ...defines('ios')],
    android: ['build', 'apk', '--release', ...defines('android')],
    macos: ['build', 'macos', '--debug', ...defines('macos')],
  };
  log(`flutter ${targets[platform].join(' ')}`);
  const t0 = Date.now();
  const { stdout, stderr } = await run('flutter', targets[platform], { cwd: appDir });
  await fsp.writeFile(path.join(outDir, `build-${platform}.log`), stdout + stderr);
  log(`built ${platform} in ${((Date.now() - t0) / 1000).toFixed(0)}s`);
}

function findMacApp() {
  const products = path.join(appDir, 'build', 'macos', 'Build', 'Products');
  for (const cfg of ['Debug', 'Release']) {
    const dir = path.join(products, cfg);
    if (!fs.existsSync(dir)) continue;
    const app = fs.readdirSync(dir).find((f) => f.endsWith('.app'));
    if (app) return path.join(dir, app);
  }
  throw new Error('macOS .app not found; run flutter build macos');
}

function findIosApp() {
  const dir = path.join(appDir, 'build', 'ios', 'iphonesimulator');
  const app = fs.existsSync(dir) && fs.readdirSync(dir).find((f) => f.endsWith('.app'));
  if (!app) throw new Error('iOS simulator .app not found; run flutter build ios --simulator');
  return path.join(dir, app);
}

function findApk() {
  const apk = path.join(appDir, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
  if (!fs.existsSync(apk)) throw new Error('APK not found; run flutter build apk --release');
  return apk;
}

// ---------------------------------------------------------------------------
// macOS window helpers (CoreGraphics via JXA, no extra dependencies)
// ---------------------------------------------------------------------------

const windowScript = `
ObjC.import('CoreGraphics');
ObjC.import('Foundation');
function run(argv) {
  const owner = argv[0];
  const list = $.CGWindowListCopyWindowInfo(
    $.kCGWindowListOptionOnScreenOnly | $.kCGWindowListExcludeDesktopElements,
    $.kCGNullWindowID);
  const arr = ObjC.castRefToObject(list);
  const out = [];
  for (let i = 0; i < arr.count; i++) {
    const w = arr.objectAtIndex(i);
    const name = ObjC.unwrap(w.objectForKey('kCGWindowOwnerName'));
    const layer = ObjC.unwrap(w.objectForKey('kCGWindowLayer'));
    if (name !== owner || layer !== 0) continue;
    const b = w.objectForKey('kCGWindowBounds');
    out.push({
      id: ObjC.unwrap(w.objectForKey('kCGWindowNumber')),
      x: ObjC.unwrap(b.objectForKey('X')), y: ObjC.unwrap(b.objectForKey('Y')),
      w: ObjC.unwrap(b.objectForKey('Width')), h: ObjC.unwrap(b.objectForKey('Height')),
      title: ObjC.unwrap(w.objectForKey('kCGWindowName')) || '',
    });
  }
  return JSON.stringify(out);
}`;
const windowScriptPath = path.join(os.tmpdir(), 'brickfolk-windows.js');
fs.writeFileSync(windowScriptPath, windowScript);

async function windowsOf(ownerName) {
  const { stdout } = await run('osascript', ['-l', 'JavaScript', windowScriptPath, ownerName]);
  return JSON.parse(stdout.trim() || '[]').filter((w) => w.w > 100 && w.h > 100);
}

async function captureWindow(windowId, file) {
  await run('screencapture', ['-x', '-o', `-l${windowId}`, file]);
}

// Device pixels per point of the main display (window bounds are in points).
async function displayScale() {
  const { stdout } = await run('osascript', [
    '-l',
    'JavaScript',
    '-e',
    "ObjC.import('AppKit'); String($.NSScreen.mainScreen.backingScaleFactor)",
  ]).catch(() => ({ stdout: '1' }));
  const s = Number(stdout.trim());
  return Number.isFinite(s) && s > 0 ? s : 1;
}

// ---------------------------------------------------------------------------
// Clients
// ---------------------------------------------------------------------------

let browserPromise;
function getBrowser() {
  browserPromise ??= chromium.launch({ headless: false }).then((b) => {
    onCleanup(() => b.close());
    return b;
  });
  return browserPromise;
}

const webViewport = { width: 1180, height: 760 };
// The native window is pinned to the web viewport so captures line up.
const macWindowEnv = { BRICKFOLK_WINDOW: `${webViewport.width}x${webViewport.height}` };

async function serveWebBuild() {
  const webRoot = path.join(appDir, 'build', 'web');
  if (!fs.existsSync(path.join(webRoot, 'index.html'))) {
    throw new Error('build/web missing; run flutter build web');
  }
  const mime = {
    '.html': 'text/html',
    '.js': 'application/javascript',
    '.mjs': 'application/javascript',
    '.json': 'application/json',
    '.wasm': 'application/wasm',
    '.css': 'text/css',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.ttf': 'font/ttf',
    '.otf': 'font/otf',
    '.woff2': 'font/woff2',
  };
  const server = http.createServer((req, res) => {
    const url = new URL(req.url, 'http://localhost');
    let file = path.join(webRoot, decodeURIComponent(url.pathname));
    if (!file.startsWith(webRoot)) {
      res.writeHead(403).end();
      return;
    }
    if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) file = path.join(webRoot, 'index.html');
    res.writeHead(200, {
      'content-type': mime[path.extname(file)] ?? 'application/octet-stream',
      'cache-control': 'no-store',
    });
    fs.createReadStream(file).pipe(res);
  });
  await new Promise((r) => server.listen(webPort, '127.0.0.1', r));
  onCleanup(() => new Promise((r) => server.close(() => r())));
}

async function startWeb() {
  await serveWebBuild();
  const browser = await getBrowser();
  const videoDir = path.join(outDir, 'video-web');
  const recordingStartedAt = Date.now();
  const context = await browser.newContext({
    viewport: webViewport,
    recordVideo: { dir: videoDir, size: webViewport },
  });
  const page = await context.newPage();
  const consoleLog = fs.createWriteStream(path.join(outDir, 'web-console.log'), { flags: 'a' });
  page.on('console', (m) => consoleLog.write(`[${m.type()}] ${m.text()}\n`));
  page.on('pageerror', (e) => consoleLog.write(`[pageerror] ${e.message}\n`));
  const q = new URLSearchParams({
    test: '1',
    name: names.web,
    party: partyCode,
    host: hostPlatform === 'web' ? '1' : '0',
    players: String(platforms.length),
    bots: String(bots),
    experience,
    server: `ws://localhost:${serverPort}/ws`,
    theme: 'light',
  });
  await page.goto(`http://127.0.0.1:${webPort}/?${q}`);
  log(`web client opened http://127.0.0.1:${webPort}/?${q}`);
  return {
    name: 'web',
    recordingStartedAt,
    screenshot: (file) => page.screenshot({ path: file }),
    stopRecording: async () => {
      const video = page.video();
      await context.close();
      if (!video) return null;
      const target = path.join(outDir, 'recording-web.webm');
      await video.saveAs(target);
      return target;
    },
    stop: () => context.close().catch(() => {}),
  };
}

async function startIos() {
  const app = findIosApp();
  const { stdout } = await run('xcrun', ['simctl', 'list', 'devices', 'booted', '-j']);
  const devices = Object.values(JSON.parse(stdout).devices).flat();
  let udid = devices.find((d) => d.state === 'Booted')?.udid;
  if (!udid) {
    log('no booted simulator; booting the first available iPhone');
    const all = JSON.parse(
      (await run('xcrun', ['simctl', 'list', 'devices', 'available', '-j'])).stdout,
    );
    const phone = Object.values(all.devices).flat().find((d) => /iPhone/.test(d.name));
    if (!phone) throw new Error('No iPhone simulator available');
    await run('xcrun', ['simctl', 'boot', phone.udid]);
    udid = phone.udid;
  }
  await run('open', ['-a', 'Simulator']);
  await waitFor(
    'simulator boot',
    async () => /Finished|already booted/.test((await run('xcrun', ['simctl', 'bootstatus', udid])).stdout),
    { timeoutMs: 120_000, intervalMs: 2000 },
  );
  await run('xcrun', ['simctl', 'terminate', udid, iosBundleId]).catch(() => {});
  await run('xcrun', ['simctl', 'install', udid, app]);
  await run('xcrun', ['simctl', 'launch', udid, iosBundleId]);
  log(`ios app launched on ${udid}`);
  const videoFile = path.join(outDir, 'recording-ios.mp4');
  // A recorder left behind by an aborted run blocks the simulator's next one.
  await run('pkill', ['-INT', '-f', `simctl io ${udid} recordVideo`]).catch(() => {});
  let rec;
  let recordingStartedAt = null;
  // Resolves true once simctl confirms the recording, false if it exits first
  // (typically code 16, "Host recording is already in progress", which a
  // recorder killed without SIGINT leaves behind inside Simulator.app).
  const spawnRecorder = () =>
    new Promise((resolve) => {
      rec = spawnLogged('ios-record', 'xcrun', [
        'simctl', 'io', udid, 'recordVideo', '--codec=h264', '--force', videoFile,
      ]);
      rec.stderr.on('data', (chunk) => {
        if (!String(chunk).includes('Recording started')) return;
        recordingStartedAt = Date.now();
        resolve(true);
      });
      rec.once('exit', () => resolve(false));
    });
  return {
    name: 'ios',
    get recordingStartedAt() {
      return recordingStartedAt;
    },
    screenshot: (file) => run('xcrun', ['simctl', 'io', udid, 'screenshot', file]),
    startRecording: async () => {
      for (let attempt = 0; attempt < 2; attempt += 1) {
        if (await spawnRecorder()) {
          onCleanup(() => rec.kill('SIGINT'));
          return;
        }
        rec = null;
        if (attempt > 0) break;
        // Only Simulator.app holds the stale host recording; the device (and
        // the app under test) stay booted across its restart.
        log('ios recorder refused to start; restarting Simulator.app to clear a stale host recording');
        await run('osascript', ['-e', 'quit app "Simulator"']).catch(() => {});
        await sleep(3000);
        await run('open', ['-a', 'Simulator']);
        await waitFor(
          'simulator after restart',
          async () => /Finished|already booted/.test((await run('xcrun', ['simctl', 'bootstatus', udid])).stdout),
          { timeoutMs: 60_000, intervalMs: 2000 },
        );
        await sleep(2000);
      }
      throw new Error('ios screen recording could not start (see ios-record.log)');
    },
    stopRecording: async () => {
      if (!rec) return null;
      rec.kill('SIGINT');
      await new Promise((r) => (rec.exitCode === null ? rec.once('exit', r) : r()));
      return fs.existsSync(videoFile) && fs.statSync(videoFile).size > 0 ? videoFile : null;
    },
    stop: () => run('xcrun', ['simctl', 'terminate', udid, iosBundleId]).catch(() => {}),
  };
}

// The software emulator's adbd falls over when shell commands overlap, so every
// adb call after boot goes through one queue with a hard per-command timeout.
let adbChain = Promise.resolve();
let adbPending = 0;
function adbRun(adbArgs, opts = {}) {
  adbPending += 1;
  const next = adbChain
    .then(() => run(adb, adbArgs, { timeout: 90_000, killSignal: 'SIGKILL', ...opts }))
    .finally(() => (adbPending -= 1));
  adbChain = next.catch(() => {});
  return next;
}

async function adbDeviceOnline() {
  const { stdout } = await run(adb, ['devices']);
  return stdout.split('\n').some((l) => /\tdevice$/.test(l.trim()));
}

async function ensureEmulator() {
  if (await adbDeviceOnline()) return;
  if (!fs.existsSync(emulatorBin)) {
    throw new Error(`no Android device online and emulator binary missing: ${emulatorBin}`);
  }
  log(`starting emulator ${avdName} (${emulatorBin} ${emulatorExtraArgs.join(' ')})`);
  const child = spawnLogged('emulator', emulatorBin, [
    '-avd',
    avdName,
    '-no-snapshot',
    '-no-boot-anim',
    '-no-audio',
    '-gpu',
    'swiftshader_indirect',
    ...emulatorExtraArgs,
  ]);
  child.unref();
  await waitFor('android device', adbDeviceOnline, { timeoutMs: 300_000, intervalMs: 3000 });
}

// Installs are slow on software-emulated devices, so the APK is pushed once
// and re-installed only when its content hash changes.
async function installApk(apk) {
  const remote = '/data/local/tmp/brickfolk.apk';
  const digest = createHash('sha256').update(await fsp.readFile(apk)).digest('hex');
  const installed = await run(adb, ['shell', `cat ${remote}.sha256 2>/dev/null`])
    .then((r) => r.stdout.trim())
    .catch(() => '');
  const present = await run(adb, ['shell', 'pm', 'list', 'packages', androidPackage])
    .then((r) => r.stdout.includes(androidPackage))
    .catch(() => false);
  if (installed === digest && present) {
    log('android apk already installed (hash match)');
    return;
  }
  const t0 = Date.now();
  await run(adb, ['push', apk, remote]);
  const { stdout } = await run(adb, ['shell', 'pm', 'install', '-r', '-t', remote]);
  if (!/Success/.test(stdout)) throw new Error(`pm install failed: ${stdout.trim()}`);
  await run(adb, ['shell', `echo ${digest} > ${remote}.sha256`]);
  log(`android apk installed in ${((Date.now() - t0) / 1000).toFixed(0)}s`);
}

// sys.boot_completed stays set while the framework soft-restarts, so also
// require the package manager to answer before touching the device.
async function waitForAndroidBoot() {
  await waitFor(
    'android boot_completed',
    async () => {
      const boot = await run(adb, ['shell', 'getprop', 'sys.boot_completed']);
      if (boot.stdout.trim() !== '1') return false;
      const pm = await run(adb, ['shell', 'pm', 'path', 'android'], {
        timeout: 60_000,
        killSignal: 'SIGKILL',
      }).catch(() => ({ stdout: '' }));
      return /^package:/m.test(pm.stdout);
    },
    // A cold boot of the software-emulated system image takes ~15 minutes.
    { timeoutMs: 1_200_000, intervalMs: 5000 },
  );
}

// Android keeps its default routes in per-network tables, so ask the kernel
// for a route to the host (10.0.2.2 from inside the emulator) instead of
// reading the main table.
const androidHasRoute = () =>
  run(adb, ['shell', 'ip', 'route', 'get', '10.0.2.2'])
    .then((r) => /\bdev wlan0\b|\bdev eth0\b/.test(r.stdout))
    .catch(() => false);

// The app reaches the host through the guest's Wi-Fi route, which comes up
// some time after boot_completed. When the framework is starved long enough
// for its netd calls to time out, the Wi-Fi state machine drops the interface
// for good; `adb reboot` leaves this emulator with an unresponsive adbd, so
// the recovery is a fresh emulator process.
async function ensureAndroidNetwork() {
  const routeUp = () =>
    waitFor('android route to host', androidHasRoute, {
      timeoutMs: 360_000,
      intervalMs: 5000,
    });
  try {
    await routeUp();
    return;
  } catch (e) {
    log(`android guest cannot reach the host (${e.message}); restarting the emulator`);
  }
  await run(adb, ['emu', 'kill']).catch(() => {});
  await waitFor('emulator gone', async () => !(await adbDeviceOnline()), {
    timeoutMs: 60_000,
    intervalMs: 2000,
  }).catch(() => {});
  await ensureEmulator();
  await waitForAndroidBoot();
  await routeUp();
}

async function startAndroid() {
  const apk = findApk();
  await ensureEmulator();
  await waitForAndroidBoot();
  await ensureAndroidNetwork();
  // hide_error_dialogs is read at boot, so it protects the next boot of this
  // AVD; a dialog already showing (typically raised while the software
  // emulator booted) is tapped away below. No configuration change is forced
  // here: on this device a density round-trip makes System UI re-inflate for
  // minutes and starves the app.
  await run(adb, [
    'shell',
    'settings put global hide_error_dialogs 1; ' +
      'settings put global window_animation_scale 0; ' +
      'settings put global transition_animation_scale 0; ' +
      'settings put global animator_duration_scale 0',
  ]).catch(() => {});
  await dismissAnrDialog().catch(() => {});
  await installApk(apk);
  // Let System UI / launcher restarts triggered by the boot finish before
  // the app competes with them for the single emulated core.
  await waitFor(
    'android load settled',
    async () => {
      const { stdout } = await run(adb, ['shell', 'cat', '/proc/loadavg']);
      const load = Number(stdout.trim().split(/\s+/)[0]);
      log(`android loadavg ${load}`);
      return load < androidSettledLoad;
    },
    { timeoutMs: 240_000, intervalMs: 10_000 },
  ).catch((e) => log(`android did not settle: ${e.message}`));
  await run(adb, ['shell', 'am', 'force-stop', androidPackage]).catch(() => {});
  await run(adb, ['shell', 'am', 'start', '-n', `${androidPackage}/.MainActivity`]);
  log('android app launched');
  const capture = await EmulatorCapture.open(path.join(outDir, 'segments-android'));
  const grabFrame = async (file) => {
    if (capture) return capture.screenshot(file);
    const { stdout } = await adbRun(['exec-out', 'screencap', '-p'], { encoding: 'buffer' });
    if (stdout.length < 100) throw new Error('empty screencap');
    await fsp.writeFile(file, stdout);
  };
  // Evidence must show the app, never a system dialog. The frame is grabbed
  // at once (the emulated display only holds a state for a few seconds
  // before its next, much later frame lands), then the window list decides
  // whether it counts: the dialog persists until tapped, so if it is on
  // screen after the frame it was on screen during it. A dismissal that was
  // already in flight while the frame was grabbed disqualifies it too.
  let anrBusy = Promise.resolve();
  let capturing = 0;
  const screencap = async (file) => {
    capturing += 1;
    try {
      for (let attempt = 1; attempt <= anrScreenshotAttempts; attempt++) {
        const dismissed = anrDismissals;
        await grabFrame(file);
        await anrBusy;
        const dialog = await findAnrDialog().catch((e) => e);
        if (dialog === null && anrDismissals === dismissed) return;
        log(
          dialog instanceof Error
            ? `android window list unavailable after ${path.basename(file)} (${dialog.message.split('\n')[0]}); retaking`
            : `android ANR dialog on screen while ${path.basename(file)} was taken; retaking`,
        );
        await fsp.rm(file, { force: true });
        if (dialog && !(dialog instanceof Error)) await dismissAnrDialog().catch(() => {});
        await sleep(2500);
      }
      throw new Error(`could not capture ${path.basename(file)} without an ANR dialog on screen`);
    } finally {
      capturing -= 1;
    }
  };
  // A software-emulated system process can trip its own ANR watchdog; the
  // resulting dialog steals focus from the app until "Wait" is tapped. The
  // check is skipped while other adb work is queued so it never piles up.
  let anrInFlight = false;
  const anrLoop = setInterval(() => {
    if (anrInFlight || capturing > 0 || adbPending > 0) return;
    anrInFlight = true;
    anrBusy = dismissAnrDialog()
      .catch(() => {})
      .finally(() => (anrInFlight = false));
  }, anrPollMs);
  onCleanup(() => clearInterval(anrLoop));
  // `marker` mode: one loop grabs the display every markerPollMs and reads
  // the phase marker. The first dialog-free frame of each phase is kept (a
  // phase can reach the display before the harness asks for it) and handed
  // to whoever asks for that phase. The display shows the phases in order,
  // but it can still be showing a previous app instance when the run starts,
  // so a frame only counts once the server has seen this client reach that
  // phase and the phase follows the last accepted one.
  const markerDir = path.join(outDir, 'segments-android');
  const markerOrder = ['hub', 'lobby', 'countdown', 'gameplay', 'results'];
  const markerReached = new Set(['hub', 'countdown']);
  const markerSeen = new Map(); // phase -> kept frame
  const markerWaiters = new Map(); // phase -> [{ resolve, reject }]
  const markerTimes = {}; // phase -> seconds since harness start
  let markerLast = null;
  let markerIndex = -1;
  let markerBusy = false;
  const markerLoop =
    androidCapture !== 'marker'
      ? null
      : setInterval(async () => {
          if (markerBusy) return;
          markerBusy = true;
          try {
            if (capture && !capture.current) return; // recording starts at sign-in
            await fsp.mkdir(markerDir, { recursive: true });
            const tmp = path.join(markerDir, 'marker-probe.png');
            const dismissed = anrDismissals;
            await (capture ? capture.probe(tmp) : grabFrame(tmp));
            const phase = await readPhaseMarker(tmp);
            if (phase !== markerLast) {
              log(`android display shows ${phase ?? 'no phase marker'}`);
              markerLast = phase;
            }
            if (!phase || markerSeen.has(phase)) return;
            if (!markerReached.has(phase) || markerOrder.indexOf(phase) <= markerIndex) {
              if (markerLast === phase && !markerSeen.has(`stale:${phase}`)) {
                markerSeen.set(`stale:${phase}`, true);
                log(`android display ${phase} ignored (not reached yet or out of order)`);
              }
              return;
            }
            await anrBusy;
            const dialog = await findAnrDialog().catch((e) => e);
            if (dialog !== null || anrDismissals !== dismissed) {
              log(`android ${phase} frame had an ANR dialog on screen; waiting for the next`);
              if (dialog && !(dialog instanceof Error)) await dismissAnrDialog().catch(() => {});
              return;
            }
            const kept = path.join(markerDir, `marker-${phase}.png`);
            await fsp.rename(tmp, kept);
            markerSeen.set(phase, kept);
            markerIndex = markerOrder.indexOf(phase);
            markerTimes[phase] = Number(((Date.now() - started) / 1000).toFixed(1));
            for (const w of markerWaiters.get(phase) ?? []) w.resolve(kept);
            markerWaiters.delete(phase);
          } catch (e) {
            log(`android marker probe: ${e.message.split('\n')[0]}`);
          } finally {
            markerBusy = false;
          }
        }, markerPollMs);
  if (markerLoop) onCleanup(() => clearInterval(markerLoop));
  const markerShot = async (file, phase) => {
    const kept =
      markerSeen.get(phase) ??
      (await new Promise((resolve, reject) => {
        const list = markerWaiters.get(phase) ?? [];
        const timer = setTimeout(() => {
          markerWaiters.set(phase, (markerWaiters.get(phase) ?? []).filter((w) => w.resolve !== ok));
          reject(new Error(`android display did not show the ${phase} marker within ${markerWaitMs / 1000}s`));
        }, markerWaitMs);
        const ok = (f) => {
          clearTimeout(timer);
          resolve(f);
        };
        list.push({ resolve: ok, reject });
        markerWaiters.set(phase, list);
      }));
    await fsp.copyFile(kept, file);
  };
  return {
    name: 'android',
    screenshot: androidCapture === 'marker' ? markerShot : screencap,
    captureMode: androidCapture,
    markerTimes,
    notePhase: (phase) => markerReached.add(phase),
    get recordingStartedAt() {
      return capture?.segments[0]?.t ?? capture?.current?.t ?? null;
    },
    // The lobby is held open until its display frame is in hand.
    afterScreenshot: async (phase) => {
      if (androidCapture !== 'marker' || phase !== 'lobby') return;
      await postJson(`http://127.0.0.1:${serverPort}/test/control`, { cmd: 'ready', platform: 'android' });
      log('android readied after its lobby capture');
    },
    startRecording: () => capture?.start(),
    stopRecording: async () => {
      if (!capture) return null;
      const target = path.join(outDir, 'recording-android.mp4');
      return capture.stop(target);
    },
    stop: () => {
      clearInterval(anrLoop);
      if (markerLoop) clearInterval(markerLoop);
      capture?.close();
      return adbRun(['shell', 'am', 'force-stop', androidPackage]).catch(() => {});
    },
  };
}

// Names the phase marker (PhaseMarker in the app) painted in [file]: the
// left-edge strip around mid-height is read as raw RGB and the marker colour
// with the most near-exact pixels wins, if enough of them are present.
async function readPhaseMarker(file) {
  const ffmpeg = findFfmpeg();
  if (!ffmpeg) throw new Error('ffmpeg is required to read the phase marker');
  const { stdout } = await run(
    ffmpeg,
    ['-v', 'error', '-i', file, '-vf', 'crop=12:ih*0.4:0:ih*0.3', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'],
    { encoding: 'buffer', maxBuffer: 64 * 1024 * 1024 },
  );
  const counts = Object.fromEntries(Object.keys(markerColors).map((k) => [k, 0]));
  for (let i = 0; i + 2 < stdout.length; i += 3) {
    for (const [phase, [r, g, b]] of Object.entries(markerColors)) {
      if (Math.abs(stdout[i] - r) <= 40 && Math.abs(stdout[i + 1] - g) <= 40 && Math.abs(stdout[i + 2] - b) <= 40) {
        counts[phase] += 1;
        break;
      }
    }
  }
  const [phase, n] = Object.entries(counts).sort((a, b) => b[1] - a[1])[0];
  return n >= 120 ? phase : null;
}

// Records the emulator display from the host side through the emulator
// console, so capturing costs the emulated device nothing. (In-guest
// `screenrecord` needs a hardware encoder and `screencap` stalls a software
// emulator for seconds per frame.) The console caps each recording at 180 s,
// so the session is a chain of segments concatenated by ffmpeg at the end; a
// screenshot closes the current segment and takes its last frame.
class EmulatorCapture {
  static async open(dir) {
    const serial = await run(adb, ['devices'])
      .then(({ stdout }) => stdout.match(/^(emulator-(\d+))\tdevice$/m))
      .catch(() => null);
    if (!serial) return null;
    const tokenFile = path.join(os.homedir(), '.emulator_console_auth_token');
    const token = fs.existsSync(tokenFile) ? fs.readFileSync(tokenFile, 'utf8').trim() : '';
    const c = new EmulatorCapture(Number(serial[2]), dir);
    try {
      // The greeting ends with its own OK before any command is answered.
      await c.command(null, 10_000);
      await c.command(`auth ${token}`, 10_000);
      await c.command('help screenrecord', 10_000);
    } catch (e) {
      log(`emulator console unavailable (${e.message}); falling back to screencap`);
      c.close();
      return null;
    }
    fs.mkdirSync(dir, { recursive: true });
    return c;
  }

  constructor(port, dir) {
    this.dir = dir;
    this.segments = [];
    this.current = null;
    this.rotate = null;
    this.buffer = '';
    this.waiters = [];
    this.socket = net.createConnection({ host: '127.0.0.1', port });
    this.socket.setEncoding('utf8');
    this.socket.on('data', (d) => this.onData(d));
    this.socket.on('error', (e) => this.fail(e));
    this.socket.on('close', () => this.fail(new Error('emulator console closed')));
    this.chain = Promise.resolve(); // console commands, strictly one at a time
    this.ops = Promise.resolve(); // segment operations (start/split/stop)
  }

  onData(chunk) {
    this.buffer += chunk;
    let m;
    while ((m = this.buffer.match(/^(OK|KO:.*)\r?\n/m))) {
      const end = m.index + m[0].length;
      const reply = this.buffer.slice(0, end);
      this.buffer = this.buffer.slice(end);
      const w = this.waiters.shift();
      if (!w) continue;
      if (m[1] === 'OK') w.resolve(reply);
      else w.reject(new Error(m[1].trim()));
    }
  }

  fail(err) {
    for (const w of this.waiters.splice(0)) w.reject(err);
  }

  // Sends one console line (or, with null, just waits for the next reply).
  command(line, timeoutMs = 15_000) {
    const next = this.chain.then(
      () =>
        new Promise((resolve, reject) => {
          const timer = setTimeout(() => {
            const i = this.waiters.indexOf(w);
            if (i >= 0) this.waiters.splice(i, 1);
            reject(new Error(`emulator console timeout: ${(line ?? 'greeting').split(' ')[0]}`));
          }, timeoutMs);
          const w = {
            resolve: (v) => (clearTimeout(timer), resolve(v)),
            reject: (e) => (clearTimeout(timer), reject(e)),
          };
          this.waiters.push(w);
          if (line !== null) this.socket.write(`${line}\n`);
        }),
    );
    this.chain = next.catch(() => {});
    return next;
  }

  locked(fn) {
    const next = this.ops.then(fn);
    this.ops = next.catch(() => {});
    return next;
  }

  start() {
    return this.locked(() => this.beginSegment());
  }

  async beginSegment() {
    if (this.current) return;
    const file = path.join(this.dir, `${String(this.segments.length).padStart(3, '0')}.webm`);
    await this.command(`screenrecord start --time-limit 180 ${file}`);
    this.current = { file, t: Date.now() };
    this.rotate = setTimeout(
      () => this.locked(() => this.endSegment(true)).catch((e) => log(`android capture rotate failed: ${e.message}`)),
      170_000,
    );
  }

  // Closes the current segment, waits for the encoder to flush it, and
  // optionally starts the next one.
  async endSegment(restart) {
    clearTimeout(this.rotate);
    const done = this.current;
    if (!done) return null;
    this.current = null;
    await this.command('screenrecord stop');
    done.end = Date.now();
    this.segments.push(done);
    if (restart) await this.beginSegment();
    await waitFor(
      'emulator segment',
      () => fs.existsSync(done.file) && fs.statSync(done.file).size > 0,
      { timeoutMs: 15_000 },
    ).catch((e) => log(`android capture: ${e.message}`));
    await sleep(500);
    return done;
  }

  // Newest frame of the segment being written, decoded from the last few
  // seconds of the file without touching the recording: for polling.
  async probe(file) {
    const cur = this.current;
    if (!cur) throw new Error('not recording');
    const ffmpeg = findFfmpeg();
    if (!ffmpeg) throw new Error('ffmpeg not found');
    // The muxer flushes clusters some seconds behind the wall clock.
    const elapsed = (Date.now() - cur.t) / 1000;
    for (const back of [20, 60]) {
      await fsp.rm(file, { force: true });
      const from = Math.max(0, elapsed - back);
      await run(ffmpeg, ['-y', '-v', 'error', '-ss', String(from), '-i', cur.file, '-update', '1', file]).catch(
        () => {},
      );
      if (fs.existsSync(file) && fs.statSync(file).size > 0) return;
    }
    throw new Error('no frame decoded yet');
  }

  screenshot(file) {
    return this.locked(async () => {
      if (!this.current) {
        await this.beginSegment();
        await sleep(1500);
      }
      const seg = await this.endSegment(true);
      const ffmpeg = findFfmpeg();
      if (!ffmpeg) throw new Error('ffmpeg not found');
      // Last frame of the segment; very short segments have no room to seek.
      for (const seek of [['-sseof', '-0.4'], []]) {
        await run(ffmpeg, ['-y', '-v', 'error', ...seek, '-i', seg.file, '-update', '1', '-frames:v', '1', file]).catch(
          () => {},
        );
        if (fs.existsSync(file) && fs.statSync(file).size > 0) return;
      }
      throw new Error(`no frame decoded from ${path.basename(seg.file)}`);
    });
  }

  stop(target) {
    return this.locked(async () => {
      await this.endSegment(false).catch(() => {});
      const files = this.segments.map((s) => s.file).filter((f) => fs.existsSync(f) && fs.statSync(f).size > 0);
      if (files.length === 0) return null;
      const ffmpeg = findFfmpeg();
      if (!ffmpeg) return null;
      const listFile = path.join(this.dir, 'segments.txt');
      await fsp.writeFile(listFile, files.map((f) => `file '${f}'`).join('\n'));
      // The console writes ~20 frames per wall second but leaves the WebM
      // frame-rate header unset, so the rate is stated rather than guessed.
      await run(ffmpeg, [
        '-y', '-v', 'error', '-r', '20', '-f', 'concat', '-safe', '0', '-i', listFile,
        '-vf', 'scale=trunc(iw/2)*2:trunc(ih/2)*2',
        '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-preset', 'veryfast', '-crf', '24', '-an',
        target,
      ]);
      log(`android recording assembled from ${files.length} host-side segment(s)`);
      return target;
    });
  }

  close() {
    clearTimeout(this.rotate);
    this.socket.destroy();
  }
}

const anrPollMs = 20_000;
const anrScreenshotAttempts = 6;
const androidSettledLoad = 1.5;
let anrDismissals = 0;

// Frame of the visible ANR dialog, or null when none is showing.
async function findAnrDialog() {
  const { stdout } = await adbRun(['shell', 'dumpsys', 'window', 'windows']);
  const m = stdout.match(
    /Window\{[^}]*Application Not Responding[^}]*\}[\s\S]*?mFrame=\[(\d+),(\d+)\]\[(\d+),(\d+)\]/,
  );
  if (!m) return null;
  const [x1, y1, x2, y2] = m.slice(1).map(Number);
  if (x2 - x1 < 100 || y2 - y1 < 100) return null;
  return { x1, y1, x2, y2 };
}

// Centre of the dialog's "Wait" item from the accessibility tree, or, when
// the dump fails on a starved device, from the dialog's frame: the dialog
// stacks its title over the "Close app" and "Wait" rows, so "Wait" sits
// about 78% of the way down the frame.
async function findWaitButton(f) {
  const dump = await adbRun(
    ['shell', 'uiautomator dump /data/local/tmp/ui.xml >/dev/null && cat /data/local/tmp/ui.xml'],
    { timeout: 60_000 },
  ).catch(() => null);
  const m = dump?.stdout.match(/text="Wait"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"/);
  if (m) {
    const [x1, y1, x2, y2] = m.slice(1).map(Number);
    return { x: Math.round((x1 + x2) / 2), y: Math.round((y1 + y2) / 2), via: 'uiautomator' };
  }
  return {
    x: Math.round((f.x1 + f.x2) / 2),
    y: Math.round(f.y1 + (f.y2 - f.y1) * 0.78),
    via: 'frame',
  };
}

async function dismissAnrDialog() {
  const f = await findAnrDialog();
  if (!f) return false;
  const { x, y, via } = await findWaitButton(f);
  await adbRun(['shell', 'input', 'tap', String(x), String(y)]);
  await sleep(1500);
  const gone = !(await findAnrDialog());
  anrDismissals += 1;
  log(`android ANR dialog: tapped Wait at ${x},${y} (${via}); ${gone ? 'dismissed' : 'still showing'}`);
  return true;
}

async function startMacos() {
  const app = findMacApp();
  const exe = path.join(app, 'Contents', 'MacOS', fs.readdirSync(path.join(app, 'Contents', 'MacOS'))[0]);
  // A leftover instance from an earlier run would hold the fixed player name.
  await run('pkill', ['-f', exe]).catch(() => {});
  await sleep(500);
  const child = spawnLogged('macos', exe, [], {
    env: { ...process.env, ...macWindowEnv, ...clientConfig('macos') },
  });
  onCleanup(() => child.kill('SIGTERM'));
  const owner = path.basename(exe);
  const win = await waitFor('macOS window', async () => (await windowsOf(owner))[0], {
    timeoutMs: 60_000,
  });
  log(`macos app window ${win.id} (${win.w}x${win.h} at ${win.x},${win.y})`);
  const videoFile = path.join(outDir, 'recording-macos.mp4');
  let rec;
  let recordingStopping = false;
  let recordingStartedAt = null;
  return {
    name: 'macos',
    get recordingStartedAt() {
      return recordingStartedAt;
    },
    screenshot: async (file) => {
      const w = (await windowsOf(owner))[0] ?? win;
      await captureWindow(w.id, file);
    },
    // The recording is a screen region grabbed by ffmpeg (AVFoundation) with
    // wall-clock timestamps, so frames dropped while the host is saturated
    // by the other clients only lower the frame rate and never shorten or
    // compress the timeline. The app is brought to the front first (the
    // Simulator window can sit over it); other clients are recorded through
    // their own APIs and do not need the focus.
    startRecording: async () => {
      await run('open', [app]).catch(() => {});
      await sleep(500);
      const s = await displayScale();
      const even = (v) => Math.floor(v / 2) * 2;
      const crop = `${even(win.w * s)}:${even(win.h * s)}:${Math.round(win.x * s)}:${Math.round(win.y * s)}`;
      const log_ = fs.openSync(path.join(outDir, 'macos-record.log'), 'a');
      recordingStartedAt = Date.now();
      rec = spawn(
        findFfmpeg(),
        [
          '-hide_banner', '-v', 'warning', '-y',
          '-f', 'avfoundation', '-framerate', '30', '-capture_cursor', '0',
          '-pixel_format', 'uyvy422', '-use_wallclock_as_timestamps', '1', '-i', '0:none',
          '-vf', `crop=${crop}`, '-fps_mode', 'vfr',
          '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '20', '-pix_fmt', 'yuv420p',
          '-movflags', '+faststart', videoFile,
        ],
        { stdio: ['pipe', log_, log_] },
      );
      rec.once('exit', (code, signal) => {
        if (recordingStopping) return;
        log(`macos recorder exited early (code=${code} signal=${signal}); see macos-record.log`);
      });
      onCleanup(() => rec.kill('SIGINT'));
    },
    stopRecording: async () => {
      if (!rec) return null;
      recordingStopping = true;
      rec.stdin.write('q');
      rec.stdin.end();
      const exited = new Promise((r) => (rec.exitCode === null ? rec.once('exit', r) : r()));
      const timer = setTimeout(() => rec.kill('SIGINT'), 10_000);
      await exited;
      clearTimeout(timer);
      return fs.existsSync(videoFile) ? videoFile : null;
    },
    stop: () => child.kill('SIGTERM'),
  };
}

const starters = { web: startWeb, ios: startIos, android: startAndroid, macos: startMacos };

// Clients left over from an earlier run would reconnect with the fixed test
// names as soon as the server comes up, so stop them before it starts.
async function stopStaleClients() {
  await run('pkill', ['-f', 'Brickfolk.app/Contents/MacOS']).catch(() => {});
  const booted = await run('xcrun', ['simctl', 'list', 'devices', 'booted', '-j'])
    .then(({ stdout }) => Object.values(JSON.parse(stdout).devices).flat())
    .catch(() => []);
  for (const d of booted) {
    await run('xcrun', ['simctl', 'terminate', d.udid, iosBundleId]).catch(() => {});
  }
  if (await adbDeviceOnline().catch(() => false)) {
    await run(adb, ['shell', 'am', 'force-stop', androidPackage]).catch(() => {});
  }
}

// ---------------------------------------------------------------------------
// Match observation
// ---------------------------------------------------------------------------

async function observeMatch(clients) {
  const byName = Object.fromEntries(clients.map((c) => [c.name, c]));
  const shot = {}; // platform -> Set(phase)
  const pending = [];
  const results = {};
  const seenPlaying = {};
  const timeline = {}; // platform -> phase -> wall-clock ms of the first report
  const deadline = Date.now() + timeoutSec * 1000;

  // Clients report a phase only once a frame showing it has been rasterised;
  // the delay lets entrance animations finish. When the Android display is
  // grabbed on a software emulator a frame takes many seconds, so the
  // reported frame is already settled and the next one may show a later
  // phase: capture it promptly.
  const take = async (platform, phase, delayMs) => {
    const key = `${platform}:${phase}`;
    if (shot[key]) return;
    shot[key] = true;
    const p = (async () => {
      const mode = byName[platform].captureMode;
      const prompt = mode === 'display' && platform === 'android';
      await sleep(mode === 'marker' ? 0 : prompt ? Math.min(delayMs, 1500) : delayMs);
      const file = path.join(outDir, `${platform}-${phase}.png`);
      try {
        await byName[platform].screenshot(file, phase);
        log(`screenshot ${path.basename(file)}`);
      } catch (e) {
        log(`screenshot ${platform} ${phase} failed: ${e.message}`);
      } finally {
        await byName[platform].afterScreenshot?.(phase).catch((e) => log(`${platform} after ${phase}: ${e.message}`));
      }
    })();
    pending.push(p);
  };

  const recording = {};
  const unrendered = new Set();
  let lastLogged = '';
  let lastProgress = 0;
  while (Date.now() < deadline) {
    const state = await fetchJson(`http://127.0.0.1:${serverPort}/test/state`);
    const reports = state.testReports ?? [];
    for (const r of reports) {
      if (!byName[r.platform]) continue;
      if (!recording[r.platform]) {
        recording[r.platform] = true;
        Promise.resolve(byName[r.platform].startRecording?.()).catch((e) =>
          log(`${r.platform} recording failed to start: ${e.message}`),
        );
        log(`${r.platform} signed in; recording started`);
      }
      if (['lobby', 'countdown', 'playing', 'results'].includes(r.phase)) {
        const phase = r.phase === 'playing' ? 'gameplay' : r.phase;
        (timeline[r.platform] ??= {})[phase] ??= Date.now();
      }
      if (r.phase !== 'frame' && r.payload?.rendered === false && !unrendered.has(`${r.platform}:${r.phase}`)) {
        unrendered.add(`${r.platform}:${r.phase}`);
        log(`${r.platform} reported ${r.phase} without a rasterised frame (raster gate timed out)`);
      }
      if (r.phase === 'lobby') {
        byName[r.platform].notePhase?.('lobby');
        take(r.platform, 'lobby', 2500);
      }
      if (r.phase === 'playing') {
        seenPlaying[r.platform] = true;
        byName[r.platform].notePhase?.('gameplay');
        take(r.platform, 'gameplay', 9000);
      }
      if (r.phase === 'results') {
        results[r.platform] = r.payload;
        byName[r.platform].notePhase?.('results');
        take(r.platform, 'results', 2500);
      }
    }
    const summary =
      `online=${state.online} parties=${state.parties.length} rooms=${state.rooms.length} ` +
      `phase=${state.rooms[0]?.phase ?? '-'} reports=${reports.length} ` +
      `results=${Object.keys(results).sort().join(',') || '-'}`;
    if (summary !== lastLogged) {
      log(summary);
      lastLogged = summary;
    }
    const room = state.rooms[0];
    if (room?.phase === 'playing' && Date.now() - lastProgress > 15_000) {
      lastProgress = Date.now();
      const names = Object.fromEntries(
        (room.members ?? []).map((m) => [m.player.id, m.player.name]),
      );
      log(
        `tick=${room.gameTick} ` +
          Object.entries(room.progress ?? {})
            .map(([id, v]) => `${names[id] ?? id}:${v}`)
            .join(' '),
      );
    }
    if (platforms.every((p) => results[p])) {
      await Promise.all(pending);
      return { results, state, timeline };
    }
    await sleep(1000);
  }
  await Promise.all(pending);
  throw new Error(
    `Match did not finish within ${timeoutSec}s; results from: ${Object.keys(results).join(',') || 'none'}`,
  );
}

function canonical(payload) {
  return JSON.stringify({
    room: payload.room,
    experience: payload.experience,
    checksum: payload.checksum,
    leaderboard: payload.leaderboard,
  });
}

// ---------------------------------------------------------------------------
// Four-way recording
// ---------------------------------------------------------------------------

// The tiles are aligned on wall-clock time: every input is trimmed to start
// at the moment the last recording began, so a given frame shows what the
// four screens displayed at the same instant (the Android display trails
// the app on a software emulator; that lag is visible here by design).
async function composeRecording(videos, startedAt) {
  const inputs = platforms.map((p) => videos[p]).filter(Boolean);
  if (inputs.length !== platforms.length) {
    log(`four-way composition skipped: ${inputs.length}/${platforms.length} recordings present`);
    return null;
  }
  const starts = platforms.map((p) => startedAt[p]);
  const aligned = starts.every((s) => typeof s === 'number');
  const latest = aligned ? Math.max(...starts) : 0;
  const trims = starts.map((s) => (aligned ? Math.max(0, (latest - s) / 1000) : 0));
  const ffmpeg = findFfmpeg();
  if (!ffmpeg) {
    log('ffmpeg not found; skipping four-way composition');
    return null;
  }
  const target = path.join(outDir, 'recording-four-way.mp4');
  const tile = 'scale=640:800:force_original_aspect_ratio=decrease,pad=640:800:(ow-iw)/2:(oh-ih)/2:color=0x13172A,setsar=1,fps=15';
  const filters = inputs.map((_, i) => `[${i}:v]${tile}[v${i}]`);
  let layout;
  if (inputs.length === 1) layout = '[v0]copy[out]';
  else if (inputs.length === 2) layout = '[v0][v1]hstack=inputs=2[out]';
  else if (inputs.length === 3) layout = '[v0][v1][v2]hstack=inputs=3[out]';
  else layout = '[v0][v1][v2][v3]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0[out]';
  const cmdArgs = [
    '-y',
    ...inputs.flatMap((f, i) => ['-ss', trims[i].toFixed(3), '-i', f]),
    '-filter_complex',
    `${filters.join(';')};${layout}`,
    '-map',
    '[out]',
    '-c:v',
    'libx264',
    '-pix_fmt',
    'yuv420p',
    '-preset',
    'veryfast',
    '-crf',
    '26',
    '-an',
    target,
  ];
  try {
    await run(ffmpeg, cmdArgs);
    log(
      `four-way recording ${path.basename(target)} (${inputs.length} sources, ` +
        `${aligned ? `aligned; trimmed ${trims.map((t) => t.toFixed(1)).join('/')} s` : 'unaligned'})`,
    );
    return target;
  } catch (e) {
    log(`ffmpeg composition failed: ${e.stderr?.slice(-600) ?? e.message}`);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Visual tour: equivalent hub states on web (reference) and macOS
// ---------------------------------------------------------------------------

const tourScreens = ['hub', 'place', 'avatar', 'social', 'chat', 'profile', 'daily'];
const tourName = 'VisualVi';
// macOS window chrome: 32px title bar above a 1180x760 content area that
// matches the web viewport; the window's rounded bottom corners are masked
// (3x3 cells of the 4x-downscaled 295x190 frame).
const macTitleBar = 32;
const visualScale = 4;
// Normalisation bounds. After the 4x box downscale the two rasterizers still
// disagree on isolated anti-aliased glyph edges by up to ~43/255 per channel
// (measured across the tour screens; identical captures differ by 0), so a
// cell is a differing pixel beyond 48/255 and the comparison requires zero of
// them. Cells between 24 and 48 are reported as edge cells and bounded too:
// at most 0.1% of the 295x190 frame and no connected run of more than 8 (a
// moved or recoloured element clusters even when it stays under 48; the
// heaviest display glyphs can leave a run of up to 7 edge cells along one
// stroke when their subpixel phase differs between CanvasKit and Impeller).
const visualTolerance = 48;
const visualEdgeTolerance = 24;
const visualMaxEdgeCells = 56;
const visualMaxCluster = 8;
// Glyph advances differ by a few device pixels between CanvasKit and Impeller,
// so a reference cell may match a neighbouring actual cell.
const visualShift = 1;
// The normalisation must still detect a layout shift of two cells (8 px).
const sensitivityShiftPx = 8;
// Masks in normalized cells. The platform chip names the running client
// ("Web" vs "macOS") by design: once in the rail's player pill on every
// screen and once in the profile header (visible behind the daily sheet).
const visualMasks = ['0,187,3,3', '292,187,3,3', '17,177,22,8'];
const screenMasks = { profile: ['170,43,28,9'], daily: ['170,43,28,9'] };
const visualMaskNote =
  'rounded bottom window corners and the platform chip in the rail pill masked; ' +
  'profile/daily also mask the platform chip in the profile header';

async function tourClient(platform, open, dir, { screens = tourScreens, suffix = '' } = {}) {
  const seen = (await testState()).testReports.length;
  const reportsSince = async (from) => (await testState()).testReports.slice(from);
  const client = await open();
  try {
    await waitFor(
      `${platform} tour client ready`,
      async () =>
        (await reportsSince(seen)).some(
          (r) => r.platform === platform && r.phase === 'tour' && r.payload.screen === 'ready',
        ),
      { timeoutMs: 120_000, intervalMs: 1000 },
    );
    const files = {};
    for (const screen of screens) {
      const before = (await testState()).testReports.length;
      await postJson(`http://127.0.0.1:${serverPort}/test/control`, { cmd: 'show', screen });
      await waitFor(
        `${platform} shows ${screen}`,
        async () =>
          (await reportsSince(before)).some(
            (r) => r.platform === platform && r.phase === 'tour' && r.payload.screen === screen,
          ),
        { timeoutMs: 30_000, intervalMs: 500 },
      );
      await sleep(1600); // entrance animations settle
      const file = path.join(dir, `${platform}-${screen}${suffix}.png`);
      await client.screenshot(file);
      files[screen] = file;
      if (platform === 'web' && screen === 'hub' && !suffix) {
        // Same state captured twice: measures rendering noise for the
        // normalisation bounds recorded alongside the comparison.
        await sleep(1000);
        await client.screenshot(path.join(dir, 'web-hub-repeat.png'));
      }
      log(`visual ${platform}-${screen}${suffix}.png`);
    }
    return files;
  } finally {
    await client.stop();
    await waitFor(
      `${platform} tour client offline`,
      async () => (await testState()).players.every((p) => p.name !== tourName),
      { timeoutMs: 30_000, intervalMs: 500 },
    ).catch((e) => log(e.message));
  }
}

async function openWebPage(dir, params) {
  const browser = await getBrowser();
  const context = await browser.newContext({ viewport: webViewport });
  const page = await context.newPage();
  const consoleLog = fs.createWriteStream(path.join(dir, 'web-console.log'), { flags: 'a' });
  page.on('console', (m) => consoleLog.write(`[${m.type()}] ${m.text()}\n`));
  const q = new URLSearchParams({ server: `ws://localhost:${serverPort}/ws`, ...params });
  await page.goto(`http://127.0.0.1:${webPort}/?${q}`);
  return {
    screenshot: (file) => page.screenshot({ path: file }),
    stop: () => context.close().catch(() => {}),
  };
}

const openWebTour = (dir, theme = 'light') =>
  openWebPage(dir, { tour: '1', name: tourName, theme });

// Route captures that are evidence but not part of the pixel comparison: the
// sign-in screen (its focused text field has a blinking caret) and the hub in
// the dark theme.
async function routeCaptures(dir) {
  const signIn = await openWebPage(dir, { theme: 'light' });
  try {
    await sleep(4000); // app boot, fonts, entrance animation
    await signIn.screenshot(path.join(dir, 'web-signin.png'));
    log('visual web-signin.png');
  } finally {
    await signIn.stop();
  }
  await tourClient('web', () => openWebTour(dir, 'dark'), dir, {
    screens: ['hub', 'avatar'],
    suffix: '-dark',
  });
}

async function openMacTour(dir) {
  const app = findMacApp();
  const exe = path.join(app, 'Contents', 'MacOS', fs.readdirSync(path.join(app, 'Contents', 'MacOS'))[0]);
  const child = spawn(exe, [], {
    stdio: ['ignore', 'pipe', 'pipe'],
    env: {
      ...process.env,
      ...macWindowEnv,
      BRICKFOLK_TOUR: 'true',
      BRICKFOLK_NAME: tourName,
      BRICKFOLK_SERVER: `ws://localhost:${serverPort}/ws`,
      BRICKFOLK_THEME: 'light',
    },
  });
  const out = fs.createWriteStream(path.join(dir, 'macos.log'), { flags: 'a' });
  child.stdout.pipe(out);
  child.stderr.pipe(out);
  onCleanup(() => child.kill('SIGTERM'));
  const owner = path.basename(exe);
  const win = await waitFor('macOS tour window', async () => (await windowsOf(owner))[0], {
    timeoutMs: 60_000,
  });
  log(`macos tour window ${win.id} (${win.w}x${win.h})`);
  return {
    screenshot: async (file) => captureWindow(((await windowsOf(owner))[0] ?? win).id, file),
    stop: async () => {
      child.kill('SIGTERM');
      await new Promise((r) => (child.exitCode === null ? child.once('exit', r) : r()));
    },
  };
}

const visualBounds = [
  '--scale', String(visualScale),
  '--tolerance', String(visualTolerance),
  '--shift', String(visualShift),
  '--edge-tolerance', String(visualEdgeTolerance),
  '--max-edge-cells', String(visualMaxEdgeCells),
  '--max-cluster', String(visualMaxCluster),
];
const visualBoundsNote =
  `${visualScale}x box downscale, shift ${visualShift}; a cell differs beyond ${visualTolerance}/255 per channel ` +
  `(zero allowed); cells between ${visualEdgeTolerance} and ${visualTolerance} are anti-aliasing edge cells ` +
  `(at most ${visualMaxEdgeCells}, no connected run over ${visualMaxCluster})`;

async function compareSensitivity(compare, hubPng, out) {
  const w = webViewport.width - sensitivityShiftPx;
  let code = 0;
  try {
    await run('python3', [
      '-B', compare, '--id', 'hub-shifted', '--reference', hubPng, '--actual', hubPng, '--out-dir', out,
      '--reference-crop', `0,0,${w},${webViewport.height}`,
      '--actual-crop', `${sensitivityShiftPx},0,${w},${webViewport.height}`,
      ...visualBounds,
      '--note', `sensitivity check: web hub against itself shifted ${sensitivityShiftPx}px; must not pass`,
    ]);
  } catch (e) {
    code = e.code ?? 1;
  }
  const m = path.join(out, 'hub-shifted-metrics.json');
  const metrics = fs.existsSync(m) ? JSON.parse(await fsp.readFile(m, 'utf8')) : null;
  return { shiftPx: sensitivityShiftPx, detected: code !== 0 && metrics !== null, metrics };
}

// Room seats survive a disconnect for the reconnect grace period, so the hub
// keeps showing "n playing" and an open-rooms menu until the match room closes.
async function waitForQuietServer() {
  await waitFor(
    'server idle before visual tour',
    async () => {
      const s = await testState();
      return s.online === 0 && s.rooms.length === 0;
    },
    { timeoutMs: 120_000, intervalMs: 1000 },
  );
}

async function visualTour() {
  const dir = path.join(outDir, 'visual');
  fs.mkdirSync(dir, { recursive: true });
  await waitForQuietServer();
  await routeCaptures(dir);
  const web = await tourClient('web', () => openWebTour(dir), dir);
  const mac = await tourClient('macos', () => openMacTour(dir), dir);
  const compare = path.join(here, 'visual_compare.py');
  const items = [];
  for (const screen of tourScreens) {
    const out = path.join(dir, screen);
    const cmd = [
      '-B', compare,
      '--id', `hub-${screen}`,
      '--reference', web[screen],
      '--actual', mac[screen],
      '--out-dir', out,
      '--actual-crop', `0,${macTitleBar},${webViewport.width},${webViewport.height}`,
      ...visualBounds,
      ...[...visualMasks, ...(screenMasks[screen] ?? [])].flatMap((m) => ['--mask', m]),
      '--note',
      `web ${webViewport.width}x${webViewport.height} viewport vs macOS window content below the ` +
        `${macTitleBar}px title bar; ${visualBoundsNote}; ${visualMaskNote}`,
    ];
    let code = 0;
    let stderr = '';
    try {
      await run('python3', cmd);
    } catch (e) {
      code = e.code ?? 1;
      stderr = e.stderr ?? e.message;
    }
    const metricsFile = path.join(out, `hub-${screen}-metrics.json`);
    const metrics = fs.existsSync(metricsFile) ? JSON.parse(await fsp.readFile(metricsFile, 'utf8')) : null;
    items.push({ screen, passed: code === 0, metrics, error: code === 0 ? null : stderr.trim().slice(-400) });
    log(
      `visual hub-${screen}: ${code === 0 ? 'match' : 'MISMATCH'}` +
        (metrics
        ? ` (differing=${metrics.different_pixels} edge=${metrics.edge_cells} maxDelta=${metrics.max_unmasked_delta} cluster=${metrics.largest_cluster})`
        : ''),
    );
  }
  // Sensitivity: the same web hub against itself shifted by 8 px must fail
  // under the same bounds, or the normalisation is too loose to trust.
  const sensitivity = await compareSensitivity(compare, web.hub, path.join(dir, 'hub-shifted'));
  log(
    `visual sensitivity (8px shift): ${sensitivity.detected ? 'detected' : 'NOT DETECTED'}` +
      ` (differing=${sensitivity.metrics?.different_pixels} cluster=${sensitivity.metrics?.largest_cluster})`,
  );
  // Rendering-noise baseline: web hub captured twice under the same conditions.
  let noise = null;
  const repeat = path.join(dir, 'web-hub-repeat.png');
  if (fs.existsSync(repeat)) {
    const out = path.join(dir, 'hub-repeat');
    await run('python3', [
      '-B', compare, '--id', 'web-hub-repeat', '--reference', web.hub, '--actual', repeat,
      '--out-dir', out, '--scale', String(visualScale), '--tolerance', '0',
      '--note', 'same web state captured twice; raw noise measurement (tolerance 0)',
    ]).catch(() => {});
    const m = path.join(out, 'web-hub-repeat-metrics.json');
    if (fs.existsSync(m)) noise = JSON.parse(await fsp.readFile(m, 'utf8'));
  }
  const summary = { reference: 'web', actual: 'macos', screens: items, noiseBaseline: noise, sensitivity };
  await fsp.writeFile(path.join(dir, 'summary.json'), JSON.stringify(summary, null, 2));
  return summary;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  log(`Brickfolk multiplayer e2e: platforms=${platforms.join(',')} experience=${experience} seed=${seed} party=${partyCode} bots=${bots}`);
  log(`evidence -> ${outDir}`);
  for (const p of platforms) {
    if (!starters[p]) throw new Error(`Unknown platform ${p}`);
  }

  if (visualOnly) return visualOnlyMain();

  if (build) {
    for (const p of platforms) await flutterBuild(p);
  } else {
    log('skipping builds (--no-build)');
    const baked = platforms.filter((p) => p === 'ios' || p === 'android');
    if (baked.length) {
      log(
        `note: ${baked.join('/')} read their test config from build-time defines; ` +
          'reuse only builds produced by this harness with the same options',
      );
    }
  }

  await stopStaleClients();
  await startServer();

  const clients = [];
  for (const p of platforms) {
    log(`starting ${p} client`);
    clients.push(await starters[p]());
  }

  const { results, state, timeline } = await observeMatch(clients);

  // Stop recordings and clients before heavy verification work.
  const videos = {};
  for (const c of clients) {
    videos[c.name] = await c.stopRecording().catch((e) => {
      log(`recording ${c.name} failed: ${e.message}`);
      return null;
    });
  }
  const fourWay = await composeRecording(
    videos,
    Object.fromEntries(clients.map((c) => [c.name, c.recordingStartedAt ?? null])),
  );
  for (const c of clients) await c.stop?.();

  let visualSummary = null;
  if (visual) {
    log('visual tour: web (reference) then macOS, same player and screens');
    visualSummary = await visualTour();
  }

  // ----- Assertions --------------------------------------------------------
  const failures = [];
  failures.push(...visualFailures(visualSummary));
  const canon = Object.fromEntries(platforms.map((p) => [p, canonical(results[p])]));
  const reference = canon[platforms[0]];
  for (const p of platforms) {
    if (canon[p] !== reference) failures.push(`${p} final state differs from ${platforms[0]}`);
  }
  const roomCode = results[platforms[0]].room;
  const room = state.rooms.find((r) => r.code === roomCode);
  if (!room) failures.push(`room ${roomCode} not present in server snapshot`);
  const serverResults = room?.lastResults;
  if (serverResults && serverResults.checksum !== results[platforms[0]].checksum) {
    failures.push(
      `server checksum ${serverResults.checksum} != client checksum ${results[platforms[0]].checksum}`,
    );
  }
  const parties = state.parties.filter((p) => p.code === partyCode);
  if (parties.length !== 1) failures.push(`expected one party ${partyCode}, found ${parties.length}`);
  const partyPlatforms = new Set(
    (parties[0]?.members ?? []).map((m) => m.platform).filter(Boolean),
  );
  for (const p of platforms) {
    if (!partyPlatforms.has(p)) failures.push(`${p} is not a member of party ${partyCode}`);
  }
  const memberPlatforms = new Set((room?.members ?? []).filter((m) => !m.player.isBot).map((m) => m.player.platform));
  for (const p of platforms) {
    if (!memberPlatforms.has(p)) failures.push(`${p} is not in room ${roomCode}`);
  }
  const leaderboard = results[platforms[0]].leaderboard ?? [];
  const expectedEntries = platforms.length + bots;
  if (leaderboard.length !== expectedEntries) {
    failures.push(`leaderboard has ${leaderboard.length} entries, expected ${expectedEntries}`);
  }
  for (const p of platforms) {
    for (const phase of ['lobby', 'gameplay', 'results']) {
      if (!fs.existsSync(path.join(outDir, `${p}-${phase}.png`))) failures.push(`missing ${p}-${phase}.png`);
    }
  }
  for (const p of platforms) {
    if (!videos[p]) failures.push(`missing recording for ${p}`);
  }
  if (!fourWay) failures.push('four-way recording was not produced');

  const report = {
    passed: failures.length === 0,
    failures,
    platforms,
    experience,
    seed,
    party: partyCode,
    bots,
    room: roomCode,
    checksum: results[platforms[0]].checksum,
    serverChecksum: serverResults?.checksum ?? null,
    leaderboard,
    perPlatform: results,
    identical: Object.fromEntries(platforms.map((p) => [p, canon[p] === reference])),
    screenshots: Object.fromEntries(
      platforms.map((p) => [p, ['lobby', 'gameplay', 'results'].map((ph) => `${p}-${ph}.png`)]),
    ),
    recordings: { ...videos, fourWay },
    recordingStartedAt: Object.fromEntries(clients.map((c) => [c.name, c.recordingStartedAt ?? null])),
    timeline,
    visual: visualSummary,
    androidAnrDismissals: anrDismissals,
    androidCapture: platforms.includes('android') ? androidCapture : null,
    androidMarkerTimes: clients.find((c) => c.name === 'android')?.markerTimes ?? null,
    serverTick: state.tick,
    durationSec: Math.round((Date.now() - started) / 1000),
    evidenceDir: outDir,
  };
  await fsp.writeFile(path.join(outDir, 'report.json'), JSON.stringify(report, null, 2));
  await fsp.writeFile(path.join(outDir, 'server-state.json'), JSON.stringify(state, null, 2));

  const lines = [
    `# Brickfolk multiplayer e2e — ${report.passed ? 'PASSED' : 'FAILED'}`,
    '',
    `- platforms: ${platforms.join(', ')}  (host: ${hostPlatform})`,
    `- experience: ${experience}  seed: ${seed}  party: ${partyCode}  room: ${roomCode}  bots: ${bots}`,
    `- checksum (all clients): ${report.checksum}  server: ${report.serverChecksum}`,
    `- identical final state: ${platforms.map((p) => `${p}=${report.identical[p]}`).join(' ')}`,
    `- duration: ${report.durationSec}s  server tick: ${state.tick}`,
    ...(platforms.includes('android')
      ? [
          androidCapture === 'marker'
            ? `- android screenshots: emulator display frames taken once the app's phase marker showed each phase (display trails the app on the software emulator; markers seen at ${JSON.stringify(report.androidMarkerTimes)} s), verified free of system ANR dialogs (${anrDismissals} dismissed during the run)`
            : `- android screenshots: emulator display, verified free of system ANR dialogs (${anrDismissals} dismissed during the run)`,
        ]
      : []),
    '',
    '| rank | player | score | detail |',
    '|---|---|---|---|',
    ...leaderboard.map((e) => `| ${e.rank} | ${e.player} | ${e.score} | ${e.detail ?? ''} |`),
    '',
    ...(visualSummary
      ? [
          ...visualLines(visualSummary),
          '',
        ]
      : []),
    ...(failures.length ? ['## Failures', ...failures.map((f) => `- ${f}`)] : []),
  ];
  await fsp.writeFile(path.join(outDir, 'summary.md'), lines.join('\n') + '\n');
  log(lines.join('\n'));
  if (!args['no-review']) await buildReview(outDir);
  return report.passed;
}

// Edited review video (title/chapter cards, aligned per-platform clips,
// captions, verdict) cut from this run's evidence by review_video.mjs.
async function buildReview(dir) {
  try {
    const { stdout } = await execFileP(process.execPath, [path.join(here, 'review_video.mjs'), dir], {
      maxBuffer: 1 << 24,
    });
    log(stdout.trim().split('\n').at(-1));
  } catch (e) {
    log(`review video failed (evidence unaffected): ${e.message.split('\n')[0]}`);
  }
}

function visualFailures(summary) {
  if (!summary) return [];
  const failures = summary.screens
    .filter((s) => !s.passed)
    .map((s) => `visual mismatch web vs macos on ${s.screen}: ${s.error ?? ''}`.trim());
  if (!summary.sensitivity?.detected) {
    failures.push(`visual normalisation did not detect a ${summary.sensitivity?.shiftPx ?? '?'}px shift`);
  }
  return failures;
}

function visualLines(summary) {
  const m = summary.sensitivity?.metrics;
  return [
    '## Visual parity (web reference vs macOS)',
    ...summary.screens.map(
      (s) =>
        `- ${s.screen}: ${s.passed ? 'match' : 'MISMATCH'}` +
        (s.metrics
          ? ` (differing ${s.metrics.different_pixels}, edge cells ${s.metrics.edge_cells}, ` +
            `max delta ${s.metrics.max_unmasked_delta}, cluster ${s.metrics.largest_cluster})`
          : ''),
    ),
    `- sensitivity (web hub vs itself shifted ${summary.sensitivity?.shiftPx}px): ` +
      `${summary.sensitivity?.detected ? 'detected' : 'NOT DETECTED'}` +
      (m ? ` (differing ${m.different_pixels}, cluster ${m.largest_cluster})` : ''),
    ...(summary.noiseBaseline
      ? [`- noise baseline (web hub captured twice, tolerance 0): differing ${summary.noiseBaseline.different_pixels}`]
      : []),
  ];
}

// Visual parity only: web (reference) and macOS tour the same hub screens on
// a fresh server without playing a match.
async function visualOnlyMain() {
  if (build) {
    for (const p of ['web', 'macos']) await flutterBuild(p);
  } else {
    log('skipping builds (--no-build)');
  }
  await stopStaleClients();
  await startServer();
  await serveWebBuild();
  const visualSummary = await visualTour();
  const failures = visualFailures(visualSummary);
  const report = {
    passed: failures.length === 0,
    failures,
    mode: 'visual-only',
    visual: visualSummary,
    durationSec: Math.round((Date.now() - started) / 1000),
    evidenceDir: outDir,
  };
  await fsp.writeFile(path.join(outDir, 'report.json'), JSON.stringify(report, null, 2));
  const lines = [
    `# Brickfolk visual parity — ${report.passed ? 'PASSED' : 'FAILED'}`,
    '',
    ...visualLines(visualSummary),
    '',
    ...(failures.length ? ['## Failures', ...failures.map((f) => `- ${f}`)] : []),
  ];
  await fsp.writeFile(path.join(outDir, 'summary.md'), lines.join('\n') + '\n');
  log(lines.join('\n'));
  return report.passed;
}

let ok = false;
try {
  ok = await main();
} catch (e) {
  log(`ERROR: ${e.stack ?? e.message}`);
} finally {
  await cleanup();
  logFile.end();
}
process.exit(ok ? 0 : 1);
