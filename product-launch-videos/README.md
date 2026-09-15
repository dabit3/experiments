# Devin on Mac — 20 launch video templates

Editable 1920 × 1080 / 30 fps Remotion templates for the supplied Mac launch
montage. All **20 independent directions** are collected under `src/templates/`.
The default seven-scene timeline is 40 seconds; each design owns its composition,
configuration and motion. `src/smoke/` remains infrastructure verification only.

See [GALLERY.md](GALLERY.md) for the portable comparison gallery, authenticated
media rehydration, collection checks and packaging. `gallery-manifest.json` records
all producer commits, artifact URLs, SHA-256 hashes and independently measured
video metadata. Original fonts, source media and renders stay outside git.

## Local setup

Requirements: Node **22.12 or newer**, npm, Python **3.9 or newer**, and FFmpeg
(`ffmpeg` and `ffprobe` on PATH). The foundation was verified on Linux with Node
24.19.0. All direct npm dependencies are exact pins; all Remotion packages use
**4.0.522**, with React/React DOM **19.1.1**. Use the committed npm lockfile.

```sh
cd product-launch-videos
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run lint
npm run typecheck
npm test
npm run build
```

Download `shared-assets.zip` through the authenticated Devin conversation attachment
link, using the browser's Download action, then pass its local path above. In a
Devin session, use the already downloaded attachment or `download_attachment`.
Do not use unauthenticated curl against attachment URLs.

The installer requires the exact 45-file flat bundle. It verifies its inventory
and SHA-256 hashes before installing, then validates PNG/WOFF2 signatures and video
properties against `src/shared/asset-manifest.json`. Missing, changed, nested,
duplicate, or symlink entries fail. It installs the brief, original prompts and
brand reference alongside the media, so producers can read them locally:

- `public/assets/production-brief.md`
- `public/assets/brand-reference.md`
- `public/assets/pasted-1789430547875.txt`

`public/assets/`, `out/`, `.cache/`, `public/renders/`, and `dist/` are ignored.
Never commit source recordings, screenshots, fonts, generated frames, or MP4s.
`--record-manifest` is a foundation-maintenance operation for a deliberately
approved new bundle, not a producer setup flag.

## Producer integration

Read [TEMPLATE-CONTRACT.md](TEMPLATE-CONTRACT.md) before starting a direction.
Each producer adds exactly one `src/templates/<slug>/` directory. There is no
global registry to edit. The collector discovers manifests and the gallery
discovers descriptor exports automatically.

```sh
npm run templates:list
npm run render -- --template 01-swiss-grid-in-motion
npm run still -- --template 01-swiss-grid-in-motion --frame 150
npm run still -- --template 01-swiss-grid-in-motion --frames 0,150,330,450,600,750,960,1140
npm run contact-sheet -- out/01-swiss-grid-in-motion
```

Outputs are `out/<slug>/<slug>.mp4`, `poster.png`, `frame-000000.png` etc.,
`contact-sheet.png`, `metadata.json`, and `resolved-props.json`. Multiple-frame
stills use exact composition frame numbers at 30 fps. Change the selection when
changing durations; stale `frame-*.png` files should be moved before making a new
contact sheet. The contact sheet arranges the sorted actual rendered frames.

Render/still also accept any independent entry:

```sh
npm run render -- --entry src/templates/01-swiss-grid-in-motion/entry.tsx --composition SwissGridInMotion
npm run still -- --entry src/templates/01-swiss-grid-in-motion/entry.tsx --composition SwissGridInMotion --frame 150
```

Use `--props /path/to/props.json` for a complete `{"config": ...}` object. Copy
`resolved-props.json` from a first render/still, edit it, and pass it back. Props
are **not deeply merged**; do not pass a partial config. Editing the template's
`config.ts` is the primary authoring path. Both render and still evaluate
`calculateMetadata`, so duration edits change the actual composition length.

Additional options: `--output /path/to/file`, `--scale 1`, `--concurrency 2`.
Final deliverables use scale 1. Videos are silent H.264, yuv420p, CRF 18, at 1×
source speed. Out-of-bounds source trims fail rather than looping or freezing.

## Smoke verification

`src/smoke/entry.tsx` registers `FoundationSmoke`, using the complete 40-second
default configuration. It verifies original logos/fonts, all four selected
screenshots (two iPhone stills), and both supplied video files.

```sh
# Default timeline metadata and representative full-resolution PNG:
npm run still -- --entry src/smoke/entry.tsx --composition FoundationSmoke --frame 150

# An 8-second diagnostic edit, including nonzero source trims:
npm run smoke:props
npm run render -- --entry src/smoke/entry.tsx --composition FoundationSmoke \
  --props out/foundation-smoke/short-props.json
npm run still -- --entry src/smoke/entry.tsx --composition FoundationSmoke \
  --props out/foundation-smoke/short-props.json --frames 15,45,75,105,135,165,195,225
npm run contact-sheet -- out/foundation-smoke
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/foundation-smoke/foundation-smoke.mp4
```

Expected short-smoke result: **1920 × 1080, 30/1 fps, 240 frames, 8 seconds**.
The default smoke reports **1200 frames / 40 seconds**. The short edit is only a
diagnostic and must not replace the comparable 40-second producer samples.

## Local comparison gallery

```sh
npm run gallery
# Local development server on port 5173
npx remotion studio src/templates/01-swiss-grid-in-motion/entry.tsx
```

For a specific Remotion Studio entry, use
`npx remotion studio src/templates/01-swiss-grid-in-motion/entry.tsx` directly;
`npm run studio` alone opens the smoke entry. The comparison gallery plays the
final local MP4s on demand. Posters, search, a modal player, downloads, source
links, configuration/control metadata and the caption transcript support comparison.
It does not run 20 simultaneous Remotion Players or publish anything.

`npm run build` checks types and compiles the gallery. It intentionally does not
copy private `public` media into `dist`. `npm run gallery:package` adds only the
final render artifacts, comparison sheet, original Regular font, manifest and
template source copies to an ignored portable ZIP. See [GALLERY.md](GALLERY.md).
Gallery viewing needs no source recordings; editing/rendering requires the original
bundle. Do not publish the private source bundle.

## Content rules and attribution

See [MEDIA-ATTRIBUTION.md](MEDIA-ATTRIBUTION.md) and the local production brief.
Native app examples are authentic **stills from separate sessions**. Neither
video is Simulator footage. Source screenshots/reports must remain unchanged.
The web testing video component reserves a persistent **Web QA example** footer
outside the source image. Keep reports' failure and untested counts visible.

The font files block render completion until loaded; failure cancels the render.
Brand colors, typography, spacing, timeline, crop coordinates and source offsets
are configuration inputs. Direction-specific layout and motion belong to each
producer and are not imposed by the shared utilities.
