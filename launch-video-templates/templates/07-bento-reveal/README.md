# 07 — Bento Reveal

A 44-second, silent, 1920 × 1080 / 30 fps launch film. Four asymmetrical rounded
tiles arrive from the center, then each expands into the entire frame and
returns to its exact original rectangle. The complete grid resolves the story
before a quiet supplied-logo end card.

## Edit and render

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 07-bento-reveal
```

The delivered silent master uses `npm run render -- 07-bento-reveal --muted`
to omit the otherwise silent AAC track and its padding from the container.

The MP4 is `out/07-bento-reveal.mp4`. No network assets are used in the composition.
Remotion may download its rendering browser on first use.

`config.ts` contains the headline copy, feature names, scene boundaries in
seconds, transition duration, grid rectangles, colors, workflow labels, source
clip in-point, end copy, frame rate and duration. Keep `template.json` synchronized
if changing the duration or frame rate. `index.tsx` defines typography, crop
coordinates and scene layout. Crops reference original source pixels and use
uniform scaling; images and video are never stretched. All motion is computed
from the frame, with cubic ease-out entrances and cubic ease-in-out moves.

## Scene map

| Time | Scene / primary copy | Media | Motion families (maximum two) |
| --- | --- | --- | --- |
| 0–4.2 | Your native apps. Now in Devin. | Wisp iPhone crop, schematic workflow tiles | Center-to-grid staggered geometry; static hook |
| 4.2–8.2 | Manual QA. Or 20+ minutes for CI. | Same grid, persistent native iPhone | Header reveal only |
| 8.2–13.8 | Build and run. On managed Macs. | Afterhours Maze iPhone screenshot; representative build/run panel | Tile geometry + content dissolve during expansion/collapse; workflow focus on hold |
| 13.8–14.2 | Grid breathing room | Original tile rectangles | None |
| 14.2–20.8 | Tap. Type. Scroll. | Wisp iPhone screenshot with illustrative gesture indicator | Tile geometry + content dissolve in transition; gesture movement + discrete action focus on hold |
| 20.8–21.2 | Grid breathing room | Original tile rectangles | None |
| 21.2–27 | Reproduce. Fix. Retest. | Actual Wisp mixed-results report excerpt | Tile geometry + content dissolve in transition; workflow focus on hold |
| 27–27.4 | Grid breathing room | Original tile rectangles | None |
| 27.4–34 | Review what happened. | Actual muted web-app QA source-video insert | Tile geometry + content dissolve in transition; source-video playback on hold |
| 34–39 | A working app. Ready to inspect. | Complete bento grid; supplied rescue-chart iPhone | Header reveal only |
| 39–44 | macOS + iOS / Build. Run. See it. | Supplied black Devin logo | One opacity/position entrance; stable hold |

Each feature expansion lasts 0.8 seconds, as does its collapse. The fixed grid
coordinates preserve spatial memory; the unselected tiles do not rearrange.
Expanded content fades in only once the tile has sufficient space, and fades
out before collapse, preventing typography from being squeezed or clipped.
The feature canvas fills 1920 × 1080 at full expansion.
The source recording freezes during expansion/collapse so it does not add a
third motion family. Grid interludes use “Native apps. One complete workflow.”

The outcome supporting line states “Live iPhone in your session. Same price as
Linux.” The “20+ minutes” is the supplied prior CI context, not a measured render,
execution time, or performance claim. Progress strips and numbered steps are
workflow illustrations, not elapsed time or test completion metrics.

## Source provenance and truthfulness

All assets originate in committed `public/assets`, supplied by the user:

- `devin-web-14.png`: Afterhours Maze iPhone Simulator image. Only the phone is
  cropped for the build/run feature. It illustrates an app running, not a new
  build captured for this film.
- `devin-web-10.png`: Wisp iPhone typing screenshot, used in the initial grid and
  Simulator feature. The gesture indicator is representative motion graphics.
  The screenshot remains a still; no fabricated native interaction outcome is
  added. A separate crop in the reproduce/fix/retest scene shows the **original
  12 passed, 3 failed, 2 untested** report and the issue details. Those numbers
  are source evidence, not claimed launch results. No all-pass retest is invented.
- `devin-web-18.png`: Rescue charts iPhone crop in the outcome grid. This is a
  separate supplied native app example, not the after-state of the Wisp report.
- `devin-testing-2.mp4`: Actual web-app QA recording, beginning at source second
  16 for the five-second evidence hold (28.2–33.2). It is identified throughout as “Source recording /
  web app QA,” with “Generic QA example. Not iOS footage.” Its aspect ratio is
  1918:1080 and is preserved with `OffthreadVideo`, muted. No native or managed-Mac
  selection claim is made for this clip.
- `logo-black.png`: Supplied Devin logo, unredrawn, proportionally scaled.

The staged native scenes visibly carry an “Illustrative workflow” or
“Illustrative gestures” label. The film shows one interactive phone at a time.
The build/run and fix panels are representative workflow UI rather than
pixel-accurate product screens, real terminal output, or a new verified test run.
Original screenshot cursors and typing overlays are retained inside source crops.
Source screenshot metrics do not describe tests run by this production session.

## Visual system, typography and audio

Adapted from the coordinator's inspected Figma website nodes and
`shared/brand.ts`: near-white paper, ink typography, blue build tile, mint native
tile, dark fix tile and lavender evidence tile. Grid gutters are 24 px; outer
margins are 96 px; tile radii are 30 px. Feature type deliberately scales beyond
the website reference for 1080p viewing. The film uses generous unoccupied
regions rather than decorative animation.

NB International Pro and Inter font binaries were not supplied. Typography uses
the shared fallback stack: **Helvetica Neue on macOS, then Arial/sans-serif**.
Representative command text uses SFMono-Regular/Menlo/Consolas. No font is fetched
at render time. Font metrics can differ on Linux; the delivered render was made
on macOS with Helvetica Neue.

Audio is intentionally silent. The source recording's incidental audio is muted.

## Offline media QA

Inspect the hook, context, all four expanded features, outcome, end card, and
midpoints of all eight expand/collapse transitions. Use `ffprobe` to verify H.264,
1920 × 1080, 30 fps and 44 seconds. Extract a full-frame poster from the outcome
hold; build a contact sheet of the selected scene and transition frames. All
rendered outputs belong under ignored `out/` and are delivered as attachments.

On macOS, with `ffmpeg` and Swift available, this optional helper extracts the
24 scene/transition samples and makes the labeled contact sheet and poster:

```sh
swift templates/07-bento-reveal/inspect.swift
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/07-bento-reveal.mp4
```

The helper writes only to ignored `out/`. Its AppKit contact-sheet compositor is
macOS-specific; the Remotion composition itself has no AppKit dependency.

Known limits: native interactions are documented representative motion UI over
supplied stills; the only moving source recording is web QA. There is no voiceover,
soundtrack, newly captured native test or unsupported distribution/signing claim.
