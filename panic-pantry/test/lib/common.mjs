// Shared helpers for the Panic Pantry test harnesses (e2e + visual parity).

import { spawnSync } from 'node:child_process';
import { createServer } from 'node:http';
import { createReadStream, existsSync, statSync } from 'node:fs';
import { extname, join } from 'node:path';

export const env = (k, d) => (process.env[k] && process.env[k].length ? process.env[k] : d);

export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

export function stamp() {
  return new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
}

export function sh(cmd, args, opts = {}) {
  const r = spawnSync(cmd, args, { encoding: 'utf8', ...opts });
  if (r.error) throw r.error;
  return r;
}

/** JSON HTTP client bound to the game server's test API. */
export function makeHttp(port) {
  return async function http(method, path, body) {
    const res = await fetch(`http://localhost:${port}${path}`, {
      method,
      headers: { 'content-type': 'application/json' },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const text = await res.text();
    let json;
    try {
      json = JSON.parse(text);
    } catch {
      json = { raw: text };
    }
    if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${text}`);
    return json;
  };
}

export async function waitFor(desc, fn, timeoutMs, everyMs = 500) {
  const end = Date.now() + timeoutMs;
  let last;
  while (Date.now() < end) {
    try {
      last = await fn();
      if (last) return last;
    } catch (e) {
      last = e;
    }
    await sleep(everyMs);
  }
  throw new Error(`timed out waiting for ${desc}${last instanceof Error ? `: ${last.message}` : ''}`);
}

// --- Static web server for build/web --------------------------------------
const MIME = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.wasm': 'application/wasm',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff2': 'font/woff2',
  '.frag': 'application/octet-stream',
  '.symbols': 'text/plain',
};
export function serveWeb(dir, port) {
  return new Promise((ok, fail) => {
    const srv = createServer((req, res) => {
      const url = new URL(req.url, 'http://x');
      let file = join(dir, decodeURIComponent(url.pathname));
      if (!existsSync(file) || statSync(file).isDirectory()) file = join(file, 'index.html');
      if (!existsSync(file)) {
        res.writeHead(404).end();
        return;
      }
      res.writeHead(200, { 'content-type': MIME[extname(file)] ?? 'application/octet-stream', 'cache-control': 'no-store' });
      createReadStream(file).pipe(res);
    });
    srv.on('error', fail);
    srv.listen(port, '127.0.0.1', () => ok(srv));
  });
}

// --- macOS window management ------------------------------------------------
export function osascript(script) {
  return sh('osascript', ['-e', script]).stdout.trim();
}

/** Frame of the first window of a macOS process (includes the title bar). */
export function windowBounds(processName) {
  const s = osascript(`tell application "System Events" to tell process "${processName}" to get {position, size} of window 1`);
  const [x, y, w, h] = s.split(',').map((n) => Number(n.trim()));
  return { x, y, w, h };
}

/** Moves (and optionally resizes) the first window of a macOS process. Throws on failure. */
export function placeWindow(processName, x, y, w, h) {
  osascript(
    `tell application "System Events" to tell process "${processName}"\n set position of window 1 to {${x}, ${y}}\n` +
      (w ? ` set size of window 1 to {${w}, ${h}}\n` : '') +
      'end tell',
  );
}
