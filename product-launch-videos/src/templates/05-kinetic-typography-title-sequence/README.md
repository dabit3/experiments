# 05 — Kinetic Typography Title Sequence

A phrase becomes a frame. Complete title blocks lift through rectangular masks.
At each still demonstration, a large action phrase and its baseline dock into a
quiet caption rail, releasing space for an undistorted product view. Both videos
have fixed, full source viewports from their first frame; only the caption moves
for the opening 26 frames. The iPhone still replacement is a clean aligned cut:
the typography does not restart or animate during report inspection.

## Run

From `product-launch-videos/`, after the shared setup:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run templates:list
npm run lint
npm run typecheck
npm test
npx tsx --test src/templates/05-kinetic-typography-title-sequence/phrase.test.ts
npm run render -- --template 05-kinetic-typography-title-sequence
npm run still -- --template 05-kinetic-typography-title-sequence --frame 450
npm run still -- --template 05-kinetic-typography-title-sequence \
  --frames 24,126,150,285,330,450,540,675,750,900,1056,1140
npm run contact-sheet -- out/05-kinetic-typography-title-sequence
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/05-kinetic-typography-title-sequence/05-kinetic-typography-title-sequence.mp4
```

Independent entry: `src/templates/05-kinetic-typography-title-sequence/entry.tsx`.
Composition: `KineticTypographyTitleSequence`. No registry edit is needed.

## Editing

`config.ts` is the complete typed input. For JSON editing, copy the generated
`out/05-kinetic-typography-title-sequence/resolved-props.json`, modify it and use
`--props /absolute/path/to/props.json`. Supply the complete `{ "config": ... }`
object: the CLI does not deep-merge partial props.

- **Copy:** `copy` includes opening, benefit, five captions, feature name, pricing,
  CTA, and URL. `labels` holds the source-kind disclosures. Keep the Web QA footer.
- **Durations:** seven durations in seconds; the default is 4 / 5 / 4 / 9 / 7 /
  6 / 5 = 40 seconds, 1200 frames at 30 fps. Metadata and scene boundaries derive
  from these values, including the iPhone cut. A short scene bounds its transition
  to one third of its duration. The source recordings must remain within their
  actual lengths; the shared video component rejects overruns.
- **Media/crops:** each `media` selection accepts an original asset, `fit`,
  normalized `anchorX`/`anchorY`, and optional original-pixel crop rectangle.
  Defaults contain the entire source. Keep complete report counts visible when
  changing crops. Source times are separately configurable in seconds.
- **Colors/type:** `brand.colors` and `brand.typography` set the presentation
  palette, family, line height and tracking. `typography` sets title/caption
  bounds, initial phrase scale, label size and title line count. Font measurement
  runs after the shared font gate. Whole words wrap in titles; captions fit on
  one line. Copy that cannot fit above the minimum font size fails explicitly.
  Tracking measurement supports `em`; keep heading tracking in this unit.
- **Spacing:** `layout.margin`, `gutter`, `padding`, `captionHeight`, and `grid`
  control scene geometry. `grid.labelHeight` reserves the small header row;
  `launchHeaderHeight` is the initial still-scene title plane; `titleWidth` limits
  opening title width; `endCardHeight` sets the final CTA panel.
- **Motion:** `phraseDockFrames`, `titleRevealFrames`, `phraseTravel`,
  `titleTravel`, `titleLift`, `ruleThickness`, `iphoneSplit`,
  `endCardRevealFrames` are documented by exported `controls`. All animation is
  a deterministic function of the Remotion frame. There are no springs, CSS
  clocks, per-letter animation, source speed changes, or external network fonts.

`Title`, `Demo`, `Caption`, `Transition`, and `EndCard` are exported components.
The source `phrase.ts` helper fits complete words using loaded-font measurements.

## Content and provenance

This is a montage of independent examples. The iPhone and iPad images are honest
stills. Neither MP4 is Simulator footage. The Web QA example label remains outside
the source image for its entire seven-second clip. The Afterhours Maze report
retains **8 passed, 0 failed, 1 untested**. Product views occupy 31 of 40 seconds.

See `attribution.json` for the default source/output timeline, and the shared
`MEDIA-ATTRIBUTION.md` for source provenance and exact-hash inventory. Brand values
derive from the corrected Figma reference specified in the production brief.
Original media and fonts remain in ignored `public/assets/`; output files remain
in ignored `out/`. None are redistributed with this template's source.

## Diagnostic configuration

This generates a complete alternate input with longer opening/caption/CTA text,
64px margins, a faster 12-frame phrase dock, 144px travel, and a 60/40 iPhone split.
Its seven scenes total **15 seconds / 450 frames**. It is an editability diagnostic,
not the comparable launch sample.

```sh
npx tsx src/templates/05-kinetic-typography-title-sequence/diagnostic-props.ts
npm run render -- \
  --entry src/templates/05-kinetic-typography-title-sequence/entry.tsx \
  --composition KineticTypographyTitleSequence \
  --props out/05-kinetic-typography-title-sequence/diagnostic-props.json
npm run still -- \
  --entry src/templates/05-kinetic-typography-title-sequence/entry.tsx \
  --composition KineticTypographyTitleSequence \
  --props out/05-kinetic-typography-title-sequence/diagnostic-props.json \
  --frames 30,90,150,235,300,360,420
```

The independent-entry invocation puts these diagnostic artifacts in
`out/kinetic-typography-title-sequence/`, separate from the final default output.

## Verified results

- Full default MP4: H.264, **1920 × 1080**, **30/1 fps**, **1200 frames**,
  **40.000000 seconds**, confirmed by FFprobe.
- Full alternate MP4: **1920 × 1080**, **30/1 fps**, **450 frames**,
  **15.000000 seconds**. Inspected its three-line opening, long single-line
  caption and two-line CTA without unintended clipping or overlapping UI.
- `assets:check`, `lint`, `typecheck`, `build`, `templates:list`, all **11 shared
  tests**, and both template tests passed. The template tests are run by the
  explicit `npx tsx --test ...` command above.
- Inspected default frames across the opening, phrase docking, both recordings,
  both iPhone reports, iPad and end-card hold. The partial text at entrance frames
  is the intentional rectangular title mask; held phrases are fully visible.
- Delivered poster is default frame **450**. The delivered contact sheet uses
  twelve actual frames **decoded from the completed MP4** at the listed positions,
  rather than a separate mockup. Extra inspection included frames 0 and 90.
- The original NB International font and supplied proportional logo are present.
  The full Afterhours Maze counts and persistent Web QA footer remain readable.

## Limitations

No delivery blocker remains. This template requires the supplied local asset
bundle; source media and font files are intentionally absent from Git. Native
app evidence is still imagery, and the two 1× recordings demonstrate separate web
sessions. The sample is silent. Very long copy fails at its configurable minimum
font size rather than overflowing; extreme custom geometry or crops should be
checked with fresh stills. The title fitter measures heading tracking in `em`.
