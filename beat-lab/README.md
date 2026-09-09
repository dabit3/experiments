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

## Run it

```bash
cd beat-lab
npm install
npm run dev
```

Then open the printed `http://localhost:5173` URL. `npm run build` type-checks and produces a
static bundle in `dist/`; `npm run lint` runs oxlint. The app has no backend and makes no network
calls at runtime.

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
4. **Add a bass line.** Switch to the **Bass** tab and place four notes (e.g. C2, G2, A#2, C3) on
   different steps. *Expected:* the tab badge shows 4 notes.
5. **Play.** Press **Play** (or `Space`). *Expected:* the teal playhead column sweeps left to
   right across the grid in time with the audio; the Stop button replaces Play.
6. **Save.** Click **Save JSON**. *Expected:* `beat-lab-pattern.json` lands in `~/Downloads` and
   a toast confirms the save.
7. **Clear.** Click **Clear**. *Expected:* drum and bass grids are empty, badges read 0.
8. **Reload.** Click **Load JSON** and pick the downloaded file. *Expected:* all 8 drum tracks,
   the 4 bass notes, 92 BPM and 15 % swing come back, and **Compare with reference** reports
   0 differences again.

### Recording

_Recording link: to be added after the showcase run._

## Project layout

```
src/
  App.tsx                    song state, sequencer wiring, compare / save / load, toasts
  components/
    Transport.tsx            play/stop, tempo + swing sliders, pattern A/B, chain, file actions
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
