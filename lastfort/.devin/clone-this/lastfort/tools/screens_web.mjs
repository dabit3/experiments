// Captures the hub screens (Play, Locker, Pass, Settings) of the web build in
// light + dark themes and at desktop + phone viewports, as clone-this
// evidence. Copy next to test/node_modules (Playwright lives there) and run:
//   node screens_web.mjs <baseUrl> <outDir>
// Navigation uses the fixed top-bar tab geometry because Flutter web only
// exposes semantics after opt-in.
import { chromium } from 'playwright';
import { mkdirSync } from 'node:fs';
import path from 'node:path';

const [base, out] = process.argv.slice(2);
mkdirSync(out, { recursive: true });
const browser = await chromium.launch({ headless: true });

const layouts = {
  desktop: {
    viewport: { width: 1280, height: 800 },
    taps: { play: [240, 30], locker: [326, 30], pass: [410, 30], settings: [503, 30] },
  },
  phone: {
    viewport: { width: 390, height: 844 },
    taps: { play: [67, 26], locker: [129, 26], pass: [191, 26], settings: [259, 26] },
  },
};

for (const [vpName, { viewport, taps }] of Object.entries(layouts)) {
  for (const theme of ['light', 'dark']) {
    const context = await browser.newContext({ viewport, deviceScaleFactor: 2 });
    const page = await context.newPage();
    await page.goto(`${base}/?name=Web&theme=${theme}&server=${encodeURIComponent(base.replace(/^http/, "ws") + "/ws")}`, { waitUntil: 'load' });
    await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 120000 });
    await page.waitForTimeout(2500);
    for (const [tab, [x, y]] of Object.entries(taps)) {
      await page.mouse.click(x, y);
      await page.waitForTimeout(900);
      await page.screenshot({ path: path.join(out, `web-${vpName}-${theme}-${tab}.png`) });
    }
    await context.close();
  }
}
await browser.close();
