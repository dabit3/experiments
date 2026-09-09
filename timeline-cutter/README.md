# Timeline Cutter

A non-linear video editor timeline with trim, split and ripple — built with
Vite + React + TypeScript. There are no real video files: every "clip" is a
procedurally drawn canvas animation (sunrise gradient, ocean waves, neon grid,
forest bokeh, golden bars, violet noise) with a burnt-in timecode, so the
program monitor composites the sequence in real time and the whole thing is
deterministic and reproducible.

## Features

- **Media bin** with 6 generated clips (4–8 s each), live thumbnails and usage counts.
- **Two-track timeline** — `V1` video (magnetic: clips always butt up against each
  other) and `T1` title overlay — with a time ruler, a zoom slider / `Ctrl`+wheel
  zoom, and a "Fit" button.
- **Draggable playhead**: scrub on the ruler or drag the red head; the monitor
  follows in real time. Scrubbing is frame-quantised to 30 fps.
- **Trim handles** on both ends of every clip. Trimming a clip's tail ripples every
  following clip; a tooltip shows the delta and the new duration while dragging.
- **Razor**: `S` splits the clip under the playhead; the razor tool (`B`) cuts
  where you click.
- **Ripple delete** (`Delete` / `Backspace`) closes the gap.
- **Drag-to-reorder** with magnetic snapping (`N` to toggle) to clip edges and the
  playhead; a snap guide lights up when a snap engages. Titles are free-positioned
  on `T1` and snap the same way.
- **Program monitor** composites the video clip under the playhead plus any active
  title (with fade in/out and a progress bar) at 1280×720.
- **Transport**: `Space` play/pause, `J` / `K` / `L` shuttle (press `J`/`L` again to
  go 2× / 4×), `←` / `→` frame step, `Home` / `End`.
- **Undo / redo** (`Ctrl+Z`, `Ctrl+Shift+Z`) across every edit.
- **Export EDL** as JSON or CSV: one event per clip with reel, source in/out and
  record in/out (seconds and `HH:MM:SS:FF` timecode), plus title events.

## Run it

```sh
cd timeline-cutter
npm install
npm run dev      # http://localhost:5173
npm run lint     # oxlint
npm run build    # tsc -b + vite build
```

No backend and no network calls; everything is bundled.

## Computer-use skill showcased

**Sub-pixel drag of trim handles, scrubbing a playhead, drag-reorder with
snapping.** Each trim handle is a 14 px-wide target that must be pressed and
dragged a precise distance (48 px per second at the default zoom, so "about
2 seconds" is a ~96 px drag). The playhead has to be scrubbed smoothly across a
cut so the monitor visibly switches sources, and reordering means grabbing a clip
body, dragging it several hundred pixels past its neighbours and releasing once
the magnetic snap guide engages on another clip's edge.

## Browser test scenario

Goal: assemble a 20-second sequence and export a correct EDL.

| # | Step | Expected result |
|---|------|-----------------|
| 1 | Click **+** on Sunrise Gradient, Ocean Waves, Neon Grid, Forest Bokeh | Four clips on V1, sequence 26.00 s, monitor shows clip A |
| 2 | Drag the right (tail) trim handle of Sunrise Gradient left by ~2 s | Clip A ≈ 4.0 s, later clips ripple left, sequence ≈ 24 s |
| 3 | Scrub the playhead to 00:00:13:00 (inside Neon Grid) and press `S` | Neon Grid splits into two 4 s halves; V1 has 5 clips |
| 4 | Click the second half of Neon Grid and press `Delete` | Ripple delete: Forest Bokeh slides left, sequence = 20.00 s |
| 5 | Drag Forest Bokeh left until it snaps to the start of Ocean Waves and release | Order becomes A, D, B, C — no gaps |
| 6 | Park the playhead over a clip and press `T` | A 4 s "Timeline Cutter" title appears on T1 and is composited in the monitor |
| 7 | Drag the playhead back and forth across the Ocean Waves → Neon Grid cut | Monitor switches between the blue waves and the neon grid in real time |
| 8 | **Export EDL → JSON**, then inspect `~/Downloads/timeline-cutter-edl.json` | 4 video events (A 4 s, D 7 s, B 5 s, C 4 s), `sequenceDuration` 20, one title event |

## Recording

Recording of Devin performing the scenario in Chrome: _pending — link added after the showcase run_.
