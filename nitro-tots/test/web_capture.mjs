// Captures one Nitro Tots web screen at an exact CSS viewport for the
// cross-platform visual parity harness (test/visual_parity.py).
//
//   node web_capture.mjs <url> <out.png> <width> <height> [settleMs]
import { chromium } from 'playwright';

const [url, out, w, h, settle = '3500'] = process.argv.slice(2);
if (!url || !out || !w || !h) {
  console.error('usage: node web_capture.mjs <url> <out.png> <width> <height> [settleMs]');
  process.exit(2);
}

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  viewport: { width: Number(w), height: Number(h) },
  deviceScaleFactor: 1,
  colorScheme: 'light',
  reducedMotion: 'reduce',
});
const page = await context.newPage();
page.on('pageerror', (e) => console.log(`[web] pageerror: ${e.message}`));
await page.goto(url, { waitUntil: 'load' });
await page.waitForTimeout(Number(settle));
await page.screenshot({ path: out });
await browser.close();
console.log(`[web] ${url} -> ${out}`);
