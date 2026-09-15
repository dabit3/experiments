# 16 — Split Timeline

40 seconds · 1920×1080 · 30 fps · H.264 · silent

A persistent vertical division connects readable developer instructions on an
off-white left panel to Devin's execution on a dark green right panel. A thin
eight-chapter timeline tracks **story progress**, never measured execution time.
The split and its intent/execution labels remain through the logo end card.

## Edit and render

`config.ts` owns every scene headline, instruction, label, duration, font, color,
and phone crop. Scene duration edits must also update `template.json` so its
duration equals the sum of the scene seconds. `index.tsx` registers `Launch` and
contains the layouts and frame-based animation. No external fetches or fonts are
required at render time.

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 16-split-timeline
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate,pix_fmt \
  -show_entries format=duration out/16-split-timeline.mp4
node templates/16-split-timeline/qa.mjs
```

Shared render defaults: H.264, yuv420p, CRF 18, concurrency 2. Rendered deliverables
belong in ignored `out/`, never in this directory.

## Scenes and motion budget

| Time | Beat and headline | Execution source | Concurrent motion families |
| --- | --- | --- | --- |
| 0–4 | Hook: Your app. Now in Devin’s hands. | Cropped native iPhone charts, `devin-web-18.png` | Story progress + entrance, then progress + typed intent |
| 4–8 | Context: Manual QA. Or another CI wait. | Actual Mac session, `devin-web-13.png`; editorial prior-CI card | Progress + entrance, then progress + typed intent |
| 8–13 | Build/run: A Mac VM. A running app. | Native phone crop from `devin-web-18.png`; illustrative build action rail | Progress + entrance/typed intent sequentially; rail changes by cut |
| 13–19 | Simulator: Tap. Type. Scroll. | Phone crops: `devin-web-14.png`, `devin-web-10.png`, `devin-web-18.png` | Progress + entrance/gesture sequentially; screenshot cuts; static instruction |
| 19–25 | Iterate: Reproduce. Fix. Retest. | `devin-web-10.png`; source's mixed results retained in a readable annotation | Progress + entrance/typing sequentially; step labels cut |
| 25–31 | Evidence: See what happened. | Actual muted `devin-testing-2.mp4`, source 14–20s | Source-video motion + story progress; other content static |
| 31–36 | Outcome: A working app. Ready to inspect. | `devin-web-18.png`; same price as Linux VMs | Progress + entrance, then progress + typed intent |
| 36–40 | End: Build. Run. See it. | Faithful supplied `logo-white.png` with macOS + iOS | Progress + entrance, then progress + typed intent |

Entrances are 21-frame ease-out translations/opacity. Intent types at frames
24–65 except in the interaction and video scenes, whose instructions are static.
Native gesture indicators are ease-in-out moves starting after entrance completes.
Chapter progress is linear. Only two families run at once: chapter progress and
one entrance, typing, gesture, or source-video family. Changes of screenshot and
step highlight are hard cuts. The source video scene intentionally disables
entrance and typing animation. There are no CSS animations, wall-clock timers,
random values, or asynchronous UI simulations.

## Source provenance and truthful representation

All media are the coordinator's committed source assets in `public/assets`.
Screenshot crops are configured in original pixel coordinates and uniformly
scaled via Remotion `Img`; no image is stretched. The original phone housing
is preserved. The interaction beat presents one iPhone at a time.

- `devin-web-18.png`: supplied native iPhone Simulator review, Rescue Charts.
  Used for native hook/build/outcome and a representative scroll gesture. The
  original UI remains unchanged. No new test was run to produce this template.
- `devin-web-14.png`: supplied Afterhours Maze native iPhone screenshot. A
  representative gesture points to the app's button; it does not demonstrate
  a newly executed tap or claim a new game outcome.
- `devin-web-10.png`: supplied Wisp Simulator checks with **12 passed, 3 failed,
  2 untested**. The phone crop is reused for the type and fix/retest story beats.
  The fix beat explicitly retains the source's mixed result counts and never
  transitions them to a fabricated all-passing result.
- `devin-web-13.png`: actual supplied Mac session with a developer feature request
  and Devin response. It is used as context, not a recording of Mac VM selection.
- `devin-testing-2.mp4`: supplied generic **web-app QA** screen recording. This
  template shows source seconds 14–20 at 1× playback, muted, with no crop and
  prominent “ACTUAL SOURCE RECORDING / WEB QA” and “not iOS footage” labels.
  It illustrates recorded evidence, not native iPhone interaction.
- `logo-white.png`: supplied complete Devin logo, uniformly scaled on dark
  background, with no redrawing or color substitutions.

Native action labels, typed intent, step highlighting, and gesture rings are
documented representative workflow motion. A persistent quiet **Illustrative
workflow** label accompanies screenshot scenes. The top line shows scene
progress rather than elapsed runtime. “20+ min” is explicitly labeled prior CI
feedback from the launch brief, not a measured duration of the depicted work.
No new native execution, pass rate, speedup, signing, distribution, or real-device
capability is claimed.

## Brand, typography, and limitations

This direction adapts the Figma values documented in root README and
`shared/brand.ts`: near-white surfaces, green status accent, restrained borders,
and generous 32/64 px rhythm. It is not a pixel-copy of the website.

NB International Pro and Inter font binaries were not supplied. The template
uses **Helvetica Neue**, then Arial/sans-serif; code labels use SFMono-Regular,
Menlo, then Consolas/monospace. No font dependency is downloaded. Typography may
vary slightly on systems without the same fallback fonts.

The composition is intentionally silent. The actual source-video audio is muted.
Native screenshots remain still apart from illustrative pointer gestures.
Source UI microcopy is supporting texture; newly typeset editorial labels and
source-result annotations carry the readable launch story. Re-render and inspect
scene/transition stills after edits, especially longer copy or changed crops.

## Offline media QA

`qa.mjs` uses the installed `ffmpeg` and `ffprobe` CLIs, with no additional Node
dependencies. It verifies H.264, 1920×1080, 30 fps, 1,200 frames, and the 40-second
video stream; extracts a full-frame poster at frame 75; and creates a 24-frame
contact sheet in chronological row-major order. Samples cover all eight beats,
all three Simulator actions, each chapter entrance, and 12 frames after each
entrance. The root render may include a silent AAC stream whose padding makes
the container about 40.043 seconds; the video remains exactly 40 seconds.

QA for this revision: root lint, typecheck, manifest validation, full-quality
render, and the ffprobe assertions pass. Scene holds and every chapter boundary
were visually inspected. Source-video audio measured digital silence
(`volumedetect`: maximum −91 dB). No native tests or UI-browser testing were
performed for this offline production task.
