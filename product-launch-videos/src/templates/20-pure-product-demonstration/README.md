# 20 · Pure Product Demonstration

An intentionally quiet, product-led 16:9 edit. The motion vocabulary is one
deliberate settings reframe, native cursor movement in genuine recordings, and
clean source cuts. Captions do not move during demonstrations. Native app reports
remain complete, stationary and explicitly labeled as stills. The iPad result
holds for six seconds before the minimal pricing/CTA page.

The complete direction is in the supplied, ignored
`public/assets/pasted-1789430547875.txt`, section 20. The verified brand reference
is `public/assets/brand-reference.md`. This template uses the shared font gate,
source primitives, tokens, duration calculation and original assets.

## Set up and render

From `product-launch-videos/`, with Node >=22.12, Python >=3.9 and FFmpeg:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run templates:list
npm run render -- --template 20-pure-product-demonstration
npm run still -- --template 20-pure-product-demonstration --frame 570
npm run still -- --template 20-pure-product-demonstration \
  --frames 0,119,120,153,180,269,270,330,389,390,524,525,659,660,750,869,870,960,1049,1050,1140,1199
npm run contact-sheet -- out/20-pure-product-demonstration
```

Independent entry: `src/templates/20-pure-product-demonstration/entry.tsx`.
Composition ID: `PureProductDemonstration`. Default video: **1920 × 1080, 30 fps,
1200 frames, 40 seconds**, silent H.264. Output files, the original assets and
font binaries are ignored and must remain outside git.

## Edit the template

`config.ts` exports the typed `PureProductConfig`. Every field is serializable.
After a render, copy the complete `out/20-pure-product-demonstration/resolved-props.json`,
edit it, and render with `--props /absolute/path/to/your-props.json`. Supply
`{"config": <complete config>}`; props are not deeply merged.

| Input | Purpose |
| --- | --- |
| `copy.*` | Opening, feature, benefit, each scene caption, pricing, CTA, URL |
| `durations.*` | Seven scene durations in seconds; metadata and source cuts both update |
| `media.*.asset` | Swap for another verified shared image or video |
| `media.iphone[0/1]` | Two configurable screenshot states, always separately labeled |
| `media.*.framing` | Contain/cover, normalized placement anchors, original-pixel crop |
| `media.agent.sourceStartSeconds`, `media.webQa.sourceStartSeconds` | Clip in-points; out-point = in-point + that scene's duration |
| `motion.environmentZoom` | Detail reframe scale, default 1.16; set 1 for no zoom |
| `motion.environmentAnchorX/Y` | Focus inside the configured crop, normalized 0–1 |
| `motion.environmentContextSeconds` | Initial context hold, default 0.8 s |
| `motion.environmentMoveSeconds` | Smoothstep reframe, default 0.6 s |
| `motion.iphoneFirstFraction` | First still's share of the iPhone scene, default 0.5 |
| `labels.*` | Source/still disclosures and speed-label prefix |
| `brand.colors`, `brand.typography`, `brand.spacing.titleGap` | Shared neutral palette, family, size, tracking, line-height and title gap |
| `typography.*` | Caption, disclosure and CTA sizes |
| `layout.margin/gutter/padding/captionHeight` | Source bounds and reserved caption/footer space |
| `layout.grid.footerHeight/webQaLabelHeight/captionInset` | Bottom note height, required QA label height and caption alignment |
| `titleLayout.*` | Title inset, logo width, heading position/width and URL gap |

The environment hold and reframe each cap at one quarter of the scene, leaving
at least its latter half static even after duration edits. The iPhone scene
requires at least two frames so both source stills are presented. For readable
final edits, give each still several seconds.

All recordings remain **1×** through the shared `SourceVideo`. The speed-label
prefix is editable, while the true `1×` suffix remains fixed. Extending a video
scene must stay within its actual clip length; invalid source trims fail instead
of looping or freezing. There is no compressed waiting in this sample and no
synthetic cursor. The permanent **Web QA example** label is owned by the shared
source primitive.

When changing report crops, inspect the full-resolution render to ensure every
failed/untested count remains visible. Default report views have no crop or zoom.
Source edits are a montage of independent sessions, not one app-building run.

## Source map

`attribution.json` records each asset's default output interval, exact clip range
and source-pixel crop. Shared provenance and original-file hashes live in
`../../shared/asset-manifest.json` and the project's `MEDIA-ATTRIBUTION.md`.
Original artwork retains its aspect ratio and source UI colors. Only the
regular NB International font is used in the composition; shared infrastructure
also preloads the supplied Light and Geist Mono companion fonts.

## Validation

```sh
npm run lint
npm run typecheck
npm test
npx tsx --test src/templates/20-pure-product-demonstration/edit.test.ts
npm run build
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/20-pure-product-demonstration/20-pure-product-demonstration.mp4
```

The local tests cover edited scene boundaries, two-still preservation,
deterministic bounded reframing, short-scene settling and disabled zoom.

### Non-default edit check

```sh
npx tsx src/templates/20-pure-product-demonstration/validation-props.ts
npm run render -- --template 20-pure-product-demonstration \
  --props out/20-pure-product-demonstration/validation/props.json \
  --output out/20-pure-product-demonstration/validation/custom.mp4
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/20-pure-product-demonstration/validation/custom.mp4
```

This writes a complete 13-second configuration with seven changed durations,
the caption “Select your hosted Mac environment.”, shifted video in-points,
a 1:2 iPhone still split and faster editorial reframing. Expected output:
1920 × 1080, 30 fps, 390 frames. This is an editability check; its abbreviated
holds are not the launch sample. The shared renderer writes metadata and
resolved props into the template's main output directory even with `--output`;
save those files first or render the default sample again afterward.

### Measured delivery validation

Validated on 2026-09-15 with Node 24.19.0 and the pinned shared dependencies:

- ESLint, TypeScript, Vite build and template discovery passed.
- All 14 tests passed: 8 shared/CLI TypeScript, 3 shared Python and 3 local tests.
- Default MP4: H.264, **1920 × 1080, 30/1 fps, 1200 frames, 40.000 seconds**.
- Custom MP4: H.264, **1920 × 1080, 30/1 fps, 390 frames, 13.000 seconds**.
- Both files decoded completely through FFmpeg without errors.
- Full-resolution rendered stills and frames extracted from the encoded MP4
  were inspected across all scenes and either side of every source cut.
  The first iPhone report retains **8 passed, 0 failed, 1 untested**.
  The Web QA label and 1× playback labels stay outside source pixels.
- The custom video visibly uses its replacement caption, edited scene cuts,
  shifted source ranges and changed still split.
- The delivered poster is encoded-video frame 570. The contact sheet contains
  encoded-video frames 0, 120, 153, 269, 270, 330, 450, 570, 660, 750, 960, 1140.

The custom render emitted a Chromium `Page.bringToFront: Target closed` warning
at the end, then returned success. Its verified complete frame count and clean
FFmpeg decode are reported above. Source UI screenshots include their original
player controls and screenshot edge pixels without retouching.

## Limits

The source provides iPhone/iPad screenshots, not Simulator recordings. This edit
does not simulate internal app motion or imply the web recording demonstrates
iOS. Some fine source UI text is necessarily smaller after a 2980px-wide still
is fitted into a 1920px composition; preserve the complete report and render at
full scale. Long replacement captions may require more caption height or a
smaller caption size; review representative frames after copy/layout edits.
No soundtrack, public deployment or browser UI testing is part of this template.
