# 03 — Swiss Grid

A silent 40-second editorial launch film. Twelve visible column guides, precise
alignment, a numbered three-section rail, grayscale native screenshots and one
blue accent give the design the rhythm of an animated Swiss publication.

## Edit and render

From `launch-video-templates/`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 03-swiss-grid
node templates/03-swiss-grid/qa.mjs
```

`config.ts` contains every scene's headline, support copy, label, duration, source
crop, and the source video in-point. `template.json` supplies format and metadata.
If changing scene durations, update `durationSeconds` in the manifest to match
their sum. `index.tsx` contains the grid, media components, and frame animation.
Composition ID is `Launch`; the current duration is 1,200 frames at 30 fps.

The layout is a strict 12-column grid: 96 px outer margins, 122 px columns,
24 px gutters. Screenshots move 24 px onto exact column starts over 18 frames;
they do not overshoot. Hairline column edges brighten during transitions.
The persistent 01 / CONTEXT, 02 / WORKFLOW, 03 / OUTCOME rail anchors every scene,
including the logo card.

There are exactly three authored type sizes: 112 px headlines, 48 px supporting
copy, and 24 px labels. All are flush left. The font stack is Helvetica Neue,
Helvetica, Arial, sans-serif; Helvetica Neue is the system fallback used for the
Mac render. NB International Pro binaries were not supplied. Text embedded in
the supplied screenshots/logo is retained as source imagery and is not restyled
or counted as authored typography. All supplied screen imagery is displayed in
grayscale, leaving `#1971c2` as the only chromatic accent. Paper and ink derive
from the supplied brand tokens; the composition adapts the reference rather
than copying its website.

## Scene table

| Time | Beat / primary copy | Source / treatment | Motion families |
| --- | --- | --- | --- |
| 00:00–00:04.50 | Hook: Devin runs Mac + iOS. | Cropped native iPhone from `devin-web-18.png` | Grid-snapped translations; guide opacity |
| 00:04.50–00:08.50 | Context: Manual QA. Or wait for CI. | Editorial 20+ minutes typesetting; prior workflow context | Grid-snapped translations; guide opacity |
| 00:08.50–00:14.00 | A: Build it. Run it. | Native Maze iPhone from `devin-web-14.png`; representative build/run stages | Grid-snapped translations; guide opacity |
| 00:14.00–00:20.00 | B: Tap. Type. Scroll. | Wisp iPhone crops from `devin-web-11.png` then `devin-web-10.png`; illustrative pointer | Grid-snapped translations and pointer motion; guide opacity |
| 00:20.00–00:26.00 | C: Find it. Fix it. Retest. | Wisp phone and unaltered findings crop from `devin-web-10.png` | Grid-snapped translations; guide opacity |
| 00:26.00–00:31.50 | D: Review what happened. | Actual `devin-testing-2.mp4`, source 00:14–00:19.50, labeled recorded web QA | Guide opacity; source playback |
| 00:31.50–00:36.00 | Outcome: A working app. In your session. | Native charts iPhone from `devin-web-18.png`; same price as Linux | Grid-snapped translations; guide opacity |
| 00:36.00–00:40.00 | Logo: macOS + iOS. Build. Run. See it. | Faithful black supplied Devin logo | Grid-snapped translations; guide opacity |

## Motion budget

All authored motion is deterministic and uses Remotion frame values. Entrances
use cubic ease-out; positional moves and 12-frame exit nudges use cubic
ease-in-out. Screens hard-cut between scenes without blank frames. Selection
states and the screenshot swap are hard cuts, not additional animation families.
Pointer moves occur after the phone's entrance, and finish before its exit.
The video scene has no screenshot motion or animated cursor overlays.
There are no CSS animations, random inputs, remote fonts, or audio.

## Provenance and truthful limits

The shared assets and design context come from the coordinator's committed base,
including the corrected Figma file referenced in the root README. This template
does not access the original Socials file.

- `devin-web-14.png`: supplied Maze app in iOS Simulator. Only its phone is
  cropped; the source includes an untested check. No blanket pass claim is made.
- `devin-web-10.png` / `devin-web-11.png`: Wisp native Simulator source stills.
  The phone crops and stage changes are representative motion UI, not new
  recordings. The source has failed and untested checks. The repair scene
  preserves those findings and never fabricates a passing retest.
- `devin-web-18.png`: native charts app within a supplied review screenshot.
  The crop supports the launch capability; it does not claim fresh footage.
- `devin-testing-2.mp4`: actual generic web QA video. It is visibly labeled
  **recorded web QA / source clip**, shown at 1×, and muted using `OffthreadVideo`.
  It is not represented as iOS footage or a Mac VM selector.
- `logo-black.png`: supplied logo, used at its intrinsic aspect ratio.
- All source crops retain their original aspect ratios and are declared in
  `config.ts`. Phone corners are masked to their rounded silhouette. Grayscale
  is an editorial color treatment only.

The small **Illustrative workflow** line identifies staged native scenes.
The phone remains one device at a time. Pointer motion communicates available
tap/type/scroll interaction; it does not purport to replay a newly captured test.
The repair stage labels describe the capability, not measured results.
“20+ minutes” is the prior CI context from the brief, not a benchmark.
The film promises no signing, distribution, real-device, or timing guarantees.

## Output and offline QA

Render: `out/03-swiss-grid.mp4` (H.264, CRF 18, 1920×1080, 30 fps).
The full-frame poster and contact sheet are extracted from the finished MP4;
they are deliverables under ignored `out/`, never committed.
`qa.mjs` requires `ffmpeg` and `ffprobe` on PATH, verifies codec, dimensions,
frame rate, duration, frame count, and full-file decoding, and generates the
poster, 32-frame contact sheet, and eight full-resolution scene stills.

The contact sheet is chronological, read left to right and top to bottom.
Its frame indices are:
`0, 60, 134, 135, 141, 195, 254, 255, 261, 330, 419, 420, 426, 495, 555, 599,
600, 606, 690, 779, 780, 786, 840, 944, 945, 951, 1005, 1079, 1080, 1086, 1155,
1199`.
This covers all eight scenes, the staged input state change, the first/last
frames, and before/at/during each scene transition. Inspect for text overlap,
incorrect phone crops, empty frames, missing assets, and readable labels.

The video stream is exactly 40.000 seconds. The default shared render includes
a silent AAC stream whose padding makes the container 40.042667 seconds.
This is silent by design; the source's incidental audio is muted.
