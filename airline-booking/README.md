# Contrail Air — airline booking wizard

A six-step flight booking flow built with Vite + React + TypeScript, styled as a real airline
product ("Contrail Air"). Everything runs in the browser with no backend and no network calls:
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

Test card: `4242 4242 4242 4242`, any future expiry, any 3-digit CVV.

## Computer-use showcase

This app exists to demonstrate Devin working through a **long multi-step form with calendar
widgets, autocomplete, a seat map and validation recovery** in a real browser. After building it,
Devin opened the app in a maximised Chrome window and performed this scenario with the mouse and
keyboard while recording:

1. Type `SFO` in **From** and pick San Francisco from the autocomplete; type `JFK` in **To** and
   pick John F. Kennedy.
2. Open the date picker and choose a departure 14 days from today and a return 21 days from
   today (past dates are greyed out and unclickable).
3. Increase **Adults** to 2 and search.
4. On the outbound results, sort by **Price**, filter to **Nonstop**, and choose the fare on the
   cheapest remaining flight (marked "Cheapest"). Repeat for the return leg.
5. Fill in both passengers and the contact details, but give passenger 1 a passport expiry that
   is less than six months after the return date. Submit → the form refuses to continue and shows
   *"Passport must be valid for 6 months after your last flight — expiry must be on or after
   …"* under that field.
6. Fix the expiry and submit again → the seat map opens.
7. Pick two adjacent seats for the two passengers: a window seat and the middle seat next to it
   (e.g. 10A + 10B) on the outbound flight, then the same on the return flight. If a seat is
   already taken on the other leg, "Use the same seats as outbound" says so and asks for a
   replacement.
8. On payment, enter `4242 4242 4242 4242` → the Visa badge and a green check appear; pay.
9. The boarding passes render with QR codes for both passengers on both flights.
10. Click **Download .ics** and inspect the file from the shell — it contains two `VEVENT`
    blocks with the flights' UTC times, seats and booking reference.

Expected result: every step succeeds, the validation error is shown once and cleared after the
fix, the seat map shows seats 1 and 2 side by side, and `contrail-<REF>.ics` lands in the
downloads folder.

### Recording

**[Watch the full recording (mp4)](https://app.devin.ai/attachments/f54e05ce-02c6-4e53-959e-16db42cbdabf/airline-booking-showcase.mp4)**

![Animated preview of the recording](https://app.devin.ai/attachments/9c032140-eb60-4791-adb7-3e951fc509c7/airline-booking-preview.webp)

Recorded run: booking `EMEE9R` — outbound Silverwing SV660 (cheapest nonstop, $263 Basic /
$326 Standard), return Northlight NL121 ($349 / $433), seats 10A+10B and 8A+8B, Visa ending
4242, `contrail-EMEE9R.ics` with two `VEVENT`s and `TRIGGER:-PT3H` alarms.

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
