// Drives the Nitro Tots web build through Playwright for the cross-platform
// multiplayer test. The page joins the deterministic room via query
// parameters; this script only positions the window, captures a screenshot
// on every room-phase change (lobby / racing / results / matchOver) and exits
// once the match is over.
//
//   node web_client.mjs <appUrl> <serverHttpUrl> <roomCode> <outDir> [x,y,w,h]
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';

const [appUrl, serverUrl, room, outDir, geometry = '0,30,800,560'] = process.argv.slice(2);
if (!appUrl || !serverUrl || !room || !outDir) {
  console.error('usage: web_client.mjs <appUrl> <serverHttpUrl> <roomCode> <outDir> [x,y,w,h]');
  process.exit(2);
}
const [x, y, w, h] = geometry.split(',').map(Number);
fs.mkdirSync(outDir, { recursive: true });

const timeoutMs = Number(process.env.NT_E2E_TIMEOUT_MS ?? 15 * 60 * 1000);
const headless = process.env.NT_E2E_HEADLESS === '1';

const browser = await chromium.launch({
  headless,
  args: [`--window-position=${x},${y}`, `--window-size=${w},${h}`, '--autoplay-policy=no-user-gesture-required'],
});
const context = await browser.newContext({ viewport: null });
const page = await context.newPage();
page.on('pageerror', (e) => console.log(`[web] pageerror: ${e.message}`));
page.on('console', (m) => {
  if (m.type() === 'error') console.log(`[web] console.error: ${m.text()}`);
});

await page.goto(appUrl, { waitUntil: 'load' });
console.log(`[web] loaded ${appUrl}`);

let lastPhase = '';
const seen = new Set();
const started = Date.now();
while (Date.now() - started < timeoutMs) {
  let status = null;
  try {
    const res = await fetch(`${serverUrl}/rooms/${room}`);
    if (res.ok) status = (await res.json()).status;
  } catch (_) {
    // server not up yet
  }
  if (status && status !== lastPhase) {
    lastPhase = status;
    // Let the screen transition settle before capturing.
    await page.waitForTimeout(status === 'racing' ? 9000 : 2500);
    const file = path.join(outDir, `web_${status}.png`);
    await page.screenshot({ path: file });
    seen.add(status);
    console.log(`[web] ${status} -> ${file}`);
    if (status === 'matchOver') break;
  } else if (status === 'racing' && !seen.has('racing_mid')) {
    // A second in-race capture with the HUD fully populated.
    await page.waitForTimeout(20000);
    await page.screenshot({ path: path.join(outDir, 'web_racing_mid.png') });
    seen.add('racing_mid');
  }
  await page.waitForTimeout(500);
}
if (lastPhase !== 'matchOver') {
  console.log('[web] timed out waiting for matchOver');
  await browser.close();
  process.exit(1);
}
// Stay on the podium long enough for the recording, then exit.
await page.waitForTimeout(Number(process.env.NT_E2E_LINGER_MS ?? 6000));
await browser.close();
