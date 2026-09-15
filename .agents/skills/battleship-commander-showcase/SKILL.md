---
name: battleship-commander-showcase
description: Computer-use regression test for battleship-commander. Drives the real UI in maximised Chrome (drag placement, R rotation, seed-8 battle, heatmap) while recording with structured annotations; the annotated mp4 is the test artifact.
---

# Battleship Commander — annotated computer-use test

Run this whenever `battleship-commander/` changes. The test is the README's
"Browser test scenario" executed for real with mouse + keyboard, recorded, and
annotated so the video doubles as the pass/fail report. Do **not** script the
interactions (no Playwright/CDP) — the point is to exercise the app the way a
person would.

## Setup

```sh
cd battleship-commander
npm install            # only if node_modules is missing
npm run lint && npm run build
npm run dev            # serves http://localhost:5173
```

Maximise Chrome before recording:

```sh
wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
```

Start a recording, then open `http://localhost:5173/?seed=8`.
Capture the illustrated arcade title screen, then click **Take command**.
Expected: the mission opens in placement mode with the same URL seed.

## Annotate as you go

Use the recording annotation tool at every step below. Exactly this shape:

| When | type | value |
|---|---|---|
| after the page loads | `setup` | `Opening Battleship Commander at ?seed=8 in maximised Chrome` |
| before dragging | `test_start` | `It should place all five ships by dragging, rotating two with R` |
| after the dock reads 5 / 5 placed | `assertion` (passed/failed) | `5/5 placed; two ships rotated vertical via R, Start battle enabled` |
| before the first shot | `test_start` | `It should complete a seed-8 battle using the probability heatmap` |
| after the first sunk banner | `assertion` | `Target mode after first hit; <ship> sunk with banner and log entry` |
| when the end screen appears | `assertion` | `Victory in N shots, X% accuracy, 5/5 sunk vs AI M/5; mission report shown` (or the actual Defeat statistics) |

If a step cannot be executed, record the assertion with `untested` and say why
in the final report — never mark it passed.
Try to win, but a defeat with correct game behavior is not a failed application
assertion. On defeat, complete the one required rematch and report both outcomes.

## Steps and expected results

1. **Placement.** Drag each of the five ships from the dock onto *Your fleet*
   with press-move-release (not a click). Press `R` while dragging the Carrier
   and again while dragging the Cruiser so both land vertical. Expected: green
   preview on legal cells, red on illegal; all five dock cards show `DEPLOYED`,
   the badge reads `5/5 placed`, and *Start battle* is enabled. Placed ships
   can be re-dragged. Dock cards retain their positions after deployment.
2. **Start battle.** Click *Start battle*. Expected: the dock is replaced by the
   heatmap card, fleet status and shot log; status pill says it is your turn.
3. **Opening shot + heatmap.** Fire one shot in *Enemy waters*, then switch on
   *Probability heatmap* and leave it on. Expected: gold shading with `%`
   labels on the warmest cells and a pulsing *best guess*; the badge reads
   `HUNT` if the opening shot missed, `TARGET` if it hit.
4. **Hunt → target.** Keep firing at the best guess. Expected: the first hit
   flips the badge to `TARGET`, the shading favors cells around the hit
   (then the line through aligned hits), and following it sinks the ship with a "You sank the enemy …!" banner,
   dark-red sunk cells and a struck-through row in *Enemy fleet*.
5. **Two boards.** After each of your shots the AI fires at *Your fleet* about
   a second later. Expected: hits/misses animate on your board, the AI's
   entries interleave with yours in the shot log, and your fleet's segment
   indicators fill in as ships are damaged.
6. **Finish.** Play until the overlay appears. Expected: crest, `Mission report
   · Game 01 · Seed 8`, VICTORY or DEFEAT, a You / Enemy AI table (shots, hits,
   accuracy, ships sunk), *Rematch (same seed)* and *Edit fleet* buttons.
7. **Rematch (only on defeat).** Click *Rematch (same seed)* once and play to a
   second result. Expected: same enemy layout, same player fleet, `Game 02`.

## Determinism oracle for seed 8

The enemy layout for `?seed=8` is fixed; use it to check the app, not to play
the showcase by looking up hidden ships. Pick shots using only the visible
heatmap, hits and misses during the recorded game. Use this table only for a
separate determinism check, and investigate any mismatch before assigning blame.

| Ship | Cells |
|---|---|
| Carrier (5) | D1 D2 D3 D4 D5 |
| Battleship (4) | B7 C7 D7 E7 |
| Cruiser (3) | G6 G7 G8 |
| Submarine (3) | D8 E8 F8 |
| Destroyer (2) | B1 C1 |

Consequences you can assert directly: `E5` is always a miss and `D5` is
always a hit. After a hit at `D5` with no other shots the badge reads `TARGET`
and the best guess is one of its orthogonal neighbours (`C5`, `D4`, `D6`,
`E5`) — ties are broken by scan order, so do not assert a single cell.

## Artifacts

- Stop the recording with a title/summary that leads with pass or fail.
- Take 4–8 full-screen screenshots (title screen, placement, 5/5 placed,
  heatmap on, target mode, first sunk, both boards active, end screen).
- Report: result, shots/accuracy from the end screen, any UI defects, and the
  paths of the mp4 and screenshots so they can be attached to the PR.
