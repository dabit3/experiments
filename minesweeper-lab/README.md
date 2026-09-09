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
focused cell. The face button restarts the *same* seed; **Shuffle** picks a new random one.

## Computer-use showcase

This app exists to demonstrate Devin driving a real browser with all three mouse buttons —
left-click reveal, right-click flag, middle-click chord — while reading the board and reasoning
probabilistically about where the mines are. After building it, Devin opened
`http://localhost:5173/?level=intermediate&seed=1234` in Chrome, maximized the window, and
performed the following scenario end to end while recording:

1. Confirmed the HUD shows `040` mines, a smiling face and a timer at `000`, and that the
   Intermediate tab (16×16 · 40 mines) is active with seed `1234`.
2. Left-clicked the centre cell (row 7, column 7, zero-indexed) to open the board. Because the
   first click is safe, this always opens the same 15-cell pocket for seed 1234.
3. Worked outwards from the opening by deduction: right-clicked to plant a flag on every cell
   proven to be a mine, and middle-clicked satisfied numbers to chord-reveal their neighbours
   (dozens of chord clicks in total, well over the required two).
4. Continued until all 216 safe cells were revealed. The game flags the remaining mines itself.
5. Verified the win state: sunglasses face, mine counter `000`, timer frozen, status line
   "Cleared! Every mine is flagged.", and the Intermediate best time saved in the sidebar.

Expected results: no mine is ever hit; every one of the 40 mines ends up flagged; the timer stops
on the winning click and the best-times panel shows that time for Intermediate with seed 1234.
`scripts/solve.mjs` confirms this seed / first-click combination is solvable without guessing.

### Recording

**[Watch the full recording (mp4)](https://app.devin.ai/attachments/ba4a1426-ecdd-4792-b1be-4dbe56d4429b/minesweeper-lab-showcase.mp4)**

![Animated preview of the showcase run](https://app.devin.ai/attachments/db2e6e0e-25e9-48fa-b0ea-adecc358fbf8/minesweeper-lab-preview.webp)

Result: the recorded game was won with the timer stopping at 145 s and the mine counter at `000`.
An earlier attempt on the same seed hit a mine; the loss state (all mines revealed, the hit mine
highlighted, wrong flags crossed out) is captured in the PR screenshots, after which the board was
restarted with the same seed and cleared.

## Project layout

```
src/
  App.tsx                 URL <-> level/seed sync, layout, HUD, sidebar
  components/
    Board.tsx             mouse protocol: left reveal, right flag, middle / both chord
    Cell.tsx              a single cell (numbers, flag, question, mine, wrong flag)
    Counter.tsx           three-digit LED read-out
    Face.tsx              smiley reset button with four moods
  hooks/useGame.ts        reducer: reveal / chord / mark / reset, timer, best times
  lib/board.ts            seeded mine placement, flood reveal, chord, win/loss checks
  lib/rng.ts              mulberry32 PRNG + seed parsing
  lib/bestTimes.ts        localStorage best-time table
scripts/solve.mjs         prints a seeded board and checks it is solvable without guessing
```
