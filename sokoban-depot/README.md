# Sokoban Depot: push crates onto targets

A warehouse-themed Sokoban built with Vite + React + TypeScript. Eight hand-made levels of
increasing difficulty (a warm-up plus classic layouts from the freely distributable *Microban*
set), arrow-key / WASD movement, unlimited undo (`Z`), restart (`R`), move and push counters,
a par move count per level with a 1–3 star rating, a level-select screen with minimaps and
sequential unlocking, and progress persisted in `localStorage`. All tiles — brick walls,
wooden crates, the yellow-hard-hat worker, dashed targets — are pixel art drawn with inline
SVG and CSS; there are no external assets and no network calls at runtime.

## Run it

```bash
cd sokoban-depot
npm install
npm run dev
```

Then open the printed `http://localhost:5173` URL. `npm run build` type-checks (strict) and
produces a static bundle in `dist/`; `npm run lint` runs oxlint.

`node scripts/verify-levels.mjs` runs a breadth-first solver over every level to prove it is
solvable and that `par` equals the optimal move count.

Keyboard: `↑ ↓ ← →` or `W A S D` move (and push) · `Z` / `Backspace` undo · `R` restart ·
`Esc` / `L` level select · `Enter` / `Space` / `N` next level after clearing one.

Stars: 3 for finishing at or under par, 2 for at most 1.5× par, 1 for any finish. The best
result per level is kept.

## Notable design decisions

- **Undo is a full state stack, not a reversed move.** Every step pushes the previous
  `GameState` (player, crates, counters) onto a history array, so undo is O(1), exact, and
  also rewinds the move/push counters — which is what makes "backtrack out of a mistake and
  still earn stars" possible.
- **Corner deadlocks are detected and surfaced.** A crate that is off-target and wedged
  against two perpendicular walls can never move again; the crate glows red and a banner
  under the board says to press `Z` or `R`. The player is never blocked from continuing — it
  is a hint, not a game-over.
- **Par values are machine-verified.** `scripts/verify-levels.mjs` is a dependency-free BFS
  solver; the `par` in `src/game/levels.ts` is the optimal move count it reports.
- **Levels unlock sequentially** and progress lives under the `sokoban-depot:progress:v1`
  key, with a *Reset progress* button on the level-select screen.

## Computer-use showcase

This app exists to demonstrate **spatial planning, backtracking with undo, and level
progression**: driving a puzzle purely with the keyboard, recognising a mistake, rewinding it,
and carrying on through a sequence of levels. After building it, Devin opened the app in a
maximised Chrome window and performed the following scenario end to end while recording:

1. Opened the level-select screen (fresh progress: 0 of 8 cleared, levels 2–8 locked) and
   clicked **01 · Loading Dock**.
2. Deliberately made a mistake: pushed the lower crate down against the bottom wall and then
   left into the corner. **Expected:** the crate is outlined red and the "Crate wedged in a
   corner" banner appears.
3. Pressed `Z` four times to rewind past the bad pushes. **Expected:** banner disappears,
   crate returns to its starting cell, move counter drops back to 1.
4. Finished level 1 with the arrow keys. **Expected:** "Level 1 cleared" overlay with
   moves/pushes/par and a star rating (12 moves vs par 10 → 2 stars).
5. Pressed `Enter` to go to level 2 (Two-Bay) and solved it in par (16 moves → 3 stars).
6. Pressed `Enter`, solved level 3 (Corner Store) in par (33 moves → 3 stars).
7. Pressed `Enter`, solved level 4 (Long Haul) in par (23 moves → 3 stars).
8. Pressed `Esc` to return to level select. **Expected:** levels 1–4 show *cleared* badges
   and their stars (2 + 3 + 3 + 3 = 11 / 24), level 5 is unlocked, levels 6–8 remain locked.

### Recording

**[Watch the full recording (mp4)](RECORDING_URL_PLACEHOLDER)**

## Project layout

```
src/
  App.tsx                    screen routing (select ⇄ play), progress wiring
  components/
    LevelSelect.tsx          level cards with minimaps, stars, lock state
    PlayScreen.tsx           board + sidebar, keyboard handling, win overlay
    Board.tsx                absolutely positioned tiles and animated entities
    Sprites.tsx              pixel-art wall / crate / worker drawn as SVG rects
    Stars.tsx                star rating icons
  game/
    levels.ts                the eight levels in classic text format + par
    engine.ts                parse, move/push rules, solved & deadlock checks, stars
    useSokoban.ts            history stack: step / undo / restart
    progress.ts              localStorage persistence and unlock rules
scripts/
  verify-levels.mjs          BFS solver that checks solvability and par
```
