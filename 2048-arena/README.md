# 2048 Arena: reach the 512 tile

A polished 2048 clone built to be driven by rapid keyboard input. Slide tiles on a
4×4 grid, merge equal numbers, and reach the **512** tile. Every run is
reproducible: the tile spawns come from a seeded RNG, so `?seed=99` always
produces the same game for the same sequence of moves.

Features:

- Smooth tile slide / merge / spawn animations, all **90 ms** so keys can be sent
  back-to-back without waiting.
- Score and persisted best score (`localStorage`).
- **Undo up to 5 moves** (`Z`, `Backspace`, or `Ctrl`/`Cmd`+`Z`). Undo restores
  the RNG state too, so redoing the same move spawns the same tile.
- Deterministic RNG from `?seed=N` (mulberry32). "Restart seed" replays the same
  seed from scratch; "New game" picks a fresh seed and writes it to the URL.
- "You reached 512!" and "Game over" banners with Keep going / Undo / New game
  actions.
- Arrow keys and WASD on desktop, swipe gestures on touch screens.
- No backend, no network calls, everything is bundled.

## Run it

```sh
cd 2048-arena
npm install
npm run dev        # http://localhost:5173
```

`npm run lint` (oxlint) and `npm run build` (strict `tsc -b` + Vite) must pass.

`node scripts/simulate.mjs 99` plays a seed headlessly with the naive
left/down/right/up loop to sanity-check the engine.

## Computer-use skill showcased

**Long sequences of arrow-key input while continuously re-reading a changing
grid.** The agent has to fire many arrow-key presses, look at the board after
each burst, decide the next moves from the new tile layout (corner strategy),
notice when a move went wrong, and recover with undo.

## Browser test scenario

Run `npm run dev`, then in a maximised Chrome window:

| # | Step | Expected result |
|---|------|-----------------|
| 1 | Open `http://localhost:5173/?seed=99` | Board shows two starting tiles, Score 0, seed field reads `99`, Undo shows `0/5` and is disabled. |
| 2 | Play with arrow keys using a corner strategy (keep the biggest tile in the bottom-left; mostly `←` and `↓`, `→`/`↑` only when nothing else moves) | Tiles slide and merge with sub-120 ms animations; Score and "Highest tile" status update after every move; Undo counter climbs to `5/5`. |
| 3 | Make a bad move (e.g. `↑` that pulls the big tile out of the corner), then press `Z` | The board, score and move counter return to the exact state before the bad move; the Undo counter drops by one. |
| 4 | Keep playing until a 512 tile appears | A gold "You reached 512!" banner covers the board with the final score, plus Keep going / New game buttons. |
| 5 | Reload `?seed=99` and replay the same moves | Identical tiles spawn in identical places — the run is reproducible. |

Recording: https://app.devin.ai/attachments/18d992b6-2c3c-414c-9510-6b450a29c594/2048-arena-showcase-edited.mp4

Result of the recorded run: 512 tile reached at move 280 with a final score of
4,252 (seed 99, bottom-left corner strategy, one deliberate bad `→` move
recovered with `Z`).
