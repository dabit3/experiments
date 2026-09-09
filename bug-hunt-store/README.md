# Bug Hunt: a storefront with 8 planted bugs and a scoreboard

"Kestrel" is a polished fake e-commerce store built with Vite + React + TypeScript, styled after
editorial fashion retailers (black-on-white, hairline rules, uppercase tracking, bundled Inter and
Archivo variable fonts, hand-drawn line illustrations for all 24 products): a 24-product grid with
search, department navigation, a rating filter, five sort orders, pagination (8 per page), a
slide-in shopping bag with quantity steppers, and a checkout modal with a promotion-code field.
Exactly **eight realistic bugs** are planted in it (wrong maths, broken sorting, an invisible
overlay, off-by-one paging…). A floating **Report a bug** widget lets a tester pick an area,
describe what went wrong, and a hidden keyword matcher (defined in `src/data/bugs.json`) decides
whether the report hits a planted bug. Confirmed reports light up the **Bugs found: n/8**
scoreboard in the header; finding all eight unlocks a QA-hero screen.

The bugs are documented, with repro steps and file locations, in [`SPOILERS.md`](SPOILERS.md).
Don't read it until you have hunted.

## Run it

```bash
cd bug-hunt-store
npm install
npm run dev
```

Then open the printed `http://localhost:5173` URL. `npm run build` type-checks (strict) and
produces a static bundle in `dist/`; `npm run lint` runs oxlint. There is no backend and no
runtime network access — the catalog, bug definitions and artwork are all bundled. Cart contents
and hunt progress persist in `localStorage`; **Reset hunt** on the scoreboard clears progress.

## Computer-use skill showcased

**Exploratory QA**: noticing wrong maths, broken sorting, overlays, off-by-one paging — and
writing them up so they can be reproduced. Nothing tells the tester where the bugs are; they have
to be found by driving the store like a suspicious customer, cross-checking totals, page counts
and sort orders against what the UI claims.

## Browser test scenario

Devin runs the app, maximizes Chrome, turns on screen recording and, **without reading
`SPOILERS.md`**, explores the store as a QA tester:

1. **Sort by price.** Switch Sort to "Price: Low to High". *Expected:* cheapest first ($9.50 Cable
   Kit). *Actual:* `$109`, `$119`, `$129`, then `$1,299.00` Vinyl Turntable ahead of `$145` —
   prices are ordered as text. Report it under *Sorting & filtering* → scoreboard 1/8.
2. **Search casing.** Type `lamp` in the search box. *Expected:* Desk Lamp and Headlamp.
   *Actual:* only Headlamp, while `Lamp` returns only Desk Lamp and `desk lamp` returns
   "No results". Report under *Search* → 2/8.
3. **Paging.** Walk pages 01 → 02 → 03 with the pagination buttons. *Expected:* 24 distinct
   products. *Actual:* page 3 repeats Camp Stove from page 2 and the 24th product (Hiking Backpack)
   never shows even though the summary says "Showing 17–24 of 24". Report under *Pagination* → 3/8.
4. **Stars.** On page 2, Sleep Ring (rating 5.0) shows **six** filled stars. Report under
   *Product card* → 4/8.
5. **Blocked button.** On page 1, click "Add to bag" on the 5th card (Wireless Earbuds).
   *Expected:* the Bag count increments. *Actual:* nothing. Resize the window (un-maximize /
   re-maximize) and an "Editor's pick" tag appears; now the button works. Report under
   *Buttons & layout* → 5/8.
6. **Quantity maths.** Add Studio Headphones, open the bag, press **+** twice. *Expected:* line
   `$747.00`. *Actual:* still `$249.00`; the subtotal does not move. Report under *Cart & totals*
   → 6/8.
7. **Wrong line removed.** Add Desk Lamp ($49) and Canvas Tote ($49); in the bag click Remove
   on the Canvas Tote. *Actual:* the Desk Lamp vanishes. Report under *Cart & totals* → 7/8.
8. **Coupon.** Checkout, apply `SAVE10`. *Expected:* 10% off. *Actual:* a flat `−$10.00`.
   Report under *Coupons & checkout* → 8/8.
9. When the eighth report is confirmed the **QA hero** screen appears listing all eight bugs.
   The PR notes which bugs were found unaided and which (if any) needed `SPOILERS.md`.

Every report goes through the floating **Report a bug** widget (area dropdown + free-text
description). The scoreboard button in the header opens a per-bug checklist at any time.

### Recording

**Recording (mp4):** https://app.devin.ai/attachments/816c9600-33b0-4f5e-bf0e-d53f344139aa/kestrel-blind-hunt-edited.mp4

![Bug Hunt showcase preview](https://app.devin.ai/attachments/c00604fe-f957-43dc-b600-79d3fb302ddd/kestrel-blind-hunt-preview.webp)

Outcome of the recorded run: a **blind** hunt performed by Devin's built-in testing agent as a
native test plan (Devin session `c510e4fb21f24ef09820f2e4fd6ca460`; the test plan and
test-execution panel are viewable in the Devin web app). Neither the session nor the testing
agent was allowed to read `SPOILERS.md`, `README.md`, the source, `bugs.json`, the PR or git
history, and no repro hints were given. It found and reported **all 8 planted bugs unaided in
~8.5 minutes** of exploration; `SPOILERS.md` was never opened. The mp4 is the native recording
(no post-processing).

Earlier recordings: a blind run by a fresh Devin session driving Chrome directly, all 8 unaided
in ~21 min, with a post-processed test-execution panel
(https://app.devin.ai/attachments/b11b33e2-5cc5-4bf4-a6db-616c0b591f77/kestrel-bug-hunt-final.mp4);
a guided run on the redesigned storefront
(https://app.devin.ai/attachments/09a54feb-9053-46de-b635-d309c1afddf0/bug-hunt-store-v2-edited.mp4);
and the first blind run on the original visual design
(https://app.devin.ai/attachments/a11ae4ce-dea8-4c03-b776-b2da33034f61/bug-hunt-store-showcase.mp4).
The 21-minute run also surfaced one genuine unplanned defect (Enter in the promo-code field
placed the order instead of applying the code), which the matcher correctly rejected as not
planted and which has since been fixed.

## Project layout

```
src/
  App.tsx                    state, filtering/sorting/paging wiring, overlays
  components/
    Header.tsx               department nav, KESTREL wordmark, search, scoreboard, Bag
    Wordmark.tsx             text wordmark used in the header and hero
    Toolbar.tsx              page heading, item count, rating filter, sort select
    ProductCard.tsx          card + the invisible "deal" overlay
    ProductArt.tsx           24 deterministic inline SVG line illustrations
    Stars.tsx                star rating (one product renders six)
    Pagination.tsx           page buttons + "Showing a–b of n"
    CartDrawer.tsx           slide-in shopping bag, quantity steppers, remove
    CheckoutModal.tsx        order summary, promotion code, fake payment form
    BugReporter.tsx          floating report widget
    Scoreboard.tsx           n/8 checklist, reset
    HeroScreen.tsx           8/8 celebration
  data/products.ts           24 deterministic products
  data/bugs.json             hidden matcher: id, title, area, keyword groups
  lib/catalog.ts             search / filter / sort / paginate
  lib/cart.ts                cart maths, coupons, shipping
  lib/matcher.ts             keyword matcher for bug reports
  hooks/                     localStorage state, window-resize flag
```
