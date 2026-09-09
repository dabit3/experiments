# Sudoku Dojo: solve an 81-cell grid by hand

A polished, client-only Sudoku trainer. It ships with 20 bundled puzzles
(7 easy, 7 medium, 6 hard) stored as 81-character strings, so every puzzle is
deterministic and addressable by URL: `?puzzle=easy-3`, `?puzzle=hard-6`, and
so on. There is no backend and no runtime network access.

Features:

- Click a cell, then type a digit (or use the on-screen number pad).
- Arrow keys move the selection (wrapping at the edges); `Backspace` / `Delete` clears.
- Notes (pencil-mark) mode, toggled with `N` or the notes button.
- Peers (row, column, 3×3 box) and same-digit cells are highlighted.
- Conflicting digits turn red immediately.
- **Check** marks any entered digit that differs from the solution.
- **Hint** fills one correct cell (counts hints used).
- Running timer, remaining-cell progress bar, per-digit remaining counts.
- Celebration overlay with confetti when the grid is solved.

## Run it

```sh
cd sudoku-dojo
npm install
npm run dev        # http://localhost:5173/?puzzle=easy-3
npm run lint       # oxlint
npm run build      # tsc -b && vite build
```

## Computer-use skill showcased

**Sustained deductive puzzle-solving with dozens of precise clicks and digit
keys.** Solving one grid takes ~40 cell selections, each followed by a digit
key, plus arrow-key navigation, mode toggling and reading the board state back
from the screen to decide the next move.

## Browser test scenario

Open `http://localhost:5173/?puzzle=easy-3` in a maximised Chrome window with
screen recording on, then:

| # | Step | Expected result |
|---|------|-----------------|
| 1 | Load `?puzzle=easy-3` | Board shows 40 givens, "41 cells left", timer starts at 00:00 |
| 2 | Click R1C2, press `N`, type `3` `8`; click R2C3, type `2` `3`; press `N` | Both cells show small pencil marks; mode pill toggles "Notes mode" → "Digit mode" |
| 3 | Click R1C4 and type `5` (deliberately wrong) | R1C4, R1C1 and R3C4 turn red; status says a digit repeats |
| 4 | Press `Backspace`, type `6` | Red clears; 6 is accepted |
| 5 | Click R7C2, type `9`, then `→` `6` `→` `2` `→` `4` `→` `5` `→` `7` | Row 7 fills left-to-right using only arrow keys between digits |
| 6 | Fill rows 1–6 by clicking each empty cell and typing its digit | Pencil marks are replaced by digits; peer notes auto-clear |
| 7 | Click **Check** | Status: "All 32 entries are correct. 9 to go." |
| 8 | Select R8C4, click **Hint** (once) | Cell fills with 3 in purple; Hint badge shows 1 |
| 9 | Fill the remaining 8 cells; enter the last digit via the number pad | Celebration overlay appears with confetti, "Puzzle solved!", elapsed time and hint count |

Constraints: solve the whole grid by hand, use Hint at most twice, use arrow
navigation for at least one row, notes mode on at least two cells, and one
corrected conflict.

Recording: https://app.devin.ai/attachments/acb65f42-601e-49cf-8c39-9deed96098a5/sudoku-dojo-showcase.mp4
