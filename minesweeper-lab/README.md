# Minesweeper Lab

Classic Minesweeper built with Vite + React + TypeScript, with three levels — Beginner 9×9 / 10
mines, Intermediate 16×16 / 40, Expert 30×16 / 99 — and fully reproducible boards. The board is
generated from `?seed=N` with a mulberry32 PRNG and **first-click safety**: the first clicked cell
and all eight of its neighbours are guaranteed mine-free, so the same seed plus the same first
click always produces the same board. Right-click cycles flag → question mark → clear;
middle-click (or left+right together) on a satisfied number chord-reveals its hidden neighbours;
a mine counter, a timer and a smiley-face reset button sit above the grid; best times per level
are stored in `localStorage`. Losing reveals every mine, highlights the one you hit and crosses
out any wrong flags. Winning flags every remaining mine so the counter reads `000`, freezes the
timer and records the time.

The UI is an original arcade cabinet: a butter-yellow enclosure, mint bevelled tiles, pink
and mint counters, a springy smiley reset button, and a personal best-time strip. Sparky, the
custom SVG bomb mascot, sits beside the condensed wordmark and tactile difficulty buttons.
The cabinet's marquee reacts to wins and losses; a field-clear meter tracks the round.
The How to play dialog explains the mouse and keyboard controls without adding test UI.
Narrow screens stack the controls above the cabinet and allow horizontal scrolling inside
large boards. Reduced-motion preferences are respected.

Outfit and Barlow Condensed fonts are bundled with their SIL Open Font Licenses in
`src/assets/`; the mascot and favicon are original SVGs. No runtime requests leave the app.

## Run it

```bash
cd minesweeper-lab
npm install
npm run dev
```

Then open the printed `http://localhost:5173` URL. Useful query parameters:

- `?seed=1234` — pick the board seed (any non-negative integer; a random one is chosen otherwise).
- `?level=beginner|intermediate|expert` — pick the level (default `beginner`).

The URL is kept in sync as you change level or seed, so it can be copied to replay a board.
`npm run build` type-checks (strict) and produces a static bundle in `dist/`; `npm run lint` runs
oxlint. `node scripts/solve.mjs intermediate 1234 7 7` prints the board for a seed / first click
and reports whether it can be cleared without guessing.

Controls: **left click** reveal · **right click** flag → ? → clear · **middle click** or
**left + right** chord · **face** restart the same seed · **Enter** / **F** reveal / flag the
focused cell. The face button restarts the *same* seed; the shuffle button picks a new random one.

## Computer-use showcase

This app exists to demonstrate Devin driving a real browser with all three mouse buttons —
left-click reveal, right-click flag, middle-click chord — while reading the board and reasoning
probabilistically about where the mines are. After building it, Devin opened
`http://localhost:5173/?level=intermediate&seed=1234` in Chrome, maximized the window, and
performed the following scenario end to end while recording:

1. Confirmed the HUD shows `040` mines, a smiling face and a timer at `000`, and that the
   Intermediate tab (16×16 · 40 mines) is active with seed `1234`.
2. Left-clicked the centre cell (row 7, column 7, zero-indexed) to open the board. Because the
   first click is safe, this always opens the same 15-cell pocket for seed 1234; the timer starts.
3. Worked outwards from the opening by deduction: right-clicked to plant a flag on every cell
   proven to be a mine (the counter decrements per flag), and middle-clicked satisfied numbers to
   chord-reveal their neighbours (the `Chords` stat counts them; dozens in total, well over the
   required two).
4. Continued until all 40 flags were placed (counter `000`) and all 216 safe cells revealed. If a
   mine is hit, the face is clicked to restart the same seed and the run continues.
5. Verified the win state: sunglasses face, mine counter `000`, timer frozen, status line
   "Board cleared. Every mine is flagged.", the "YOU SWEPT IT!" marquee, 100% field cleared,
   and the Intermediate best time saved below the cabinet.

Each step is marked in the recording with a structured annotation (setup / test start /
assertion), so the test script is visible in the video overlay rather than in the app.

Expected results: every one of the 40 mines ends up flagged; the timer stops on the winning click;
the best-times panel shows that time for Intermediate with seed 1234. `scripts/solve.mjs`
confirms this seed / first-click combination is solvable without guessing.

### Recording

**[Watch the annotated arcade showcase (mp4)](https://app.devin.ai/attachments/14816e55-505e-4b72-8b12-8186a9a8235c/minesweeper-lab-showcase.mp4)**

![Animated preview of the arcade showcase](https://app.devin.ai/attachments/8d9e916d-b0b8-4807-a32b-b8ca541003db/minesweeper-lab-preview.webp)

Result: the same-seed retry was won in **102 seconds**, with **41 chords**, **216/216 safe cells**,
and all **40 flags placed manually before victory**. The counter remained `000`, the timer
stayed frozen, and the matching best time survived a reload.

The recording retains the first attempt: an incorrect deduction flagged `(2,9)` and chorded
into the mine at `(2,10)`, losing at 90 seconds. This was a playing error, not an application
defect. The retry used the same seed, as allowed by the scenario. All gameplay used real mouse
input and visible board numbers; no solver, saved mine maps, board internals, Playwright, or
scripted gameplay were used for this recording. It is a replay of a previously played seed,
and the loss visually exposed the mines before the retry.

The MP4 is the recording tool's edited, annotated 1600×1200 capture; the WebP is an 800×600,
4× accelerated preview. Test steps stay in this README and the recording annotations.

### Additional browser checks

All three difficulties, seed Apply/shuffle, first-click safety, face reset, flag/question/clear
cycling, keyboard `F`/`Enter`, and loss/wrong-flag rendering passed. How to play passed open,
close, Escape, Tab/Shift+Tab containment and focus return checks. Best-time persistence was
verified in a second tab to preserve the original win state.

At approximately 390px and 1000px widths, oversized boards scrolled inside the cabinet
without horizontal page overflow. These checks used native Chrome interactions.

## Project layout

```
src/
  App.tsx                 URL <-> level/seed sync, arcade layout, HUD, help dialog
  assets/sparky.svg        original bomb mascot (favicon in public/)
  assets/*.ttf             bundled Outfit and Barlow Condensed fonts with licenses
  components/
    Board.tsx             mouse protocol: left reveal, right flag, middle / both chord
    Cell.tsx              a single cell (numbers, flag, question, mine, wrong flag)
    Counter.tsx           three-digit LED read-out
    Face.tsx              smiley reset button with four moods
  hooks/useGame.ts        reducer: reveal / chord / mark / reset, timer, chord count, best times
  lib/board.ts            seeded mine placement, flood reveal, chord, win/loss checks
  lib/rng.ts              mulberry32 PRNG + seed parsing
  lib/bestTimes.ts        localStorage best-time table
scripts/solve.mjs         prints a seeded board and checks it is solvable without guessing
```
