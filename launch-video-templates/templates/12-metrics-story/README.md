# Metrics Story

A 42-second editorial metrics film. Large tabular numerals anchor every scene;
blue workflow charts and equal price bars provide rhythm without claiming a
measured speedup. The native iPhone is the primary visual subject.

## Edit and render

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 12-metrics-story
```

`config.ts` holds scene order, durations, headlines, supporting copy, labels,
source selections, source-video in point, and animation timing. `template.json`
holds delivery metadata. If durations change, make `durationSeconds` equal the
sum of scene `seconds`. `index.tsx` defines reusable charts, screenshot crops,
scene layouts and the `Launch` registration.

Coordinates in `Crop` use a normalized 1568-pixel-wide source image. Its image
scales uniformly, keeping the source aspect ratio. The crop coordinates select
existing iPhone frames; no source PNG is edited.

## Scenes and motion budget

Hard cuts separate scenes. Content is present at the cut; entrances use cubic
ease-out, and chart moves use cubic ease-in-out. Static source screenshots never
pretend to be newly captured iOS video. No scene has more than two concurrent
motion families.

| Time | Metric and primary copy | Media | Motion families |
| --- | --- | --- | --- |
| 0–5s | **1** live iPhone Simulator. Native apps. Now in Devin. | Wisp native iPhone crop, `devin-web-10.png` | Numeral reveal + headline translate/opacity as one coordinated entrance |
| 5–10s | **20+** min waiting on CI. Manual QA. Or waiting on CI. | Prior CI context chart | Coordinated entrance; CI bar growth |
| 10–15s | **4** workflow steps. Build. Run. | Representative Mac build/run panel; Wisp onboarding crop, `devin-web-11.png` | Coordinated entrance; workflow-path and bar reveal |
| 15–20s | **1** live Simulator at a time. Tap. Type. Scroll. | Wisp chat crop, `devin-web-10.png` | Coordinated entrance; drawn workflow-progress chart |
| 20–25s | **4** workflow steps. Reproduce. Fix. Retest. | Wisp native UI and verbatim failed-check excerpt from `devin-web-10.png` | Coordinated entrance; workflow-path reveal |
| 25–31s | **4** workflow steps. Review the evidence. | Actual muted `devin-testing-2.mp4`, source 12–18s | Entrance then path reveal (never overlapping); source-video playback |
| 31–37s | **0** price increase. A working app. Ready to inspect. | Native rescue-game iPhone crop, `devin-web-18.png` | Coordinated entrance; equal price bars grow together |
| 37–42s | **0** price increase. Supplied Devin logo. Build. Run. See it. | `logo-white.png` | Logo entrance; closing rule draw |

The metric label stays visible while its numeral reveals over the opening 22
frames. Numerals are not counted through invented intermediate values.
“4” means the four presented workflow
steps, not a test count. “1” means one interactive Simulator at a time. “20+ min”
is the supplied prior-team CI context, not timing for this demo. “0” is the price
increase relative to Linux VMs. Price bars deliberately have identical length and
no currency or numeric scale. Workflow charts explicitly say “WORKFLOW PROGRESS ·
NOT ELAPSED TIME”; no chart is a performance benchmark.

## Provenance and representation

- Launch capabilities and allowed numerical claims: supplied launch brief and
  `shared/PRODUCTION.md`.
- `devin-web-10.png` / `devin-web-11.png`: supplied native Wisp screenshots.
  These are mixed test results. The failure scene typesets the first sentence of
  the original failure summary at readable size and labels the source as mixed
  results. Other native scenes crop to
  the device rather than claiming screenshot pass totals.
- `devin-web-18.png`: supplied native rescue-game review screenshot. Used
  only for its existing iPhone UI; it does not prove a new test run.
- All representative native/build scenes say “Illustrative workflow · supplied
  native UI.” The build panel is authored explanatory UI, not captured terminal
  output. Its progress bar describes the workflow, not execution duration.
- `devin-testing-2.mp4`: actual web-app QA footage, source seconds 12–18 at normal
  playback speed, shown with its aspect ratio intact using muted `OffthreadVideo`.
  It is visibly labeled “Source recording · web QA” and “not iOS footage.”
  This clip demonstrates a generic evidence-review moment, not a native test.
- `mark-black.png`, `mark-white.png`, `logo-white.png`: supplied Devin assets,
  scaled proportionally without redrawing or recoloring. Only one contrast
  variant is used at a time.
- All assets are resolved locally with `staticFile`, `Img`, and `OffthreadVideo`.
  No network requests are required after the toolchain/browser is installed.

## Visual system, audio, and limitations

The restrained paper/ink/blue palette adapts the inspected Figma values in
`shared/brand.ts` (`#fcfcfc`, `#191919`, `#1971c2`), with 32/48/96 px spacing and
generous empty space. It is not a pixel-copy of the site.

NB International Pro files were not supplied. Display and body use the explicit
system fallback **Helvetica Neue → Arial → sans-serif**; code-like labels use
**Menlo → Consolas → monospace**. Numerals use `font-variant-numeric: tabular-nums`.
System font availability can affect line metrics on other machines.

Audio is intentionally silent; incidental source audio is muted. There is no
claim of real-device support, signing, distribution, or measured speedup. No
new native recording was captured. Source screenshots are representative static
native evidence, with source content preserved.

The shared renderer writes a silent AAC track: the video stream is exactly
42.000 seconds / 1260 frames, while the container reports 42.048 seconds due to
audio padding. No source audio is audible.

## Offline QA

Render H.264, 1920×1080, 30 fps, CRF 18 via the shared render command. Keep the
MP4, poster, contact sheet and other inspection frames under ignored `out/`.
Inspect stable frames for every scene and frames on both sides of all seven
cuts; use `ffprobe` to confirm codec, dimensions, frame rate and duration.
Full-frame source/video screenshots were inspected before selecting crops.

On macOS, the dependency-free AppKit helper produces a labeled, full-frame
contact sheet directly from the final MP4:

```sh
swiftc -typecheck templates/12-metrics-story/make-contact-sheet.swift
swift templates/12-metrics-story/make-contact-sheet.swift out
ffmpeg -i out/12-metrics-story.mp4 -vf 'select=eq(n\,75)' \
  -frames:v 1 -update 1 out/12-metrics-story-poster.png
ffprobe -v error -show_streams -show_format out/12-metrics-story.mp4
```

The helper samples all eight scene holds, frames before/within each entrance,
and the very first and last delivered frames. Its sample list is in frames at
30 fps and should be updated when editing scene durations.
