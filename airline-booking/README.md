# Contrail Air — airline booking wizard

A six-step flight booking flow built with Vite + React + TypeScript, styled as a real airline
product ("Contrail Air"): a dark navy design system with self-hosted Manrope / Instrument Serif /
JetBrains Mono type, animated step transitions, a live card preview and printable boarding
passes. Everything runs in the browser with no backend and no network calls:
the 60-airport list, the schedules, the taken seats and the booking references are all bundled
and generated deterministically, so the same search always produces the same flights.

1. **Search** — origin/destination autocomplete over 60 bundled airports (matches code, city,
   airport name or country), round-trip / one-way toggle, a two-month date-range calendar with
   past dates blocked, and adult/child passenger steppers.
2. **Flights** — per-leg results with sort (departure / price / duration), stop filter,
   departure-window filter and a max-price slider; each flight expands into Basic / Standard /
   Flex fare cards. Round trips pick the outbound first, then the return.
3. **Passengers** — a full form for every passenger plus contact details. Validation is
   realistic: names, ISO dates, passport number, date of birth must match the adult (12+) or
   child (2–11) slot, and the passport must be valid for six months after the last flight.
   Errors appear inline and the first invalid field is scrolled into view and focused.
4. **Seats** — an interactive 3-3 seat map with 30 rows for each leg. Some seats are already
   taken (seeded by flight id), rows 1–3 cost +$12, exit rows 14–15 cost +$24, and each
   passenger gets their own seat colour. A shortcut copies the outbound seats to the return
   flight when they are free.
5. **Payment** — checked bags / insurance / priority boarding / Wi-Fi extras, then a card form
   with live brand detection (Visa, Mastercard, Amex, Discover), Luhn checksum validation,
   expiry and CVV checks. The trip summary in the sidebar updates as extras change.
6. **Boarding passes** — a confirmation banner, one boarding pass per passenger per flight with
   gate, boarding time, group and a QR code (generated with the `qrcode` package from an
   IATA-style BCBP string), a "Download .ics" button that writes both flights (with a 3-hour
   reminder alarm) to a calendar file, and a print stylesheet.

Progress is kept in `localStorage`, so a reload lands you on the step you left.

## Run it

```bash
cd airline-booking
npm install
npm run dev
```

Open the printed `http://localhost:5173` URL. `npm run build` type-checks (strict) and bundles to
`dist/`; `npm run lint` runs oxlint.

Any Luhn-valid card number is accepted (e.g. Stripe's `4242 4242 4242 4242` test Visa), with
any future expiry and a 3-digit CVV (4 for Amex).

## Computer-use test

This app exists to demonstrate Devin working through a **long multi-step form with calendar
widgets, autocomplete, a seat map and validation recovery** in a real browser. The scenario is
not part of the app — it lives in the repo as an agent skill that runs in Devin's computer-use
environment:

```
.agents/skills/airline-booking-e2e/
  SKILL.md        the test: setup, 6 "It should…" blocks with assertions, teardown/report
  verify-ics.sh   shell oracle for the downloaded calendar file
```

Invoke it with `/airline-booking-e2e` (Devin also picks it up automatically for changes under
`airline-booking/`). The skill drives the wizard with mouse and keyboard only — no
Playwright, CDP or DOM injection — in a maximised Chrome window, with screen recording and
structured `test_start` / `assertion` annotations, and takes 6–8 full-screen screenshots.
In short it books SFO → JFK for 2 adults departing 14 and returning 21 days from today, sorts
by price, filters to nonstop and takes the cheapest fare on both legs, fills both passengers
(triggering and then fixing the passport-expiry rule), seats them in adjacent window + middle
seats on both flights, pays with `4242 4242 4242 4242` (Visa detected, Luhn OK), reaches the
four QR boarding passes and downloads the `.ics`.

`verify-ics.sh <file> [REF]` unfolds the RFC 5545 file and checks: exactly two `VEVENT`s, two
`TRIGGER:-PT3H` display alarms, the booking reference in both UIDs and descriptions,
SFO → JFK / JFK → SFO summaries and locations, nonstop flights, UTC start < end, chronological
order, future dates, and that both legs seat the two passengers in the same row as window +
middle (A+B or E+F). It exits non-zero on any failure, so the run cannot pass with a bad file.

### Recordings

**[Watch the full recording (mp4)](https://app.devin.ai/attachments/24a00b87-f4fd-4b45-9c1e-653dc48701a3/airline-booking-v2-edited.mp4)**

![Animated preview of the recording](https://app.devin.ai/attachments/d464830e-74fd-4cf4-b3fe-c401002a0b44/airline-booking-v2-preview.webp)

Recorded run: booking `UCEU2F` — outbound Silverwing SV660 (cheapest nonstop, $263 Basic /
$326 Standard), return Northlight NL121 ($349 / $433), seats 10A+10B and 8A+8B, Visa ending
4242, `contrail-UCEU2F.ics` with two `VEVENT`s and `TRIGGER:-PT3H` alarms.

Earlier run on the first visual pass:
[mp4](https://app.devin.ai/attachments/f54e05ce-02c6-4e53-959e-16db42cbdabf/airline-booking-showcase.mp4).

## Project layout

```
src/
  App.tsx                       wizard state, step transitions, persistence
  components/
    steps/SearchStep.tsx        airports, dates, passenger counts
    steps/ResultsStep.tsx       sort/filter, fare cards, outbound → return
    steps/PassengersStep.tsx    per-passenger forms + contact
    steps/SeatsStep.tsx         seat map for each leg
    steps/PaymentStep.tsx       extras + card form
    steps/ConfirmationStep.tsx  boarding passes, .ics download, print
    AirportAutocomplete.tsx     combobox over the bundled airport list
    DateRangePicker.tsx         two-month range calendar
    BoardingPass.tsx            pass layout + QR code
    TripSummary.tsx             sidebar price breakdown
  data/airports.ts              60 airports with time zones
  data/flights.ts               deterministic schedule generator
  lib/                          dates, validation (Luhn, passport rule), seats, pricing, ICS
```
