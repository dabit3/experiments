# Restaurant POS: floor plan, modifiers, and split bills

A tablet-style restaurant point of sale ("Ember POS") built with Vite + React + TypeScript. Everything runs in memory from a deterministic seeded demo state — no backend, no network calls.

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
| 2 | With Seat 1 selected, click **Ribeye Steak** → choose **Medium rare** + **Grilled asparagus** → **Add to Seat 1**. | Line added to Seat 1 at $45.00 (42 + 3). The Add button was disabled until both required groups were chosen. |
| 3 | Select Seat 2, click **Ember Burger** → **Medium** + **Truffle fries** → add. | Seat 2 shows Ember Burger $22.00 (18 + 4). |
| 4 | Select Seat 3, click **Customize** on **Mushroom Risotto**, type a note (e.g. `Extra parmesan, no truffle oil`) → add. | Seat 3 shows the risotto with the note printed under it. |
| 5 | Add at least four more items across Seats 1–4 from Starters/Drinks (e.g. Burrata, Craft IPA, Old Fashioned, Sparkling Water). | ≥ 7 active lines across 4 seats; subtotal, tax, gratuity and total update live. |
| 6 | Click **Fire course 1**. | Course-1 lines change status to `Fired`; the Kitchen badge count increases by 1. |
| 7 | Hover a line → **Void** → choose a reason (e.g. *Guest changed mind*) → **Void item**. | The line is struck through with the reason shown and excluded from the totals. |
| 8 | Click **Split & pay** → **By seat**. | One card per seat with items; each card shows its own tax and 18% gratuity. The verification bar reads `Seat 1 + Seat 2 + Seat 3 + Seat 4 = table total ✓`. |
| 9 | Click **Pay $…** on each seat card, optionally pick a tip, **Charge**. | Each card flips to `Paid`; the header shows `4/4 paid`; **Close table** becomes enabled. |
| 10 | Manually check: sum the four seat totals and compare to the table total. | They match to the cent (tax and gratuity are allocated with largest-remainder rounding). |
| 11 | Click **Receipt** on a paid seat → **Print receipt**. | A thermal-style receipt shows items, modifiers, note, tax, gratuity, tip and amount charged; the print preview contains only the receipt. |
| 12 | Click **Kitchen** in the top bar. | The fired course-1 ticket for Table 4 lists the fired starters with seat numbers (modifiers and notes print on the ticket for the course they belong to). |

## Recording

**Recording:** https://app.devin.ai/attachments/3c4476ce-3b5b-4d70-8e8e-4c4e71101d80/restaurant-pos-showcase.mp4

![Animated preview](https://app.devin.ai/attachments/830e4bc9-5423-43a0-981e-36076ec3f176/restaurant-pos-preview.webp)

Numbers from the recorded run (party of 6 at Table 4, 8 items ordered, 1 voided):

| Seat | Subtotal | Tax 8.875% | Gratuity 18% | Total |
|------|---------:|-----------:|-------------:|------:|
| 1 — Ribeye (medium rare, grilled asparagus +$3), Burrata | $59.00 | $5.24 | $10.62 | $74.86 |
| 2 — Ember Burger (medium, truffle fries +$4), Crispy Calamari | $35.00 | $3.10 | $6.30 | $44.40 |
| 3 — Mushroom Risotto (note), Caesar Salad | $34.00 | $3.02 | $6.12 | $43.14 |
| 4 — French Onion Soup | $10.00 | $0.89 | $1.80 | $12.69 |
| **Table** | **$138.00** | **$12.25** | **$24.84** | **$175.09** |

The four seat totals sum to $175.09, exactly the table total shown in the verification bar.
