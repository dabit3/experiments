# 13 · One Continuous Camera Journey

A 16:9 Devin launch video built as a single camera move across one flat canvas.
There are no scene cuts: every station (opening statement, product overview, key
interaction, supporting detail, real result, CTA) is laid out left-to-right on a
paper-coloured canvas, connected by an accent route line. The camera travels
briefly (~1.1s, ease in-out) between stations, then stops and holds a large,
front-facing recording or screenshot with its caption anchored beside it.

- Composition `Launch`, 1920×1080 @ 30fps, duration derived from `scenes`
  (default 1350 frames = 45s). `Poster` renders the mid-demo frame.
- Media is served from `launch-videos/assets/` via `Config.setPublicDir("../../assets")`
  and `staticFile()`. Nothing is copied into this directory.
- No audio. No dependencies beyond remotion, `@remotion/*`, react, zod, typescript, eslint.

## Scripts

```sh
npm install                # first time; if the browser download fails: npx remotion browser ensure
npm run dev                # Remotion Studio
npm run render             # out/launch.mp4
npm run still              # out/poster.png (Poster composition = middle of the "taps" hold)
npm run typecheck
npm run lint
```

## Scene table (default props)

| # | Station id | Kind    | Canvas x | Travel in | Hold           | Media                                                     | Caption / copy |
|---|------------|---------|---------:|----------:|---------------:|-----------------------------------------------------------|----------------|
| 0 | `opening`  | opening | 0        | 0         | 110f (3.7s)    | Devin logo                                                | `New` · Devin on Mac · "Devin now runs in a **Mac VM**" · subhead |
| 1 | `pick`     | media   | 2000     | 34f       | 160f (5.3s)    | `screenshots/devin-web-1.png` → cross-fade to `devin-web-4.png` (OS dropdown open) | "Pick macOS when you start a session — same price as Linux." |
| 2 | `build`    | media   | 4000     | 34f       | 210f (7.0s)    | `recordings/devin-working-4.mp4`                          | "Devin builds the app in Xcode and runs the full test suite." |
| 3 | `taps`     | media   | 6000     | 34f       | 226f (7.5s)    | `recordings/androidios.mp4`, cropped to the iPhone Simulator | "It taps, types, and scrolls through the app like a person." |
| 4 | `verify`   | media   | 8000     | 34f       | 210f (7.0s)    | `recordings/devin-testing-2.mp4` (6 passed / 0 failed)    | "Reproduce a bug, fix it, and prove the fix on screen." |
| 5 | `result`   | media   | 10000    | 34f       | 150f (5.0s)    | `screenshots/devin-web-12.png` (testing recording + open PR) | "Ship with a PR that shows the app working — not a 20-minute CI wait." |
| 6 | `cta`      | cta     | 12000    | 34f       | 80f (2.7s)     | Devin logo                                                | "The only coding agent with a cloud Mac." · `Start a Mac session` · `app.devin.ai` |

Total = Σ(travelInFrames + holdFrames) = 1350 frames. Every result recording is
held ≥ 2.5s; the camera is stationary for the entire hold.

Under each media station the route line carries a mono stage label
(`01 · Request`, `02 · Build`, `03 · Run & test`, `04 · Verify`, `05 · PR`) taken
from `station.stageLabel`, so the viewer always knows where they are in the workflow.

## Editable props (`src/schema.ts`)

| Prop | What it controls |
|------|------------------|
| `brand.*` colours | Paper, surfaces, line, ink tones, accent, black/raised black, white. Defaults from `brief/brand.md`. |
| `brand.fontFamily` / `brand.monoFontFamily` | Font stacks. Defaults `"NB International Pro", "Inter", …` and `"Geist Mono", …`. Inter and Geist Mono are loaded via `@remotion/google-fonts`. |
| `brand.licensedFontFiles` | Optional `{ regular, medium }` paths (relative to `assets/`) to licensed NB International Pro `.woff2` files. When set, `@font-face` rules are injected and the brand font wins over Inter. Omitted by default so renders are deterministic and there are no 404s. |
| `brand.logoLight` / `brand.logoDark` | Logo lockups (paths under `assets/`). |
| `content.*` | `featureName`, `eyebrow`, `headline`, `headlineAccent` (substring of the headline coloured accent), `subhead`, `captions[]`, `useCases[]`, `stages[]`, `cta.{label,url}`, `outroLine`, `speedBadge`. |
| `media` | Named slots: `{ src, kind: "image" \| "video", startFrom?, playbackRate?, crop?: {x,y,w,h} (fractions), sourceSize?: {w,h} }`. `sourceSize` gives the true pixel size so the frame keeps the asset's aspect; `crop` is a plain rectangular crop (no skew, no recolour). |
| `scenes[]` | Ordered stations. Each has `id`, `kind` (`opening`/`media`/`cta`), canvas `x`/`y` (centre, px), `travelInFrames`, `holdFrames`, optional `zoom`, `stageLabel`, `captionIndex`, `useCaseLabel`, `mediaSlot`, `mediaSlotB` (cross-fades in at the midpoint of the hold), `textSide` (`left`/`right`), `mediaWidth`, `showSpeedBadge`. |
| `camera.easing` | `inOutCubic` (default) or `inOutSine` travel curve. |
| `camera.showRoute` / `camera.routeOffsetY` | Draw the route line + station dots, and how far below station centre it sits. |
| `camera.gridSpacing` | Dot-grid spacing on the paper (0 disables). |

Because the camera path is derived from station positions, you can re-arrange the
canvas freely (e.g. an L-shaped or vertical route) by editing `x`/`y`; the
timeline is derived from `travelInFrames`/`holdFrames` so the composition length
updates automatically via `calculateMetadata`.

## Swapping launches

1. Edit `src/defaults.ts` (copy → default props), or
2. Pass a JSON file at render time:

```sh
npx remotion render Launch out/launch.mp4 --props=./my-launch.json
```

The JSON must satisfy `launchPropsSchema`; Remotion Studio exposes every field in
the right-hand props panel with zod validation.

## Decisions on ambiguous points

- **Route direction.** A single left-to-right row was chosen over an L or grid so
  the "sense of direction" is trivially readable; the route line and stage
  labels make the path explicit. Positions are props if a different shape is wanted.
- **Screenshots as connectors.** The `pick` station uses two real screenshots
  (macOS selected → OS dropdown open) cross-faded in place, instead of animating
  a fabricated dropdown. `result` uses the real `devin-web-12.png` (PR + testing
  recording) rather than a synthetic "done" state.
- **iPhone-only crop.** `androidios.mp4` shows an iPhone Simulator and an Android
  emulator side by side; the Android emulator is outside the approved claims, so
  the slot is cropped to the iPhone. The crop is rectangular only.
- **Speed badge.** All recordings play at 1x so the `3x` badge is off by default
  (`showSpeedBadge: false`); flip it on with a `playbackRate`.
- **Poster frame.** The middle of the `taps` hold (iPhone Simulator), the
  most recognisable "cloud Mac" moment.
- **Zoom.** The camera never scales; every station is designed at 1:1 so product
  UI stays at its native readable size and there is no zoom-tunnel effect.
