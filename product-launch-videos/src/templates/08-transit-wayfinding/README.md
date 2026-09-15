# 08 · Transit Wayfinding

A neutral transit identity with one route, six numbered stations, marker-origin
rectangular reveals, and a compact route strip that stays outside the source UI.
The large route appears during the opening/closing and briefly at arrivals.
No floating cards, simulated operating-system UI, invented telemetry or branches.
The route is explicitly an editorial montage of **separate sessions**.

## Run

From `product-launch-videos/`, use the foundation's pinned dependencies and
authenticated local asset bundle:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run templates:list
npm run lint
npm run typecheck
npm test
npm run build
npm run render -- --template 08-transit-wayfinding
npm run still -- --template 08-transit-wayfinding --frame 450
npm run still -- --template 08-transit-wayfinding --frames 0,80,128,180,300,450,600,720,930,1130
npm run contact-sheet -- out/08-transit-wayfinding
```

Independent entry: `src/templates/08-transit-wayfinding/entry.tsx`.
Composition: `TransitWayfinding`. Default: 1920 × 1080, 30 fps, 1200 frames /
40 seconds; silent H.264 MP4. Outputs go to ignored `out/08-transit-wayfinding/`.
No media, fonts, renders, or extracted source files are tracked.

## Edit

`config.ts` is the typed, JSON-serializable authoring surface. `index.ts` exposes
the direction's route/motion controls for the collector. All shared inputs remain
available:

| Input | Use |
| --- | --- |
| `copy` | Opening, benefit, station captions, pricing, CTA and URL |
| `durations` | Seven scene durations in seconds; metadata and sequence positions recompute |
| `media` | Shared asset IDs, source trims, `framing.fit`, normalized anchors and optional original-pixel crops |
| `brand.colors` | Approved canvas, ink, secondary ink, white, and media-mat tokens |
| `brand.typography` | Loaded family, companion family, heading/body sizes, line heights and tracking |
| `brand.spacing.titleGap` | Title/benefit vertical gap |
| `layout` | Margin, gutter, media padding, header/caption height |
| `layout.grid` | Route footer height, title width, intro map vertical position |
| `route.code`, `route.legend`, `route.stillLabel`, `route.departureLabel`, `route.destinationLabel` | Route badge, source disclosures and endpoint captions |
| `route.stations` | Six stations: scene ID, editable name, normalized x/y coordinates; adjacent points connect orthogonally |
| `motion.arrivalFrames` | Rectangular expansion from the station's map coordinates |
| `motion.mapHoldFrames` | Brief map pause before expansion |
| `motion.lineTraceFrames` | Opening line trace toward the first action |
| `motion.lineWidth`, `motion.markerRadius` | Route geometry in composition pixels |
| `motion.iphoneSplit` | Fraction of the iPhone scene occupied by the first still |

Keep one station for each non-opening scene in the shared narrative order.
Default station x coordinates leave room for labels; use short names. y coordinates
control route shape without adding unsupported branches. Preserve disclosure
labels when substituting clips from different kinds of sessions.

For JSON overrides, first copy the complete `config` object from the render's
`resolved-props.json`, edit it, then:

```sh
npm run render -- --template 08-transit-wayfinding --props /absolute/path/to/props.json
```

Props are complete, not deeply merged. Keep video durations within original clip
lengths after source offsets; shared `SourceVideo` rejects overruns and enforces 1×.
Use uncropped contain framing for report evidence so failed/untested counts stay
visible. Large text edits may need smaller typography or a taller caption region.

## Timing and source fidelity

The seven scenes retain the supplied default boundaries: 0, 4, 9, 13, 22, 29, 35,
40 seconds. The two supplied recordings begin playback at exactly 9 and 22 seconds,
from source 0. Their first frames are frozen during a short arrival **before**
those boundaries, so no source action is hidden by an expanding mask. Playback
is then uninterrupted at 1× for the full requested 4 and 7 seconds.

The environment still uses an original-pixel crop at x=550, y=400, width=1900,
height=1040. It keeps the entire composer and hosted menu while removing empty
page margins. All other product sources use full uncropped contain framing.

The iPhone section cuts at 17.5 seconds between unchanged stills from separate
sessions. The report containing **8 passed, 0 failed, 1 untested** stays intact.
The iPad section is also an unchanged still. Captions and route indicators
remain still during product holds; all composition motion is frame-driven.
`Web QA example` is a permanent reserved footer supplied by `SourceVideo`.

`attribution.json` lists each actual source use and default timing; shared
`MEDIA-ATTRIBUTION.md` and `src/shared/asset-manifest.json` hold provenance/hashes.
The logo uses the original black transparent asset without redrawing/stretching.
NB International Regular and the editorial Geist Mono indices use original WOFF2
files through the foundation's render-blocking font gate.

## Editability diagnostic

This intentionally short edit is only a configuration test, not the comparison film:

```sh
npx tsx src/templates/08-transit-wayfinding/editability-check.ts
npm run render -- --template 08-transit-wayfinding \
  --props out/08-transit-wayfinding/editability/props.json \
  --output out/08-transit-wayfinding/editability/edited.mp4
npm run still -- --template 08-transit-wayfinding \
  --props out/08-transit-wayfinding/editability/props.json --frame 90 \
  --output out/08-transit-wayfinding/editability/edited-caption.png
```

Expected: 390 frames / 13 seconds, changed environment caption, renamed `Hosted Mac`
station, and shorter arrival timing. These commands update the shared output
metadata; run the default render afterward to restore the default metadata/props.

## Validation

Run `ffprobe -v error -select_streams v:0 -show_entries
stream=width,height,r_frame_rate,nb_frames:format=duration -of json
out/08-transit-wayfinding/08-transit-wayfinding.mp4`.

Inspect full-resolution representative frames and the contact sheet for source
fidelity, proportional logo sizing, readable captions and report counts. Output
artifacts are delivered separately; do not commit them.

The completed default render was verified as 1920 × 1080, 30/1 fps, 1200 frames,
40.000 seconds. The edited configuration rendered a complete 1920 × 1080,
30/1 fps, 390-frame, 13.000-second diagnostic; its changed caption was inspected.
Lint, typecheck, the eight shared TypeScript tests, three Python tests, asset
verification and the Vite build passed. The build emits a non-fatal upstream
Remotion Player `use client` directive warning.

Limitations: supplied native examples are still screenshots rather than Simulator
recordings. Full source UI is scaled proportionally to fit the reserved space;
the output cannot make every small source paragraph readable at thumbnail size.
Source selection and claims remain the supplied launch montage.
