# The Password Game: rules that stack against you

A clone of the "Password Game" idea, built with Vite + React + TypeScript. There is one
textbox. Rules appear one at a time as the previous ones pass, each as a card that flips
green/red live as you type, with a live readout of the constraint (`digits sum to 34 / 25`,
`product is 525 / 35`, `V 23 + I 53 + … = 174 / 200`, `30 is not prime`). Later rules are
designed to fight earlier ones: the current time adds digits, Roman numerals are also element
symbols, element symbols can be Roman numerals, and the final length has to be prime. A
character counter is always visible, and all 14 rules passing triggers confetti.

The 14 rules, in order:

1. At least 5 characters
2. Include a number
3. Include an uppercase letter
4. Include a special character
5. Digits add up to 25
6. Include a month of the year
7. Include a Roman numeral (uppercase `I V X L C D M`)
8. Include a sponsor: `pepsi`, `starbucks` or `shell`
9. Roman numerals multiply to 35 (each maximal run of Roman letters is one numeral)
10. Include a two-letter chemical element symbol (case-sensitive, e.g. `He`, `Fe`, `Ti`)
11. Include the current time as `HH:MM`, read from the clock widget (24h, re-checked every second)
12. Include today's Wordle answer, read from the solved mini-board (the green row)
13. Atomic numbers of all element symbols in the password add up to 200
14. Length is a prime number

Element symbols are scanned left to right: at each uppercase letter the two-letter symbol
(`Uppercase` + `lowercase`) is tried first, then the single letter. So `VII` counts as
V + I + I = 23 + 53 + 53, and `Cd` is cadmium *and* the Roman numeral C.

Today's Wordle answer is picked deterministically from a bundled word list by the local date
(`daysSince(2021-06-19) % list.length`), so everyone sees the same board on the same day. There
is no backend and no network access at runtime.

## Run it

```bash
cd password-game
npm install
npm run dev
```

Then open the printed `http://localhost:5173` URL. `npm run build` type-checks and produces a
static bundle in `dist/`; `npm run lint` runs oxlint.

## Computer-use showcase

**Skill: iterative constraint satisfaction in a single text field with live validation.**
Every rule is checked on every keystroke, so satisfying rule N regularly breaks rule N-k. Devin
has to read the live cards (and the clock and Wordle widgets), decide what to add or change,
edit the right part of the text with the mouse and keyboard, and re-read the cards until all
14 are green.

### Browser test scenario

Devin opened the app in a maximized Chrome window and performed this scenario end to end
with mouse and keyboard while recording. The exact time and Wordle word depend on the day and
minute the scenario is run; the structure is always the same.

1. Type `pepsi` → rule 1 passes (the sponsor rule will pass for free later). Rule 2 appears.
2. Append `7` → rule 2 passes. Append `V` → rule 3 passes (and it is a Roman numeral).
   Append `!` → rule 4 passes. Rule 5 appears: digits sum to 7 / 25.
3. Append `99` → digits sum to 25, rule 5 passes. Append `may` → rule 6 passes.
4. Rule 7 (Roman numeral) and rule 8 (sponsor) pass immediately from `V` and `pepsi`;
   rule 9 appears red: product is 5 / 35. Append `VII` → runs `V` and `VII`, product 35.
5. **Break #1.** Rule 10 wants a two-letter element. Append `Cd` → rule 10 turns green but
   rule 9 turns red (`C` is a Roman numeral, so `VIICd` reads as `VIIC` = 105 → product 525).
   Repair: replace `Cd` with `Ti` → rules 9 and 10 both green.
6. **Break #2.** Rule 11 wants the time from the clock widget. Append it (e.g. `13:05`) →
   rule 11 turns green but rule 5 turns red (the time's digits push the sum above 25).
   Repair: shrink the earlier digits (e.g. `99` → `9`) until the sum is 25 again.
7. Rule 12 wants the Wordle answer: read the green row of the mini-board and append it.
8. Rule 13 wants atomic numbers to sum to 200. Read the running total on the card
   (V 23 + V 23 + I 53 + I 53 + Ti 22 = 174) and append the missing element (`Fe` = 26).
9. Rule 14 wants a prime length. Read the counter; if the length is not prime, append `!`
   until it is.
10. Expected result: all 14 cards green, `14 / 14 rules passed`, the "Password accepted"
    banner and confetti.

### Recording

**Recording (mp4): RECORDING_LINK_PLACEHOLDER**

## Project layout

```
src/
  App.tsx                    password state, rule reveal cascade, layout
  rules.ts                   the 14 rules and their live checks
  data/elements.ts           118 element symbols + left-to-right symbol scanner
  data/wordle.ts             bundled answers, deterministic daily pick, tile scoring
  components/RuleCard.tsx    green/red rule card with live detail
  components/ClockWidget.tsx HH:MM:SS clock the time rule reads from
  components/WordleBoard.tsx solved mini-board the Wordle rule reads from
  components/Confetti.tsx    canvas confetti on completion
```
