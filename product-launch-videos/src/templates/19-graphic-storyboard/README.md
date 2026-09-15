# 19 — Graphic Storyboard

A seven-panel editorial story. Three proportioned opening panels establish the
feature, then the active product panel expands while the previous panel collapses
to a quiet typographic spine. Side, stacked and full-width arrangements share
consistent gutters. A moving vertical boundary changes the two iPhone stills.
The last product panel occupies the entire available page area and holds into the
closing scene before a full-panel CTA opens.

The marks are editorial panel indices, not execution telemetry. Native views are
unchanged stills from separate sessions. Agent selection and Web QA are the two
actual recordings. Captions, still/recording disclosures and the seven-panel
reading strip sit outside product controls. The web recording also retains the
shared mandatory **Web QA example** footer. The first iPhone report includes
**8 passed, 0 failed, 1 untested**.

## Setup and render

From `product-launch-videos/`, with Node 22.12+, npm, Python 3.9+ and FFmpeg:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run lint
npm run typecheck
npm test
npm run build
npm run render -- --template 19-graphic-storyboard
npm run still -- --template 19-graphic-storyboard --frame 90
npm run still -- --template 19-graphic-storyboard \
  --frames 0,90,126,180,330,450,530,600,750,960,1080,1140
npm run contact-sheet -- out/19-graphic-storyboard
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/19-graphic-storyboard/19-graphic-storyboard.mp4
```

Default output: 1920×1080, 30 fps, silent H.264, 1200 frames / 40 seconds.
Fonts, source files and all renders stay in ignored directories; no binaries are
included here. Asset provenance and the default timeline are in `attribution.json`
and the shared `MEDIA-ATTRIBUTION.md`.

## Editing

`config.ts` exports the complete typed `StoryboardConfig`. `index.ts` lists all
controls for the gallery. Edit that config, or copy the generated
`out/19-graphic-storyboard/resolved-props.json`, change its complete `config`
object, and pass `--props /absolute/path/to/props.json` to render/still. Partial
objects are not merged. The seven configured durations drive composition metadata.

- `copy`: title, feature, benefit, scene captions, pricing, CTA and URL.
- `media`: original image/video IDs, source start offsets, contain/cover framing,
  source-pixel crop rectangles and normalized anchors. Defaults preserve every
  source pixel. Do not crop away results, failure counts or untested counts.
- `brand`: neutral palette, original font families, sizes, line heights and
  tracking. Heading and body sizes also scale the title and caption hierarchy.
  The shared font gate waits for the supplied original font files.
- `layout`: margin, gutter, source padding, caption height; `grid.top`,
  `contextWidth`, `contextHeight`, `borderWidth` and `logoWidth` control geometry.
  Keep positive source viewports and allow space for edited captions.
- `storyboard.readingOrder`: `left-to-right` or `right-to-left`. This mirrors the
  visual reading direction and gutter opening, preserving the approved narrative
  and source sequence.
- `storyboard.arrangements`: `side`, `stack`, `full` per product scene. `opening`
  and `closing` entries are reserved; those scenes keep their dedicated layouts.
- `storyboard.introFractions`: three positive relative panel widths, normalized
  automatically. Defaults allocate most of the opening to the launch headline.
- `storyboard.introLabels`, `chapterNames`, `edition`, `montageLabel`, `stillLabel`,
  `recordingLabel`: editable marginal copy. Keep the separate-session/still
  distinctions truthful. `closingLogo` controls the supplied light-on-dark logo.
- `motion.gutterFrames`: boundary expansion time, capped to a quarter of the
  scene. `stillEntryFraction` and `videoEntryFraction` set initial active sizes;
  keep video entry at least 0.85 so source actions remain recognizable throughout.
- `motion.introStaggerFrames`: short offsets between title panel reveals.
- `motion.iphoneSplit`: split ratio between the two honest iPhone stills;
  `stillBoundaryFrames` controls the boundary crossing. No internal UI animates.
- `motion.closingResultFraction`: closing hold on the final iPad result;
  `closingBoundaryFrames` controls the CTA boundary.
- `motion.contextOpacity`: quiet previous-panel labels.

Animations depend only on composition frames. Typography is stationary throughout
demonstrations. Videos always run at 1×; source bounds are checked by the shared
component. Extending either recording must still fit its actual source length.

## Reusability validation

Generate a separate 12-second / 360-frame diagnostic with altered environment
and agent captions, a mirrored reading direction, a stacked environment panel,
faster gutter travel and a different iPhone split:

```sh
npx tsx src/templates/19-graphic-storyboard/validation-props.ts
npm run render -- --template 19-graphic-storyboard \
  --props out/19-graphic-storyboard/validation/props.json \
  --output out/19-graphic-storyboard/validation/variant.mp4
npm run still -- --template 19-graphic-storyboard \
  --props out/19-graphic-storyboard/validation/props.json --frame 65 \
  --output out/19-graphic-storyboard/validation/caption-check.png
```

The shared CLI overwrites its top-level metadata/resolved-props even with a custom
output path. Render the default sample last to leave default metadata alongside
the final MP4. Keep diagnostic frames in their own subdirectory so they do not
enter the default contact sheet.

## Limits

The input recordings do not show iOS Simulator motion. The montage intentionally
labels Simulator stills and preserves source reports. User-edited layouts/copy
must be re-rendered and inspected; arbitrary long text or extreme panel
proportions are not automatically typeset. No soundtrack, public deployment,
browser testing or individual PR is part of this direction.
