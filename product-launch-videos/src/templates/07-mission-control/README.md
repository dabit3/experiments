# 07 · Mission Control

A fixed control-room composition: one large primary display and three smaller,
text-only source-index bays. These identify session setup, Simulator stills, and
the separate web QA recording. The bright outline means “on main display,” not
execution status. The bays do not imply concurrent agents or app continuity.

The opening aperture settles into the display structure. Source changes retain
the same viewport and caption location; a short selection rule points from the
relevant bay to the primary display. Demo typography and media geometry remain
stationary. The iPad result holds for six seconds, then the primary display
consolidates into a full-width closing hero.

## Run

From `product-launch-videos/`, with Node >=22.12, npm, Python and FFmpeg:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run templates:list
npm run lint
npm run typecheck
npm test
npm run build
npm run render -- --template 07-mission-control
npm run still -- --template 07-mission-control --frame 450
npm run still -- --template 07-mission-control --frames 0,18,90,150,270,330,450,540,675,750,960,1062,1140
npm run contact-sheet -- out/07-mission-control
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/07-mission-control/07-mission-control.mp4
```

The independent entry is `src/templates/07-mission-control/entry.tsx`, composition
`MissionControl`. The collector discovers `manifest.json` and `index.ts`; no
shared registry changes are needed. Outputs and private inputs remain ignored.

## Editing

`config.ts` exports the complete typed `MissionControlConfig`.

- `copy`: all shared captions, opening, benefit, closing, CTA and URL.
- `durations`: seven scene durations in seconds, default 4/5/4/9/7/6/5.
  Composition metadata is calculated from these durations.
- `media`: originals, source-pixel crops, contain/cover fit, crop anchors and
  video source-start seconds. Video playback ranges are source start through
  source start + scene duration. Shared validation rejects source overruns.
- `brand`: colors and font family, heading/body size, tracking and line height;
  original bundled fonts block render until loaded. Use the supplied white
  artwork on the default dark presentation.
- `layout`: outer margins, primary/rail gutter, media padding, caption height,
  and numeric `grid.captionTop`/`grid.footerTop` positions.
- `panels`: primary width, display top/height, display header height, rail width,
  bay height/gap and logo width. Keep margin × 2 + primary width + gutter + rail
  width <=1920. Keep display top + display height below the footer.
- `labels`: source descriptions, editorial edition, bay titles/details/source
  notes, scene-to-bay assignments, reference and selected labels.
- `status`: selected/reference outlines, selected fill, secondary text,
  outline width and optional selection badges. These are editorial treatments.
- `motion`: aperture frames, bay settle/stagger/travel, selection-rule frames,
  opening width ratio, closing consolidation frames and iPhone still split.
  All motion is deterministic and frame-driven. Set animation durations to zero
  for cuts. Keep short scenes long enough to finish their bookend animations.

For a render override, copy `out/07-mission-control/resolved-props.json`, edit the
complete object, and pass `--props /absolute/path/to/edited-props.json`. Props are
not deeply merged. Every field above is JSON serializable.

Reproduce the 16-second editability diagnostic (custom environment caption,
different scene durations and animation timings, nonzero video trims):

```sh
npx tsx src/templates/07-mission-control/make-variant.ts
npm run render -- --template 07-mission-control \
  --props out/07-mission-control/editability/props.json \
  --output out/07-mission-control/editability/edited.mp4
npm run still -- --template 07-mission-control \
  --props out/07-mission-control/editability/props.json --frame 75 \
  --output out/07-mission-control/editability/edited-caption.png
```

The expected diagnostic duration is 480 frames / 16 seconds. The CLI writes
`metadata.json` and `resolved-props.json` at the template output root even with
a custom output path; copy diagnostic metadata into the editability directory
before rendering defaults again.

## Media and fidelity

`attribution.json` records the exact default edit, crops, source trims, fonts and
logo. See the shared `MEDIA-ATTRIBUTION.md` for original provenance and hashes.
The environment crop emphasizes the actual hosted Mac menu. The agent crop
retains the original composer and menu. Both recordings play at 1×; neither
recording depicts an iOS Simulator. All three native-app examples are genuine
stills from separate sessions. The native screenshots are uncropped, preserving
failed/untested counts and reports. Web QA carries the persistent shared label.

For source substitutions, recheck crop bounds and report visibility. Long custom
captions may require smaller body typography or a taller caption region.
No soundtrack, network font, placeholder, fake telemetry or animated internal
Simulator state is used.

## Validation

Verified on 2026-09-15:

- `assets:check`: all 45 supplied originals match the foundation manifest.
- `lint`, `typecheck`, `build` and template discovery pass. The shared suite
  passes all 8 TypeScript and 3 Python tests.
- Full default render: H.264, 1920 × 1080, 30/1 fps, 1200 frames, exactly
  40.000000 seconds, no audio stream. FFmpeg decoded the whole MP4 without errors.
- Edited diagnostic: 1920 × 1080, 30/1 fps, 480 frames, exactly 16 seconds.
  The changed environment caption was rendered and visually checked. Agent
  source offset is 1 second and web QA offset is 3 seconds in that diagnostic.
- Inspected representative opening, selection, iPhone, web QA, iPad and closing
  frames, plus the opening/closing motion and source boundaries. The initial
  reference-bay text wrap was corrected before the final render.
- Original report counts, proportional white lockups, loaded font glyphs and
  fixed demo typography were checked in full-size frames. Afterhours Maze
  retains “8 passed / 0 failed / 1 untested,” including in the encoded MP4.

The delivered poster is full-size frame 450. The compact contact sheet uses
eight frames extracted from the actual encoded MP4 at 3, 5, 11, 15, 18, 25, 32
and 38 seconds, in reading order. Reproduce that sheet after the main render:

```sh
mkdir -p out/07-mission-control/contact-frames
ffmpeg -v error -i out/07-mission-control/07-mission-control.mp4 \
  -vf "select='eq(n,90)+eq(n,150)+eq(n,330)+eq(n,450)+eq(n,540)+eq(n,750)+eq(n,960)+eq(n,1140)'" \
  -vsync 0 -frame_pts 1 out/07-mission-control/contact-frames/frame-%06d.png
npm run contact-sheet -- out/07-mission-control/contact-frames
cp out/07-mission-control/contact-frames/contact-sheet.png \
  out/07-mission-control/contact-sheet.png
```

Limitations: private source media and original font binaries must be installed
from the shared ZIP; they are deliberately absent from git. Simulator examples
are stills, not recordings. Small text in complete source reports is best viewed
at the native 1080p output size. Arbitrary replacement captions and geometries
need a new visual check; this is an editable composition, not an automatic layout
engine. No public deployment or browser UI testing was performed.
