# 11 — Precision Paper Engineering

The opening is a folded title sleeve resting over a flat product carrier. It slides
off to reveal a recreated hosted environment selector. The cursor moves from
Ubuntu to macOS, clicks, and updates the selected checkmark and header. This
animation follows the user's supplied close-up reference and explicit request
to recreate the transition. Subsequent stills are uncovered by horizontal
sleeves or a vertical divider. Three slightly offset matte sheets, contact shadows,
and a narrow folded return give the carrier depth. Original screenshots never
bend, tilt, change color, or simulate app interaction. Only the separately authored
environment selector animates internal UI state.
For both recordings, the divider moves in the blank margin; the full recording is
already visible and stable from source frame zero. Captions stay on an aligned,
separate strip. The final assembly pairs the genuine Large Dispatch result with
the approved pricing and CTA.

## Setup and render

Run from `product-launch-videos/`, on foundation commit
`81abbc4d7f9ee2fefaa8467c940e465b61439ec4` or its collected successor:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run templates:list
npm run lint
npm run typecheck
npm test
npm run build
npm run render -- --template 11-precision-paper-engineering
npm run still -- --template 11-precision-paper-engineering --frame 60
npm run still -- --template 11-precision-paper-engineering \
  --frames 0,60,108,150,300,399,450,534,600,720,900,1060,1140
npm run contact-sheet -- out/11-precision-paper-engineering
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/11-precision-paper-engineering/11-precision-paper-engineering.mp4
```

The default is 1920 × 1080, 30 fps, 1,200 frames / 40 seconds, silent H.264.
Original media/fonts and outputs remain in the foundation's ignored
`public/assets/` and `out/` directories. No public deployment is required.

## Editability

Edit `config.ts`, or copy the complete generated
`out/11-precision-paper-engineering/resolved-props.json`, edit that copy, and pass
`--props /absolute/path/to/complete-props.json` to `render` or `still`.
Partial configs are not deep-merged. No global registry changes are necessary.

- `copy`: every shared caption, opening, benefit, pricing, CTA, and URL.
- `durations`: seven scene lengths in seconds. Metadata and sequence boundaries
  derive from these values at 30 fps; the iPhone split is proportional.
- `media`: original asset filenames, `framing.fit`, `anchorX`, `anchorY`, optional
  original-pixel `crop`, and video `sourceStartSeconds`. Reports default to contain
  with no crop. With `environmentSelector.enabled: false`, the static environment
  fallback uses x550/y430/w1900/h1000, retaining its real composer. Change
  `paper.labels.environment` to `Hosted environment` when using that fallback.
- `environmentSelector`: `enabled` chooses the recreated menu or original still;
  `width` sets the illustration width (automatically contained within its carrier).
  `moveAt` and `selectAt` are fractions of the environment scene, defaulting to
  0.20 and 0.52. The cursor starts on Ubuntu, moves to macOS, clicks, then exits.
  The active header and checkmark update together; an open menu holds the result.
  Timings scale with edited scene duration. The opening sleeve reveals a held
  Ubuntu state, so selection only begins in the environment scene.
- `brand.colors` and `brand.typography`: presentation colors, supplied font family,
  heading/body sizes, line heights, and tracking. NB International Regular is the
  primary face; Geist Mono appears only in editorial indices. The shared font
  gate awaits the original WOFF2s; no network fonts or silent substitutions.
- `layout`: margin, gutter, carrier padding, caption height, `grid.mediaTop`,
  `grid.captionGap`, and `grid.captionIndexWidth`.
- `paper`: sheet count/offsets, folded margin width, shadow strength, very faint
  paper-only texture, title width, result-card width, caption and label sizes,
  and honest source-context labels.
- `motion`: sleeve and title-slide frames, divider lift, blank-paper fold angle,
  iPhone split ratio, and left/right sleeve direction. Motion uses deterministic
  smoothstep easing and caps reveal time in short scenes; no bounce or CSS clock.

Keep caption copy short enough for its reserved strip. For longer copy, reduce
`paper.captionSize` or enlarge `layout.captionHeight`. Typography remains still
during all demonstrations. Source videos always run at 1×, and the shared primitive
rejects durations/trims exceeding the real clip. Do not hide failed/untested counts.
The Web QA footer is mandatory and independent of editable secondary captions.
The closing result is a thumbnail of an earlier full-size still, not new evidence.

## Alternate configuration check

The local diagnostic uses a 12-second edit, a different environment caption,
rightward sleeves and weaker shadows. To generate the complete JSON:

```sh
mkdir -p out/11-precision-paper-engineering/alternate
node --input-type=module -e '
import {readFileSync, writeFileSync} from "node:fs";
const p = JSON.parse(readFileSync("out/11-precision-paper-engineering/resolved-props.json", "utf8"));
p.config.durations = {opening:1, environment:2, agent:1, iphone:3, webQa:2, ipad:2, closing:1};
p.config.copy.environment = "Select your hosted Mac.";
p.config.motion.sleeveDirection = "right";
p.config.paper.shadowStrength = 0.08;
writeFileSync("out/11-precision-paper-engineering/alternate/props.json", JSON.stringify(p,null,2));
'
npm run render -- --template 11-precision-paper-engineering \
  --props out/11-precision-paper-engineering/alternate/props.json \
  --output out/11-precision-paper-engineering/alternate/alternate.mp4
npm run still -- --template 11-precision-paper-engineering \
  --props out/11-precision-paper-engineering/alternate/props.json --frame 60 \
  --output out/11-precision-paper-engineering/alternate/caption.png
```

Expected metadata: 360 frames / 12 seconds. The renderer's metadata and
resolved-props files are overwritten for each invocation, even with `--output`;
render the default last when preparing collection artifacts.

## Source map and content limits

`attribution.json` records each selected original, sample times, crop and treatments,
plus the supplied reference URL for the recreated selector. `EnvironmentSelector.tsx`
draws approximate icons and UI in SVG/React; no screenshot or new dependency is
required for that illustration. The reserved caption strip identifies it as an
animated recreation. All other demonstrations retain their original source pixels.
The shared asset manifest provides provenance and hashes; `MEDIA-ATTRIBUTION.md`
contains source restrictions. The montage uses separate sessions. Both native app
examples are screenshots; neither supplied video is Simulator footage. The first
iPhone report retains **8 passed / 0 failed / 1 untested**. No unrelated customer
logos, fabricated outcomes, signing, physical device, or publishing claims appear.

## Original delivery validation

- `assets:check`: all 45 bundled originals passed hash and format checks.
- `lint`, `typecheck`, `templates:list`, and `build` passed. The foundation test
  suite passed all 8 TypeScript and 3 Python tests.
- Full sample rendered and decoded without errors: H.264, 1920 × 1080,
  30/1 fps, 1,200 frames, exactly 40 seconds, no audio stream.
- Inspected 13 Remotion stills across the opening, sleeves, both recordings,
  all native examples and closing. Inspected the encoded movie's extracted
  contact sheet and its full-size Afterhours frame; the untested count is retained.
- The alternate edit rendered at 1920 × 1080, 30/1 fps, 360 frames / 12 seconds.
  Its changed caption was visually verified. Default metadata was restored
  afterward by rendering the default poster at frame 60.
- The delivered small contact sheet uses 12 frames decoded directly from the
  final MP4: 60, 108, 150, 300, 399, 450, 534, 600, 720, 900, 1060 and 1140.
  The source examples are unchanged; transitions intentionally cover part of
  stills temporarily. Active recordings are never covered.

## Ubuntu-to-macOS revision validation

- ESLint and TypeScript passed on the revised source. The foundation's 8
  TypeScript tests, 3 Python tests, and Vite build also passed.
- Full revised render: `ubuntu-to-macos-revision.mp4`, H.264, 1920 × 1080,
  30 fps, 1,200 frames / 40 seconds, no audio. Full FFmpeg decode passed.
- The standalone `ubuntu-to-macos-closeup.mp4` contains output seconds 4–9,
  verified at 1920 × 1080, 30 fps, 150 frames / 5 seconds.
- Inspected the opening reveal, Ubuntu selection, macOS hover, click frame,
  updated header/checkmark, final macOS hold and complete montage contact sheet.
  The header and checkmark switch on the same frame, without two selected rows.
- A 12-second edit changed the environment scene to 2 seconds, caption to
  “Select your hosted Mac.”, menu width to 900, movement start to 0.1 and selection
  to 0.6. It rendered at 1920 × 1080, 30 fps, 360 frames. Its selected state and
  changed caption were visually verified.
- Updated poster: `selector-poster.png`, frame 210. The revised contact sheet in
  `selector-contact-frames/contact-sheet.png` uses frames decoded from the full
  revised MP4: 60, 120, 180, 197, 210, 269, 300, 450, 600, 720, 900 and 1140.

Revision artifacts are under the same ignored `out/11-precision-paper-engineering/`
directory. To render the updated source to the revision filename:

```sh
npm run render -- --template 11-precision-paper-engineering \
  --output out/11-precision-paper-engineering/ubuntu-to-macos-revision.mp4
npm run still -- --template 11-precision-paper-engineering --frame 210 \
  --output out/11-precision-paper-engineering/selector-poster.png
```

To reproduce the original contact-sheet frame selection after a full render:

```sh
mkdir -p out/11-precision-paper-engineering/contact-frames
ffmpeg -hide_banner -loglevel error \
  -i out/11-precision-paper-engineering/11-precision-paper-engineering.mp4 \
  -vf "select='eq(n,60)+eq(n,108)+eq(n,150)+eq(n,300)+eq(n,399)+eq(n,450)+eq(n,534)+eq(n,600)+eq(n,720)+eq(n,900)+eq(n,1060)+eq(n,1140)'" \
  -vsync 0 out/11-precision-paper-engineering/contact-frames/frame-%06d.png
npm run contact-sheet -- out/11-precision-paper-engineering/contact-frames
```

Limitations: original screenshots and fonts must be installed from the private
bundle. Detailed result paragraphs are intended for full-resolution viewing;
the contact sheet and closing thumbnail are orientation images. Longer custom
copy may require adjusting the exposed caption size/height. This is media render
validation, not live iOS app testing.
