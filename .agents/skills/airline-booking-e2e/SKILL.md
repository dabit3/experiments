---
name: airline-booking-e2e
description: Drive the Contrail Air booking wizard (airline-booking/) end-to-end in a real, maximised Chrome window using computer use — mouse and keyboard only — and record the run with structured annotations. Use after changing anything in airline-booking/, or when asked to test, demo, or re-record the airline booking app.
---

# airline-booking end-to-end computer-use test

This is the integration test for `airline-booking/`. It is executed by an agent in the
computer-use environment, not by a script: every step is performed with the mouse and
keyboard in Chrome, and every assertion is a visible UI state. **Never** use Playwright,
CDP, `browser_console`, or DOM injection to perform or short-cut a step. The shell is only
for setup, verifying the downloaded calendar file, and producing the artifacts (ffmpeg).
Browser zoom (`ctrl+minus`) and scrolling are fine for inspecting long lists.

Result contract: the run **passes** only if every assertion in the "Scenario" section is
observed. If a step is impossible, mark its assertion `untested`/`failed` and report why —
never mark a step passed that did not happen. App bugs found along the way get fixed, then the
whole scenario is re-run from step 0.

## Setup

1. Install and start the app (leave the server running in its own shell):
   ```bash
   cd airline-booking && npm install && npm run dev -- --host 127.0.0.1 --port 5173
   ```
   Wait for `http://127.0.0.1:5173` (or `http://localhost:5173`) to respond.
2. Compute the scenario dates and remember them (the app blocks past dates, so the scenario
   is always relative to *today*):
   ```bash
   date +%F; date -d '+14 days' '+%F (%a %b %-d)'; date -d '+21 days' '+%F (%a %b %-d)'
   ```
3. Chrome must already be running. Maximise it and clear any previous booking state:
   ```bash
   wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
   ```
   Open `http://localhost:5173` (always type the scheme). If the wizard is not on step 1
   ("Where to next?"), click **Start over** in the top bar.
4. Make sure the Downloads folder does not already contain a `contrail-*.ics` (delete old ones)
   so the file produced by this run is unambiguous.
5. Start a screen recording (`recording_start`, e.g. `recording_id=airline-booking-e2e`) and add
   a `setup` annotation such as "Contrail Air dev server on :5173, Chrome maximised".

## Scenario

Use `annotate_recording` with `test_start` at the beginning of each numbered block below and
an `assertion` (passed/failed/untested) for each **Assert** line. At each **Screenshot**
marker take a screenshot of the whole desktop (not a full-page capture; uncropped) and copy
it under `~/showcase/airline-booking-e2e/` with the given name (6–8 in total).

Dates and expiries are relative to *today* so the scenario never rots: `D` = departure
(+14 days), `R` = return (+21 days), `Y` = current year.

### 1. It should search SFO → JFK for 2 adults with dates 14 and 21 days out

- Click **From**, type `SFO`, pick *San Francisco International* from the dropdown.
- Click **To**, type `JFK`, pick *John F. Kennedy International*.
- Click the **Dates** field. In the calendar popover:
  - **Assert** the days before today in the current month are greyed out and one of them does
    nothing when clicked (click it to prove it; **Previous month** is disabled). If today is
    the 1st there is no past cell — mark this assertion `untested` with that reason.
  - Click the date 14 days from today (use **Next month** if it is in the following month),
    then the date 21 days from today.
  - **Assert** the Depart / Return fields show those two dates.
- Click **+** next to *Adults* once so it reads **2**. Leave *Children* at 0.
- **Screenshot** `01-search.png` (calendar or completed form).
- Click **Search flights**.
- **Assert** the Flights step opens with eyebrow *Step 2 · Outbound flight*, heading
  *San Francisco → New York*, the departure date and *2 passengers*.

### 2. It should sort by price, filter to nonstop and pick the cheapest nonstop flight on both legs

- In **Sort by**, click **Price**. **Assert** the card prices are ascending top-to-bottom.
- In **Stops**, click **Nonstop**. **Assert** every remaining card says *Nonstop* and the first
  card carries the **Cheapest** badge.
- Click **Select** on the first card, then **Choose** the *Standard* fare (the "Most popular"
  card). Note the flight number and price.
- **Assert** the page switches to *Return flight* (*New York → San Francisco*, return date),
  an *Outbound selected* banner names the chosen flight, and the sidebar **Your trip** shows
  the outbound flight and fare.
- Repeat sort **Price** → **Nonstop** → first card **Select** → *Standard* on the return leg.
- **Screenshot** `02-results.png` before choosing the return fare.
- **Assert** the Passengers step opens with two passenger cards (*Passenger 1 · Adult*,
  *Passenger 2 · Adult*) and a Contact details block.

### 3. It should reject a short passport expiry, then accept the corrected form

Fill both passengers by clicking each field and typing (Tab is fine between fields):

| Field | Passenger 1 | Passenger 2 |
|---|---|---|
| Title | Ms | Mr |
| First / last name | Avery / Nakamura | Jordan / Nakamura |
| Date of birth | 1988-04-12 | 1990-09-30 |
| Nationality | United States | United States |
| Passport number | X1234567 | Y7654321 |
| Passport expiry | **R + 2 months** (deliberately invalid) | `Y+5`-06-15 |

Contact: email `avery@example.com`, phone `+1 415 555 0142`.

- Click **Continue to seats**.
- **Assert** the form does *not* advance; a banner reads *Please fix 1 issue below to
  continue* and Passenger 1's expiry field shows *Passport must be valid for 6 months after
  your last flight — expiry must be on or after &lt;return date + 6 months&gt;*. The field is
  focused/scrolled into view.
- **Screenshot** `03-passport-error.png`.
- Replace Passenger 1's expiry with `Y+4`-11-20. **Assert** the inline error clears.
- Click **Continue to seats**. **Assert** the Seats step opens on the *Outbound* leg with a
  30-row, 3-3 map (aisle gap between C and D, EXIT markers at rows 14–15).

### 4. It should seat both passengers in adjacent window + middle seats on both legs

- With *Passenger 1* active (highlighted in the Passengers panel), click seat **10A**. If 10A
  or 10B is already taken (grey), use the lowest row ≥ 6 where both A and B are free and read
  `NA`/`NB` below as that row.
- **Assert** 10A takes Passenger 1's colour and the active passenger flips to *Passenger 2*.
- Click **10B**. **Assert** 10A and 10B are shown side by side in two colours and the
  Passengers panel lists `10A` and `10B`.
- **Screenshot** `04-seat-map.png`.
- Click **Continue to return flight** (or the *Return* leg tab), then **Use the same seats as
  outbound**.
  - If a notice says a seat is taken on the return flight, only the free seat is copied: click
    *Passenger 1* in the panel, then pick a replacement adjacent window+middle pair (e.g. 8A +
    8B) for both passengers.
- **Assert** both passengers have a window (A/F) and the neighbouring middle (B/E) seat on the
  return leg and the sidebar shows non-zero *Seat fees* only if a paid row was used.
- Click **Continue to payment**.

### 5. It should detect Visa, pass Luhn and issue boarding passes

- Toggle **Travel insurance** on. **Assert** the sidebar *Total* increases.
- Card holder `Avery Nakamura`; card number `4242 4242 4242 4242`.
  - **Assert** the hint changes to *Visa detected*, the Visa badge lights up, the live card
    preview shows the number groups, and a green check appears at the end of the input.
- Expiry `08/` + last two digits of `Y+3`, CVV `314`, ZIP `94110`. **Screenshot**
  `05-payment.png`.
- Click **Pay …** (the button shows the total). A *Processing…* spinner shows for about a
  second (too brief for a screenshot; it is visible in the recording, not an assertion).
  **Assert** the Confirmation step: *Booking confirmed*, a 6-character **Booking reference**,
  and four boarding passes (2 passengers × 2 flights) each with a rendered QR code, seat, gate
  and group (zoom out or scroll to see all four).
- **Screenshot** `06-boarding-passes.png`. Note the booking reference `<REF>`.

### 6. It should download a valid .ics with both flights and 3-hour alarms

- Click **Download .ics**. **Assert** the toast *Calendar file saved — 2 flights added with a
  3-hour reminder.* appears.
- From the shell, verify the file (the script prints the file and exits non-zero on any
  failed check):
  ```bash
  .agents/skills/airline-booking-e2e/verify-ics.sh "$HOME/Downloads/contrail-<REF>.ics" <REF>
  ```
- **Assert** the script exits 0 and reports `PASS` (2 `VEVENT`s, 2 `TRIGGER:-PT3H`, reference,
  SFO/JFK and both seat pairs present). Then run the same command in a maximised terminal
  window (shrink the font if needed so the whole calendar and the PASS line fit) —
  **Screenshot** `07-ics.png`.

## Teardown and report

1. `recording_stop` with a title like *Contrail Air booking E2E* and a summary that leads with
   pass/fail.
2. Build the animated preview (≤ 15 MB) from the edited recording:
   ```bash
   ffmpeg -y -i <recording>.mp4 -vf "setpts=PTS/2.5,fps=10,scale=720:-2" -loop 0 \
     -c:v libwebp -lossless 0 -q:v 55 -preset picture -an airline-booking-preview.webp
   ```
3. Report: verdict, the booking reference, the recording path, the webp path, the screenshot
   paths, and the `verify-ics.sh` output. List any assertion that was not `passed` with the
   reason and, if a bug was fixed during the run, what changed.
