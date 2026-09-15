# 09 · Optical Laboratory

A restrained observation desk: one full interface establishes context, then
recedes laterally to make room for one outlined source crop. A fine elbow leader
connects the crop to its exact original rectangle. Neither panel distorts pixels.
Annotations live in a dedicated margin. The interface returns to the complete
view at each reading stop; the final scene keeps the complete iPad result.

The seven-scene sample is 40 seconds at 1920 × 1080, 30 fps. The iPhone examples
are two separate stills, not one build sequence. The test recording always says
**Web QA example**, including beneath the magnified copy. Both recordings run at
1× and share the exact same source time in the context and inspection view.

## Setup and render

From `product-launch-videos/`, use the foundation's pinned dependencies:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run lint
npm run typecheck
npm test
npm run build
npm run render -- --template 09-optical-laboratory
npm run still -- --template 09-optical-laboratory --frame 195
npm run still -- --template 09-optical-laboratory \
  --frames 0,60,120,156,195,285,330,480,615,675,720,795,930,1020,1110,1199
npm run contact-sheet -- out/09-optical-laboratory
```

The independent Remotion entry is `entry.tsx`, composition `OpticalLaboratory`.
The shared renderer derives duration from all seven configured durations.
No browser, public deployment, external font service, or additional dependency
is necessary. All originals and output files remain in ignored directories.

## Editing

Edit `config.ts`, or copy the generated `out/09-optical-laboratory/resolved-props.json`
and supply the complete `{"config": ...}` object:

```sh
npm run render -- --template 09-optical-laboratory --props /path/to/edit.json \
  --output out/09-optical-laboratory/custom.mp4
```

- `copy`: title, benefit, five demonstration captions, pricing, CTA, URL.
- `durations`: seconds per scene. Video duration plus source offset must remain
  within the original recording; overrun throws instead of freezing or looping.
- `media`: original asset selections, source start seconds, and context fit/crop
  anchors. Complete report views should use `contain`.
- `focus.<scene>.crop`: x/y/width/height in **original source pixels**, independent
  of output resolution. Change these when changing assets. A crop outside the
  context crop fails validation. Use only meaningful source content.
- `focus.<scene>.annotation` and `sourceNote`: text in the left margin.
- `brand`: all shared colors, fonts, tracking, line-height, and type sizes.
  Original fonts are loaded by `defineTemplate` before rendering.
- `layout`: margin, gutter, padding, caption position; `grid` exposes context and
  inspection dimensions/positions plus caption, annotation, index, and logo sizes.
- `labels`: editable editorial labels and source qualifications.
- `motion.contextHoldSeconds`: full-context reading time before inspection.
- `motion.revealFrames`: frames per phase of the deterministic lateral move
  followed by the detail reveal. Detail closes before context expands again.
- `motion.returnSeconds`: return to the full interface at the end of a segment.
- `motion.iphoneSplit`: ratio of the nine-second iPhone scene assigned to the
  first still; keep both examples long enough to read.
- `motion.outlineWidth` and `connectorOpacity`: understated editorial line work.
- `motion.maxSourceScale`: maximum output pixels per source pixel; hard-capped
  at 1. Magnification enlarges the reduced context without synthesizing detail.

Context/reveal/return timings adapt to shorter configured scenes. Typography is
stationary during demonstrations. Crop coordinates and frames describe editorial
framing, not product controls, optical measurements, or execution telemetry.
Maintain room for custom longer captions and inspect frames after layout edits.

## Provenance and limits

`attribution.json` maps the default timeline, original crops, logos and fonts.
The shared `MEDIA-ATTRIBUTION.md` and asset manifest retain exact provenance.
No source binary, screenshot, font or rendered artifact is committed.
Reports stay intact in the context view, including the Afterhours Maze untested
count. Its note repeats the exact 8 passed / 0 failed / 1 untested qualification.
Source screenshots have a finite resolution; the inspection scale cap is deliberate.
There is no soundtrack and no simulated interaction inside native app stills.

## Validation

Validated with the supplied 45-file asset bundle:

- `npm run lint`, `npm run typecheck`, `npm test` (8 TypeScript and 3 Python
  tests), template discovery, and `npm run build` passed.
- Full default H.264 MP4: **1920 × 1080**, **30/1 fps**, **1200 frames**,
  **40.000000 seconds**. `ffprobe -count_frames` decoded all 1200 frames and
  a complete `ffmpeg -v error -i <video> -f null -` pass reported no errors.
- Sixteen full-resolution stills cover the opening, context-to-detail changes,
  both iPhone examples, both video segments, iPad and CTA. Poster is frame 195.
  Contact sheet is assembled from actual Remotion-rendered PNGs.
- Inspected the supplied font, proportional logo, focus rectangles, captions,
  report qualifications, persistent Web QA labels, and final complete result.
- A complete alternate MP4 with durations `{opening:2, environment:2, agent:1,
  iphone:2, webQa:1, ipad:1, closing:2}` produced **330 decoded frames /
  11.000000 seconds** at 1920 × 1080 / 30 fps. Its edited opening, “Devin on
  Mac.”, was checked in a rendered still. This short variant checks editability;
  the default 40-second version supplies the intended readable holds.

To reproduce the alternate configuration, start with the default resolved props:

```sh
jq '.config.durations = {opening:2, environment:2, agent:1, iphone:2, webQa:1, ipad:1, closing:2}
    | .config.copy.opening = "Devin on Mac."
    | .config.focus.environment.annotation = "Hosted Mac, ready to choose"' \
  out/09-optical-laboratory/resolved-props.json \
  > out/09-optical-laboratory/edited-props.json
npm run render -- --entry src/templates/09-optical-laboratory/entry.tsx \
  --composition OpticalLaboratory \
  --props out/09-optical-laboratory/edited-props.json \
  --output out/09-optical-laboratory/edited-config.mp4
```

The direct-entry command writes its metadata under `out/optical-laboratory/`,
leaving the default sample's metadata untouched. Validation used the bundled
headless renderer and image inspection; no browser UI testing was performed.
The full render logged a `Page.bringToFront: Target closed` warning near completion
but exited successfully; independent decoding verified the complete output.
