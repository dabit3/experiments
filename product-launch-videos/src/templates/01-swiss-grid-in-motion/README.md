# 01 · Swiss Grid in Motion

A rigorous asymmetric composition: a 240px explanatory rail aligns with a
1520px product region. Large regular-weight NB International type and square
rules establish the grid. Source stills appear through horizontally expanding
rectangular regions; complete captions slide vertically within fixed masks.
Recordings cut into the established grid fully visible, with still typography
for their entire run. There are no gradients, shadows, perspective, elastic
motion, fabricated UI or simulated source interactions.

## Run

From `product-launch-videos/`, after `npm ci` and the shared authenticated asset
setup:

```sh
npm run assets:check
npm run templates:list
npm run lint
npm run typecheck
npx tsx --test src/templates/01-swiss-grid-in-motion/config.test.ts
npm run render -- --template 01-swiss-grid-in-motion
npm run still -- --template 01-swiss-grid-in-motion --frame 450
npm run still -- --template 01-swiss-grid-in-motion \
  --frames 45,119,128,180,330,450,600,750,960,1140,1199
npm run contact-sheet -- out/01-swiss-grid-in-motion
```

Independent entry: `src/templates/01-swiss-grid-in-motion/entry.tsx`.
Composition ID: `SwissGridInMotion`. Default: 1920 × 1080, 30fps, 40 seconds,
silent H.264. `defineTemplate` derives the duration from configuration.

## Editable inputs

Edit `config.ts`, or copy the complete `out/01-swiss-grid-in-motion/resolved-props.json`
to a new ignored file and pass `--props /absolute/path/to/props.json` to render
or still. Partial configuration objects are not merged.

- `copy`: feature, opening, benefit, all five product captions, pricing, CTA, URL.
- `durations`: opening/environment/agent/iPhone/web QA/iPad/closing seconds.
  Defaults: 4/5/4/9/7/6/5. Keep video trims within their genuine source duration.
- `media`: supplied asset selections, `framing.fit`, `anchorX`/`anchorY` (0–1),
  optional original-pixel `crop`, and video `sourceStartSeconds`.
- `brand`: canvas, ink, secondary ink, white, mat; font family, sizes, line
  heights, tracking; title spacing. The shared font gate loads original fonts.
  A changed font family must refer to one of the bundled registered families.
- `layout`: margins, gutters, media padding, caption height budget.
  `grid` positions the caption rail, header, footer, opening title, captions and
  flat rules. Caption rail width 210–340px is the intended adjustment range.
- `motion.panelRevealFrames`: horizontal media/CTA expansion, default 18.
  Recordings deliberately bypass this reveal so every source action is visible.
- `motion.panelTravel`: horizontal still-panel slide along the grid, default
  64px. This settles within the reveal; recordings do not move.
- `motion.typeRevealFrames`: caption/title mask duration, default 14.
  Recording captions are present and still from the first source frame.
- `motion.typeTravel`: vertical travel within the fixed mask, default 42px.
- `motion.regionStartWidth`: initial rectangular region fraction, default 0.28.
- `motion.iphoneSplit`: fraction of the iPhone scene given to the first still,
  default 0.5. Use at least two frames to show both; use several seconds each
  for readable reports.
- `editorial`: index labels and explicit still/recording/montage descriptions.

The `controls` descriptor lists the main editable fields for gallery discovery.
All config fields remain editable through typed source or full JSON props.
Keep longer copy within its allocated space; captions use the loaded font's
actual longest-word width and a conservative height budget. Their size remains
constant during product demonstrations.

## Source treatment

`attribution.json` records the default timeline. Shared provenance, hashes and
content constraints are in `../../shared/asset-manifest.json` and the project's
`MEDIA-ATTRIBUTION.md`. The source asset bundle and fonts stay ignored.

The environment crop removes only broad blank canvas around the composer and
hosted menu. All report screenshots and both recordings use full-frame contain,
preserving counts and controls. iPhone stills switch at 17.5 seconds; neither
source MP4 is iOS footage. The web QA clip always carries the shared **Web QA
example** footer, outside the recording. The footer explicitly identifies the
film as examples from separate sessions.

## Editable-config exercise

The local generator produces a complete 12-second JSON edit with changed opening,
environment caption, CTA, grid width, type size, crop anchor and reveal controls:

```sh
npx tsx src/templates/01-swiss-grid-in-motion/editability-props.ts
npm run render -- \
  --entry src/templates/01-swiss-grid-in-motion/entry.tsx \
  --composition SwissGridInMotion \
  --props out/01-swiss-grid-in-motion/editability-props.json \
  --output out/01-swiss-grid-in-motion/editability.mp4
npm run still -- \
  --entry src/templates/01-swiss-grid-in-motion/entry.tsx \
  --composition SwissGridInMotion \
  --props out/01-swiss-grid-in-motion/editability-props.json \
  --frame 80 --output out/01-swiss-grid-in-motion/editability.png
```

The direct-entry path keeps this diagnostic's metadata separate from the
default template's metadata. Expected diagnostic: 360 frames, 12 seconds at 30fps.
This short diagnostic is only an editability check; the main sample retains the
full shared seven-part 40-second edit.

## Validation

Validated on 2026-09-15:

- Full sample: H.264, 1920 × 1080, 30/1fps, 1200 frames, 40.000000 seconds;
  silent. `ffprobe` verified metadata and FFmpeg decoded the entire file without
  errors.
- Alternate configuration: H.264, 1920 × 1080, 30/1fps, 360 frames,
  12.000000 seconds. Full decode passed; frame 80 shows the changed environment
  caption and rail width.
- Lint, typecheck, Vite build, 8 shared/discovery TypeScript tests, 3 Python
  asset tests and 2 direction tests passed. All 45 original assets verified.
- Inspected rendered title, masked transitions, hosted menu, agent menu,
  both iPhone stills, web QA, iPad and CTA. Settled captions fit their rails;
  report counts and the persistent web QA label remain visible.
- The delivered poster is decoded frame 450. The contact sheet contains
  decoded frames 45, 128, 180, 330, 450, 525, 600, 750, 870, 888, 960 and 1140
  from the actual default MP4. Frames 128 and 870 deliberately show reveals
  in progress; their masks settle within 18 frames.

To verify an output:

```sh
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/01-swiss-grid-in-motion/01-swiss-grid-in-motion.mp4
ffmpeg -v error -i out/01-swiss-grid-in-motion/01-swiss-grid-in-motion.mp4 -f null -
```

Limitations: the supplied iOS examples are stills; only the agent and web QA
scenes contain source video. Reports are preserved in full, so fine text is best
viewed at full output resolution. Extreme layout values or substantially longer
titles need a fresh visual check. The 12-second diagnostic is too short for
reading all reports and is not a replacement for the default sample. Re-rendering
requires the separately supplied, ignored asset/font bundle.

Rendered artifacts remain in ignored `out/01-swiss-grid-in-motion/`; do not
commit binaries or publicly deploy the source media.
