# Prove You're a Robot

A tongue-in-cheek **reverse CAPTCHA**: a five-stage gauntlet in which a robot has to prove that it
is *not* a human, built with Vite + React + TypeScript. Every challenge demands the kind of
pixel-precise mouse work that CAPTCHAs use to trip up bots — a slider that must land within 4 px,
a dial that must be released within 5°, a "select every traffic cone" grid, a jigsaw piece that
has to drop into its exact hole, and a winding corridor that has to be traced with the button held
down. Pass all five and you are issued a certificate — **Certified Robot #\<seed\>** — with a
printable view.

Everything on screen is generated inline SVG (landscape, robot, tiles, jigsaw cut, corridor), so
there are no external assets and no network calls at runtime. All content is derived from
`?seed=N` with a small deterministic PRNG, so a given seed always produces the exact same gauntlet
and a recorded run can be replayed step for step.

## Run it

```bash
cd prove-youre-a-robot
npm install
npm run dev
```

Then open the printed `http://localhost:5173` URL and add `?seed=5` (or any non-negative integer;
the seed defaults to `1`). `npm run build` type-checks and produces a static bundle in `dist/`;
`npm run lint` runs oxlint.

## The five stages

| # | Stage | What you do | Pass condition |
|---|-------|-------------|----------------|
| 1 | **Slide** | Drag a slider handle so the cut-out puzzle piece glides horizontally into the notch in the picture. | Piece x within **±4 px** of the notch on release. |
| 2 | **Rotate** | Drag a knob around a dial to rotate a tilted picture until the horizon is level and the robot stands up. | Image within **±5°** of upright on release. |
| 3 | **Select** | Click every tile in a 4×4 grid of generated SVG scenes that contains an orange traffic cone, then press *Verify*. Barrels, hydrants, mailboxes, benches, lamps and trees are decoys. | Exactly the cone tiles selected, no misses, no extras. |
| 4 | **Jigsaw** | Pick up a jigsaw piece from the tray and drop it into the hole cut out of the picture. | Piece within **±6 px** of the hole on each axis. |
| 5 | **Trace** | Press on START, follow a winding corridor with the mouse button held down, and release on END. | Cursor never leaves the 44 px-wide corridor and the button is released on END after covering the whole path. |

Failing a stage shows a red **REJECTED** banner with the exact miss (e.g. *"Piece released 164 px
short of the notch"*), bumps the attempt counter, resets the stage, and lets you retry
immediately. Passing shows a green **VERIFIED** banner, locks the stage, fills its segment of the
progress bar and enables *Continue*. Feedback is purely visual — the app makes no sound. The
certificate lists seed, elapsed time, attempts per stage and a checksum, and *Printable
certificate* switches it to a white paper layout with a *Print* button (`@media print` hides all
other chrome).

## Computer-use skill

**Pixel-precise mouse manipulation**: slider puzzles, rotation dials, tile selection, jigsaw
drag-and-drop and path tracing with the button held down. The tolerances are deliberately tight
(4 px, 5°, 6 px, 22 px corridor half-width) so the stages can only be passed by placing and
releasing the pointer accurately; each stage exposes a small telemetry line (`piece.x`, `dial`,
`piece @ (x, y)`, `trace %`) so the operator can verify a position before letting go.

## Browser test scenario

Run with `npm run dev`, open `http://localhost:5173/?seed=5` in a maximized Chrome window and:

1. Click **Begin verification**.
   *Expected:* Stage 1 of 5 appears with the piece parked at the left edge (`piece.x = 8`).
2. **Deliberately fail stage 1:** drag the slider handle part of the way and release well short
   of the notch.
   *Expected:* red **REJECTED** banner reporting how many px short the piece was, attempt counter
   becomes 2, the piece snaps back to the start.
3. Drag the handle again until the piece sits in the notch (`piece.x = 425` for seed 5) and
   release.
   *Expected:* green **VERIFIED — Slide accepted** banner, Slide segment of the progress bar turns
   green, **Continue** enables. Click it.
4. Drag the dial knob clockwise until the picture is upright (seed 5 starts at −58°, so the dial
   reads about `+58°`) and release.
   *Expected:* **VERIFIED — Orientation locked**. Continue.
5. Click the four cone tiles (seed 5: tiles 4, 9, 11 and 15 — the striped barrel in tile 14 is a
   decoy) and press **Verify selection**.
   *Expected:* **VERIFIED — Classification complete**. Continue.
6. Drag the jigsaw piece from the tray onto the hole (seed 5: hole at `(123, 42)`) and release.
   *Expected:* the piece seats with a green outline, **VERIFIED — Piece seated**. Continue.
7. Press on **START**, follow the corridor with the button held down (the trail draws in cyan and
   `trace %` climbs), and release on **END**.
   *Expected:* **VERIFIED — Corridor traced**, the button now reads **Claim certificate**.
8. Click **Claim certificate**.
   *Expected:* the **Certified Robot #5** certificate with all five stages ticked, "2 attempts"
   next to *Slide the piece into the notch*, and a **Printable certificate** button.
9. Click **Printable certificate**.
   *Expected:* the certificate switches to a white paper layout with **Print** / **Back**.

### Recording

**Recording link:** _to be added after the showcase run_

## Project layout

```
src/
  App.tsx                     run state machine, header, progress, feedback, certificate hand-off
  components/
    ProgressBar.tsx           five-segment progress bar
    Certificate.tsx           certificate + printable view
    SceneSvg.tsx              renders a generated landscape/robot scene into an <svg>
  stages/
    types.ts                  stage metadata, shared props, tolerances
    SliderStage.tsx           stage 1: horizontal slide into a notch
    RotateStage.tsx           stage 2: drag-dial rotation
    TilesStage.tsx            stage 3: 4×4 "select the traffic cones" grid
    JigsawStage.tsx           stage 4: jigsaw drag-and-drop
    PathStage.tsx             stage 5: corridor tracing with the button held down
  lib/
    rng.ts                    mulberry32 PRNG, seed parsing, per-stage sub-seeds
    scene.ts                  deterministic landscape + robot scene spec
    jigsaw.ts                 jigsaw piece outline path generator
    geometry.ts               Catmull-Rom curve, nearest-point-on-polyline, helpers
```
