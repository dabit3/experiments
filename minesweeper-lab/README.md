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

The UI is a dark, console-style layout: a glass masthead with the app icon, a segmented level
switcher and the seed control; a game panel with LED counters, the face button, the board and a
status/stat bar; and a sidebar with the **Test scenario** panel (the browser test script below,
rendered as a live checklist that ticks itself off as you play), best times and a controls
legend.

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

1. Confirmed the HUD shows `040` mines, a smiling face and a timer at `000`, that the
   Intermediate tab (16×16 · 40 mines) is active with seed `1234`, and that the **Test scenario**
   panel reads `READY` with step 1 already ticked.
2. Left-clicked the centre cell (row 7, column 7, zero-indexed) to open the board. Because the
   first click is safe, this always opens the same 15-cell pocket for seed 1234. The panel flips
   to `RUNNING` and ticks step 2.
3. Worked outwards from the opening by deduction: right-clicked to plant a flag on every cell
   proven to be a mine (step 3 counts `n/40`), and middle-clicked satisfied numbers to
   chord-reveal their neighbours (step 4 counts chords; dozens in total, well over the required
   two).
4. Continued until all 216 safe cells were revealed (step 5 counts `n/216`). If a mine is hit the
   panel turns `FAILED` and tells you to restart the same seed via the face button.
5. Verified the win state: sunglasses face, mine counter `000`, timer frozen, status line
   "Board cleared. Every mine is flagged.", the scenario panel reading `PASSED · 6/6 steps`, and
   the Intermediate best time saved in the sidebar.

Expected results: every one of the 40 mines ends up flagged; the timer stops on the winning click;
the scenario panel shows `PASSED`; the best-times panel shows that time for Intermediate with seed
1234. `scripts/solve.mjs` confirms this seed / first-click combination is solvable without
guessing.

### Recording

**[Watch the full recording (mp4)](https://app.devin.ai/attachments/674b2674-6ed7-41a8-94b5-bfb1751d5aaa/minesweeper-lab-showcase.mp4)**

![Animated preview of the showcase run](https://app.devin.ai/attachments/1f380690-a5a5-49c9-b950-ebf42f2b7fa5/minesweeper-lab-preview.webp)

Result: the recorded game was won with the timer stopping at 92 s, the mine counter at `000`, all
40 flags placed by hand and 44 chord reveals, with the scenario panel reading `PASSED`. The first
attempt in the same recording mis-flagged a cell and chorded into a mine; the loss state (all
mines revealed, the hit mine highlighted, the wrong flag crossed out, panel `FAILED`) is shown,
after which the board was restarted with the same seed via the face button and cleared.

## Project layout

```
src/
  App.tsx                 URL <-> level/seed sync, layout, HUD, sidebar
  assets/app-icon.webp    app icon shown in the masthead (favicon in public/)
  components/
    Board.tsx             mouse protocol: left reveal, right flag, middle / both chord
    Cell.tsx              a single cell (numbers, flag, question, mine, wrong flag)
    Counter.tsx           three-digit LED read-out
    Face.tsx              smiley reset button with four moods
    Scenario.tsx          the test scenario as a live checklist driven by game state
  hooks/useGame.ts        reducer: reveal / chord / mark / reset, timer, chords, best times
  lib/board.ts            seeded mine placement, flood reveal, chord, win/loss checks
  lib/scenario.ts         level / seed / min-chords of the showcase scenario
  lib/rng.ts              mulberry32 PRNG + seed parsing
  lib/bestTimes.ts        localStorage best-time table
scripts/solve.mjs         prints a seeded board and checks it is solvable without guessing
```
