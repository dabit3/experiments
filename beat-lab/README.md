# Beat Lab

A step sequencer and piano roll built with Vite + React + TypeScript. Eight drum tracks (kick,
snare, closed hat, open hat, clap, rim, tom, cowbell) are synthesised entirely with the Web Audio
API — oscillators, filtered noise and envelopes, no samples — on a 16-step grid with a look-ahead
scheduler so timing stays tight while the UI redraws. It has a 60–200 BPM tempo slider, swing,
per-step velocity (right-click cycles soft / medium / hard), two patterns (A/B) with chained
playback, mute/solo per track, a piano-roll tab for a one-bar C2–C4 bass line, a moving playhead
column, save/load of the whole song as JSON (download/upload), and a read-only **Reference** panel
showing a target "Boom Bap" pattern with a **Compare with reference** button that lists every
step that differs.

## Studio workspace

A mineral-colored shell frames a graphite sequencer with muted track colors, precise beat
divisions and an understated rhythm mark. Inter handles the interface; JetBrains Mono handles
the musical data. The transport stays above the score, and live A/B pattern previews make it
easy to switch ideas without losing your place.

The piano roll fills the editor width and keeps its 25 pitches compact on desktop. Smaller
screens use scrolling inside the editor with sticky pitch labels, rather than shrinking the
whole application or requiring browser zoom. Velocity levels have visible bars as well as
different color intensities.

## Run it

```bash
cd beat-lab
npm install
npm run dev
```

Then open the printed `http://localhost:5173` URL. `npm run build` type-checks and produces a
static bundle in `dist/`; `npm run lint` runs oxlint. The app has no backend and makes no network
calls at runtime (Inter and JetBrains Mono are bundled via `@fontsource-variable`).

### Automated test

```bash
npx playwright install chromium   # first time only
npm run test:e2e
```

`e2e/showcase.spec.ts` is a Playwright script that replays the full browser scenario below
(reproduce Boom Bap → Compare = 0 differences → 92 BPM / 15 % swing → 4-note bass line → play and
assert the playhead advances → Save JSON → Clear → upload the saved file → assert everything is
restored). It starts the Vite dev server itself on port 5174.

`e2e/studio.spec.ts` also covers independent A/B edits, live pattern previews, chained playback,
mute/solo and velocity controls, plus containment and piano-ruler alignment at six viewport
widths from 360 to 1600 pixels. A dedicated mobile regression checks the visible sticky track
indices and masked ruler corner after horizontal scrolling. The four automated tests supplement
the real mouse-and-keyboard showcase recording.

Controls: left-click a cell to toggle a step · right-click to cycle velocity · `Space` play/stop ·
tempo and swing sliders also respond to arrow keys and have −/+ buttons for exact values ·
`M`/`S` next to a track name mutes/solos it.

## Computer-use skill showcased

**Dense grid toggling, slider control, reproducing a pattern from a reference and visual playback
verification.** The 8×16 drum grid has 128 small targets that have to be hit exactly to match
the reference; the sliders must land on precise values (92 BPM, 15 % swing); the piano roll is a
25×16 grid; and the playhead can only be verified by watching the column highlight move while
the beat plays. Saving and re-loading the JSON through the browser's real download/upload flow
proves the round-trip.

## Browser test scenario

Performed by Devin with mouse and keyboard in a maximised Chrome window with screen recording on:

1. **Reproduce the reference.** Click every step shown in the Reference panel onto the drum grid
   (kick 1·8·11, snare 5·13, closed hat every odd step, open hat 7·15, clap 5·13, rim 4·12,
   tom 14, cowbell 10). *Expected:* the grid mirrors the reference mini-grid.
2. **Compare.** Click **Compare with reference**. *Expected:* "Perfect match — 0 differences".
3. **Set tempo and swing.** Drive the Tempo slider to **92 BPM** and the Swing slider to **15 %**
   (slider drag plus arrow keys / −+ buttons for the last step). *Expected:* the readouts show
   exactly 92 and 15.
4. **Add a bass line.** Switch to the **Bass** tab and place C2 on steps 1 and 5, D#2 on step 9,
   and G2 on step 13. *Expected:* the tab badge shows 4 notes.
5. **Play.** Press **Play** (or `Space`). *Expected:* the playhead column sweeps left to
   right across the grid in time with the audio; the Stop button replaces Play.
6. **Save.** Click **Save JSON**. *Expected:* `beat-lab-pattern.json` lands in `~/Downloads` and
   a toast confirms the save.
7. **Clear.** Click **Clear**. *Expected:* drum and bass grids are empty, badges read 0.
8. **Reload.** Click **Load JSON** and pick the downloaded file. *Expected:* all 8 drum tracks,
   the 4 bass notes, 92 BPM and 15 % swing come back, and **Compare with reference** reports
   0 differences again.

### Recording

**Recording (mp4):** https://app.devin.ai/attachments/64e88ebb-20c5-4210-9c0f-ccb96c8dec8f/beat-lab-run3.mp4

Latest studio design, recorded in maximized Chrome at 1600×1200 and 100% zoom. All 25 piano
rows fit inside the editor. The full scenario passed; the download was independently checked
for the exact drum hits, bass MIDI notes, tempo and swing.

![Beat Lab showcase preview](https://app.devin.ai/attachments/06b6068c-e3d0-4ac8-b2db-d6153638f9a4/beat-lab-preview.webp)

| | |
| --- | --- |
| ![Perfect match](https://app.devin.ai/attachments/7846630b-8f4b-4785-93f3-2001b185219d/01-perfect-match.png) Boom Bap reproduced — Compare reports 0 differences | ![92 BPM / 15% swing](https://app.devin.ai/attachments/38609280-cbcc-4ae5-8abb-2e36aa88a168/02-tempo-92-swing-15.png) Faders set to 92 BPM and 15% swing |
| ![Bass line](https://app.devin.ai/attachments/7bee7e69-490e-42f3-97bb-00e0eea61e7d/03-bass-line-4-notes.png) Four-note bass line at 100% zoom | ![Playhead](https://app.devin.ai/attachments/20378972-5c1f-4a21-80aa-4e0b333a6aed/04-playhead-moving.png) Playhead mid-playback |
| ![Saved](https://app.devin.ai/attachments/8010186f-dd9b-4d24-9ecd-af8d040ea8bc/05-saved-json.png) `beat-lab-pattern.json` downloaded | ![Cleared](https://app.devin.ai/attachments/88af1a40-527b-4cd7-9894-65a7c6f44319/06-cleared.png) Grid cleared (Drums 0, Bass 0) |
| ![Reloaded](https://app.devin.ai/attachments/35db425f-7cc5-42c5-883e-13a5f8ffd2aa/07-reloaded-drums.png) Upload restores all 21 steps | ![Round-trip verified](https://app.devin.ai/attachments/abfa6d92-f2a3-43b8-8bc4-7e2d31a6e61a/08-reloaded-bass-perfect-match.png) Bass notes back and Compare still reports 0 differences |

### Responsive verification

Mobile controls, editor scrolling, sticky track labels, ruler masking and note entry were
checked at 375px using Chrome's native responsive mode.
[Mobile recheck recording](https://app.devin.ai/attachments/04bda6c5-44a5-4504-a410-102a7b3ee0da/mobile-scroll-recheck.mp4).

| Populated mobile studio | Scrolled drum editor |
| --- | --- |
| ![Mobile studio](https://app.devin.ai/attachments/0a3f77b3-554f-42d3-b3e4-a835eac88dba/mobile-full-populated.png) | ![Sticky labels after scrolling](https://app.devin.ai/attachments/6920c96c-edd5-49aa-bc16-963c14001429/mobile-drums-scrolled-fixed.png) |

Audio quality and physical mobile hardware were not assessed.

## Project layout

```
e2e/
  showcase.spec.ts           Playwright replay of the browser scenario (npm run test:e2e)
  studio.spec.ts             A/B isolation, chaining, mixer controls and responsive layout
src/
  App.tsx                    song state, sequencer wiring, compare / save / load, toasts, status bar
  components/
    Logo.tsx                 rhythm mark (also public/favicon.svg)
    Transport.tsx            play/stop, position, beat markers, tempo + swing, chain, file actions
    PatternOverview.tsx      live A/B previews and pattern selection
    StepGrid.tsx             8×16 drum grid with velocity cells, mute/solo, playhead column
    PianoRoll.tsx            25×16 C2–C4 note grid, one note per step
    ReferencePanel.tsx       read-only target grid + compare results
  lib/
    synth.ts                 Web Audio drum + bass synthesis (no samples)
    sequencer.ts             look-ahead scheduler, swing, A/B chaining, playhead queue
    patternIO.ts             JSON serialise / validate / download
  reference.ts               Boom Bap target pattern + step diff
  types.ts                   tracks, velocities, song model, MIDI helpers
```
