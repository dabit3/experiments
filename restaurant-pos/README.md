# Restaurant POS: floor plan, modifiers, and split bills

A tablet-style restaurant point of sale ("Ember POS") built with Vite + React + TypeScript. Everything runs in memory from a deterministic seeded demo state — no backend, no network calls.

Designed for a fine-dining service: warm ivory surfaces, forest-green controls, restrained brass details, a serif Ember wordmark, and an architectural floor plan. Cormorant Garamond, Inter, and JetBrains Mono are bundled locally. Live check cards and searchable menus keep the service workflow close at hand; the floor remains scrollable and usable on tablets.

**What it does**

- **Floor plan** with 12 tables. Tap a table to seat a party or open its check. Toggle **Edit layout** to drag tables around a snapping grid.
- **Per-seat ordering** — pick a seat, tap menu items across five categories (Starters, Mains, Sides, Drinks, Desserts).
- **Modifiers** — required and optional groups with price deltas (steak temperature, sides, add-ons, allergies, wing sauce, wine pour…). Items with required groups cannot be added until every required group is satisfied.
- **Courses, notes, voids** — assign items to course 1/2/3, add free-text kitchen notes, fire a course to the kitchen, void a line with a reason.
- **Arithmetic** — 8.875% sales tax, 18% auto-gratuity for parties of 6+, percentage or fixed discounts. All money is integer cents; discount/tax/gratuity are allocated across splits with largest-remainder rounding so the splits always sum exactly to the table total.
- **Split & pay** — split by seat, evenly (N ways), or by item (assign each line to check A/B/C…). Each split takes an optional extra tip and a card/cash payment. A verification bar shows `split₁ + split₂ + … = table total`.
- **Receipts** — a printable receipt per split (`window.print()` prints only the receipt paper).
- **Kitchen ticket view** — every fired course becomes a ticket listing seat, item, modifiers, and notes; tickets can be bumped.

## Run it

```sh
cd restaurant-pos
npm install
npm run dev      # http://localhost:5173
npm run lint     # oxlint
npm run build    # tsc -b && vite build
```

## Computer-use skill showcased

**Complex stateful workflow with arithmetic that must be verified visually.** The scenario walks through a long, branching, multi-screen workflow (seating → ordering with modal modifiers → firing → voiding → splitting → paying → receipts → kitchen), and at the end the agent must read the on-screen numbers and confirm that the per-seat totals add up to the table total including tax and the 18% auto-gratuity.

## Browser test scenario

Reset state with **Reset demo** (or reload the page) so the seeded state is identical every run.

| # | Step | Expected result |
|---|------|-----------------|
| 1 | On the floor plan, click **Table 4**, pick **6**, click **Seat party of 6**. | Order view for Table 4 opens showing `Party of 6` and an `18% auto-gratuity` chip; six empty seat tabs. |
| 2 | Seat 1: **Ribeye Steak** → **Medium rare** + **Hand-cut fries**, note `No butter, sauce on the side` → add. Add **Craft IPA**. | Required modifiers gate the Add button. Steak is $42.00; Seat 1 subtotal is $50.00, with the note visible. |
| 3 | Seat 2: **Ember Burger** → **Medium** + **Truffle fries** → add. Add **Old Fashioned**. | Burger is $22.00 (18 + 4); Seat 2 subtotal is $37.00. |
| 4 | Seat 3: add **Cedar Plank Salmon**, **Sparkling Water**, and **Pappardelle Bolognese**. Seat 4: add **Crispy Calamari**. | Eight ordered lines across four seats. |
| 5 | Click **Fire course 1**. | Four first-course lines change to `Fired`; Kitchen badge increases from 4 to 5. |
| 6 | Void **Pappardelle Bolognese** with reason **Guest changed mind**. | Pasta is struck through with its reason, excluded from totals; seven active lines remain. |
| 7 | Click **Fire course 2**. | Steak, burger, and salmon fire; Kitchen badge reaches 6. |
| 8 | Click **Split & pay** → **By seat**. Read each subtotal, tax, gratuity and total. | Four seat totals are $63.44, $46.94, $41.87, $16.49. Their sum is $168.74, matching $133.00 subtotal + $11.80 tax + $23.94 gratuity. Green reconciliation chip is visible. |
| 9 | Pay Seat 1 by card with a **20%** additional tip; pay Seats 2–4 by card with no additional tip. | Seat 1 adds $10.00 and charges $73.44; other charges match their split totals. Header shows `4/4 paid`; **Close table** enables. |
| 10 | Open Seat 1's **Receipt**, then click **Print receipt**. | Receipt shows modifiers, note, $63.44 total, $10.00 extra tip, and $73.44 charged. Actual Chrome print preview shows one page with the complete receipt and barcode. Cancel the print dialog and close the receipt. |
| 11 | Open **Kitchen** and locate both Table 4 tickets. | Four first-course lines and three mains show their seat assignments; steak modifiers/note are present, voided pasta is absent. |
| 12 | Return to Table 4's payment view and click **Close table**. | Table 4 becomes available, disappears from active check cards, and floor KPIs return to 3/12 occupied and 15 guests. |

## Recording

**Recording:** https://app.devin.ai/attachments/683fad6c-3e6e-4f60-8cee-756197464f05/ember4-final-showcase-edited.mp4

![Animated preview](https://app.devin.ai/attachments/bb36237e-9541-4bc4-a0f6-d9d444333c50/restaurant-pos-preview.webp)

Devin tested the complete scenario by hand in maximized Chrome at 1600×1200 with recording annotations and eight full screenshots. Separate preflight checks covered floor dragging, sidebar navigation, menu search, and 1024×768 tablet ordering/modals. Testing caught and fixed overly small tablet floor targets and a barcode omitted by default print settings; the final scenario passed after both fixes.

Numbers from the recorded run (party of 6 at Table 4, 8 items ordered, 1 voided):

| Seat | Subtotal | Tax 8.875% | Gratuity 18% | Total |
|------|---------:|-----------:|-------------:|------:|
| 1 — Ribeye (medium rare, hand-cut fries, note), Craft IPA | $50.00 | $4.44 | $9.00 | $63.44 |
| 2 — Ember Burger (medium, truffle fries +$4), Old Fashioned | $37.00 | $3.28 | $6.66 | $46.94 |
| 3 — Cedar Plank Salmon, Sparkling Water (Pappardelle voided) | $33.00 | $2.93 | $5.94 | $41.87 |
| 4 — Crispy Calamari | $13.00 | $1.15 | $2.34 | $16.49 |
| **Table** | **$133.00** | **$11.80** | **$23.94** | **$168.74** |

The four seat totals sum to $168.74, exactly the table total shown in the verification bar. Seat 1 added a 20% tip ($10.00) and was charged $73.44.
