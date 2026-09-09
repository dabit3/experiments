# Bug Hunt: a storefront with 8 planted bugs and a scoreboard

"Kestrel Supply" is a polished fake e-commerce store built with Vite + React + TypeScript: a
24-product grid with search, category and rating filters, five sort orders, pagination (8 per
page), a slide-in cart drawer with quantity steppers, and a checkout modal with a coupon field.
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
   Kit). *Actual:* `$1,299.00` Vinyl Turntable leads and `$9.50` comes last — string ordering.
   Report it under *Sorting & filtering* → scoreboard 1/8.
2. **Search casing.** Type `lamp` in the search box. *Expected:* Desk Lamp. *Actual:* "No products
   match"; `Lamp` works. Report under *Search* → 2/8.
3. **Paging.** Walk pages 1 → 2 → 3 with the pagination buttons. *Expected:* 24 distinct products.
   *Actual:* page 3 repeats Camp Stove from page 2 and the 24th product (Hiking Backpack) never
   shows even though the footer says "Showing 17–24 of 24". Report under *Pagination* → 3/8.
4. **Stars.** On page 2, Sleep Ring (rating 5.0) shows **six** filled stars. Report under
   *Product card* → 4/8.
5. **Blocked button.** On page 1, click "Add to cart" on the 5th card (Wireless Earbuds).
   *Expected:* cart badge increments. *Actual:* nothing. Resize the window (un-maximize /
   re-maximize) and a "Deal of the day" ribbon appears; now the button works. Report under
   *Buttons & layout* → 5/8.
6. **Quantity maths.** Add Studio Headphones, open the cart, press **+** twice. *Expected:* line
   `$747.00`. *Actual:* still `$249.00`; the subtotal does not move. Report under *Cart & totals*
   → 6/8.
7. **Wrong line removed.** Add Desk Lamp ($49) and Canvas Tote ($49); in the cart click Remove
   on the Canvas Tote. *Actual:* the Desk Lamp vanishes. Report under *Cart & totals* → 7/8.
8. **Coupon.** Checkout, apply `SAVE10`. *Expected:* 10% off. *Actual:* a flat `−$10.00`.
   Report under *Coupons & checkout* → 8/8.
9. When the eighth report is confirmed the **QA hero** screen appears listing all eight bugs.
   The PR notes which bugs were found unaided and which (if any) needed `SPOILERS.md`.

Every report goes through the floating **Report a bug** widget (area dropdown + free-text
description). The scoreboard button in the header opens a per-bug checklist at any time.

### Recording

**Recording (mp4): _placeholder — filled in after the showcase_**

## Project layout

```
src/
  App.tsx                    state, filtering/sorting/paging wiring, overlays
  components/
    Header.tsx               brand, search, scoreboard pill, cart button
    Toolbar.tsx              category chips, rating filter, sort select
    ProductCard.tsx          card + the invisible "deal" overlay
    Stars.tsx                star rating (one product renders six)
    Pagination.tsx           page buttons + "Showing a–b of n"
    CartDrawer.tsx           slide-in cart, quantity steppers, remove
    CheckoutModal.tsx        order summary, coupon field, fake payment form
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
