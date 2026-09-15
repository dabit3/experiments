# 02 · Precision Industrial Product Film

A controlled, neutral studio composition: the authentic macOS menu opens in close
detail beside a quiet title, then the camera pulls back to reveal its entire
interface on a thin matte plane. Exterior lighting and restrained shadows supply
depth. A shallow 1.8° yaw occurs only during the environment and closing moves.
Both recordings and all native demonstration holds stay front-facing and still.
The closing move retains the actual iPad result beside the CTA.

## Render

From `product-launch-videos/`, with Node >=22.12, npm, Python and FFmpeg:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run render -- --template 02-precision-industrial-product-film
npm run still -- --template 02-precision-industrial-product-film --frame 0
npm run still -- --template 02-precision-industrial-product-film --frames 0,90,135,210,330,450,600,750,960,1080,1140,1199
npm run contact-sheet -- out/02-precision-industrial-product-film
npm run lint
npm run typecheck
npm test
npm run build
```

The output is silent H.264, 1920×1080, 30 fps, 40 seconds / 1200 frames.
`entry.tsx` also works independently in Remotion Studio with composition ID
`PrecisionIndustrialProductFilm`. No shared registry edits are needed.

## Editing

Edit the typed `config.ts`, or copy the generated `resolved-props.json`, change
the complete `config` object, and supply `--props /absolute/path/to/props.json`.
Partial configs are not deeply merged. All configuration is JSON serializable.

| Input | Effect |
|---|---|
| `copy.*` | Opening, benefit, each scene caption, pricing, CTA, and URL |
| `durations.*` | Seven scene lengths in seconds; Remotion metadata derives their sum |
| `media.*.asset` | Original filename from the shared source manifest |
| `media.*.framing` | `contain`/`cover`, normalized anchors, optional crop in original source pixels |
| `media.agent.sourceStartSeconds`, `media.webQa.sourceStartSeconds` | Independent source offsets; playback remains 1× and overrun is rejected |
| `camera.opening`, `camera.closing` | Output pixel rectangles: x, y, width, height |
| `camera.detailCrop`, `camera.contextCrop` | Source pixel crop rectangles for the menu pullback; update with replacement source dimensions |
| `lighting.keyX/keyY` | Key light position in canvas percent |
| `lighting.keyStrength/falloffStrength` | White studio light and dark falloff opacity, 0–1 |
| `lighting.shadowOpacity/shadowBlur/shadowDrop` | Plane shadow, outside the UI, 0–1 opacity and output pixels |
| `motion.detailHoldFraction/pullbackEndFraction` | Pullback start/end fractions of the opening duration |
| `motion.settleFrames` | Environment detail-to-wide settling time, capped to a third of that scene |
| `motion.transitionTiltDegrees/perspective` | Shallow transition-only yaw and perspective distance; set yaw to zero for a fully flat edit |
| `motion.iphoneSplit` | Fraction of the iPhone scene occupied by its first genuine still |
| `motion.closingTravelFrames` | Closing camera move, capped to a third of its scene |
| `brand.colors/typography/spacing` | Original shared brand tokens; spacing.titleGap separates opening title/benefit |
| `layout.margin/gutter/padding/captionHeight/grid` | Outer margin, caption gap, plane edge thickness, header space and editorial baselines |
| `typography.*` | Direction-specific sizes, opening text width and closing text column geometry |
| `labels.*` | Exterior source descriptions, still identifiers and montage disclosure |

Use the supplied font family names; `defineTemplate` waits for the original
WOFF2 files to load and fails on missing fonts. Do not replace brand fonts with
network requests. Keep captions within the reserved header/side areas when
making substantial copy changes. The descriptor lists editable control paths;
the shared gallery displays this metadata rather than interactive input widgets.

## Edit and source fidelity

The default edit is 4/5/4/9/7/6/5 seconds. Agent footage uses seconds 0–4; web QA
uses seconds 0–7. Native app footage is explicitly labeled as stills from separate
sessions. The Afterhours Maze report retains **8 passed, 0 failed, 1 untested**.
No source states, logs, passing results or simulator motion are fabricated.
The shared video primitive reserves the persistent **Web QA example** footer.

`attribution.json` maps default output intervals to original sources and crops.
Source provenance and hashes are in the foundation's `MEDIA-ATTRIBUTION.md` and
`src/shared/asset-manifest.json`. Font and source binaries remain in ignored
`public/assets/`; rendered outputs remain in ignored `out/`. The opening also
uses the same menu screenshot to satisfy this direction's detail-first framing.

## Validation

Run the full render and ffprobe:

```sh
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/02-precision-industrial-product-film/02-precision-industrial-product-film.mp4
```

The reproducible 16-second diagnostic changes scene durations, two captions,
shadow opacity, transition yaw and iPhone split while retaining normal source
speed:

```sh
npx tsx src/templates/02-precision-industrial-product-film/make-diagnostic.ts
npm run render -- --template 02-precision-industrial-product-film \
  --props out/02-precision-industrial-product-film/diagnostic/props.json \
  --output out/02-precision-industrial-product-film/diagnostic/edited.mp4
npm run still -- --template 02-precision-industrial-product-film \
  --props out/02-precision-industrial-product-film/diagnostic/props.json \
  --frame 105 --output out/02-precision-industrial-product-film/diagnostic/edited-caption.png
```

The diagnostic should report **480 frames / 16 seconds**. The shared render CLI
writes `metadata.json` and `resolved-props.json` at the template output root even
with `--output`; a final default still restores those files to the default edit.
Both sample renders were verified with ffprobe and decoded without errors:
the default is 1200 frames / 40 seconds and the diagnostic is 480 frames /
16 seconds, both H.264 at 1920×1080, 30 fps. Lint, TypeScript, all 11 foundation
tests, asset verification, template discovery and the production build passed.
Full-size frames across the default edit and the diagnostic's edited caption
and CTA were visually inspected. The delivered poster is default frame 0.
Always regenerate the contact sheet after changing frame selection or durations;
it must contain genuine rendered frames. Source detail, film transitions, both
recordings, report counts and the final CTA require representative full-size
frame inspection. A shorter diagnostic edit should change both copy and duration
without replacing the shared 40-second final sample.

## Limits

This is an editorial montage of independent examples, not a continuous app build.
It makes no claims about physical devices, signing or App Store publishing.
Small source-report prose is densest in the closing thumbnail; its complete
large view is held for six seconds immediately before the close. Increasing
video durations past the original source range fails instead of freezing/looping.
No soundtrack, public deployment or browser UI testing is part of this template.
