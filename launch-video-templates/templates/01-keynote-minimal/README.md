# 01 — Keynote Minimal

A silent, 44-second product reveal. Near-white fields, oversized display type,
one floating product surface, soft 40 px shadows, and slow 4% push-ins.
1920 × 1080, 30 fps, H.264. Composition: `Launch`.

## Edit and render

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 01-keynote-minimal
swift templates/01-keynote-minimal/contact-sheet.swift
```

`config.ts` holds every headline, subline, scene duration, media choice, source
clip in-point, reveal timing, and the push-in amount. Newlines in headlines are
intentional. `index.tsx` contains the layout, crop rectangles, and two motion
primitives. Update `template.json` if the sum of scene durations changes.

The optional contact-sheet helper uses macOS AppKit and `ffmpeg` to extract 28
full frames, with timestamps, into ignored `out/`. Run it from the project root
after rendering. Update its sample frames if scene timing changes.

The initial source clip is muted and begins at 7 seconds. After the evidence
title, about 4 seconds of the source plays at its original speed, followed by
the short dissolve into the outcome. Do not change that clip's caption to imply
native iOS footage.

## Scene timing and motion budget

Incoming scenes crossfade over 20 frames while the preceding scene remains
visible. Copy fades in after the outgoing headline has disappeared, avoiding
double-exposed headlines. A one-frame white breath between the context and build
titles is intentional. Each feature title dissolves into its media from local
frames 48–72, with a stagger between title fade-out and media fade-in.
The remaining 3.6 seconds are a silent, near-full-frame media hold without
overlaid display copy. White margins preserve complete screenshot content.

| Time | Primary copy | Media | Motion families |
| --- | --- | --- | --- |
| 00:00–00:05 | Devin. Now for Mac. And iPhone. | Isolated native iPhone from `devin-web-14.png` | Scale; crossfade at exit |
| 00:05–00:09 | Manual QA. Or 20+ minutes waiting for CI. | Near-white type field | Crossfade; scale |
| 00:09–00:15 | Build it. Run it. / On a managed Mac VM. | Complete `devin-web-14.png`, showing an app running in iOS Simulator | Crossfade; scale |
| 00:15–00:21 | Tap. Type. Scroll. / In iOS Simulator. | Complete `devin-web-10.png`, with supplied typing moment | Crossfade; scale |
| 00:21–00:27 | Reproduce. Fix. Retest. | Complete `devin-web-11.png`, preserving failed and untested findings | Crossfade; scale |
| 00:27–00:33 | Review the evidence. | Actual `devin-testing-2.mp4` insert, identified as recorded web QA | Crossfade; scale |
| 00:33–00:36 | A working app. Live in your session. | Isolated native iPhone from `devin-web-18.png` | Crossfade; scale |
| 00:36–00:39 | Same price as Linux VMs. | Same single iPhone | Crossfade; scale |
| 00:39–00:44 | macOS + iOS / Build. Run. See it. | Supplied black Devin logo | Crossfade; scale |

No translation, particles, camera orbit, runtime CSS animation, or random state.
Entrances use cubic ease-out. Push-ins use cubic ease-in-out and stop at 104%.
All generated motion is derived from the Remotion frame. Source video motion is
captured content; the template does not animate additional UI over it.
There is no soundtrack, voiceover, or source audio: every feature has silence.

## Source provenance and truthful presentation

All files are supplied, local assets from `public/assets`; no render-time network
media or fonts are used.

- `devin-web-14.png` is the native Afterhours Maze Simulator review. The complete
  feature frame retains **8 passed, 0 failed, 1 untested** and its original
  limitations. The hook crops only the phone (x704, y256, 533 × 1090 source px).
  The rounded clipping mask follows the phone silhouette without stretching it.
- `devin-web-10.png` and `devin-web-11.png` show Wisp native Simulator checks.
  Both preserve the original **12 passed, 3 failed, 2 untested** result summary.
  They illustrate interaction and a reproduce/fix/retest workflow; this edit
  does not claim the pictured failed findings were subsequently fixed.
- `devin-web-18.png` supplies the outcome phone (x689, y240, 567 × 1172 source px).
  The source is a review screenshot, not a live stream. The hero/outcome layouts
  are representative launch treatments and visibly say “Illustrative workflow.”
  “Live in your session” states the launch capability from the brief.
- `devin-testing-2.mp4` is real **web-app QA**, not an iOS recording. The insert
  preserves the entire 1918 × 1080 source frame, including its evidence sidebar.
  “Recorded web QA · source footage” remains visible throughout. The native and
  web examples are separate captures, not a continuous test run.
- `logo-black.png` is used without redrawing or recoloring, with its supplied
  aspect ratio intact. Only the dark variant appears on the near-white end card.

The 20+ minute CI wait is prior-workflow context supplied in the brief. The edit
does not present an elapsed execution timer, a speedup, or new test metrics.
Same-price positioning also comes directly from the launch brief.

## Typography and design provenance

Adapts the coordinator's inspected Figma website tokens (`shared/brand.ts`):
`#fcfcfc` paper, `#191919` ink, close tracking, and generous 32 px spacing.
Display type is intentionally enlarged for 1080p presentation.

NB International Pro / Inter binaries were not supplied. This template explicitly
uses **Helvetica Neue → Helvetica → Arial → sans-serif** from the render machine.
It was produced on macOS with Helvetica Neue. Font metrics may differ on Linux;
inspect the contact sheet when rendering on a different operating system.

## Limitations and QA

Native UI moments are supplied still captures with deterministic scale motion.
This is not newly recorded iOS testing, and no tapping/typing/scrolling is
synthetically fabricated. All feature screenshots are shown in full with
proportional dimensions. The source capture's small incidental UI text is not
launch copy; headline readability is prioritized.

The poster and contact sheet should be extracted from the finished MP4 under
ignored `out/`. Cover the hook, context, all four feature titles and holds, both
outcome headlines, end card, and midpoint crossfades. Check crops and all test
result headers, especially failure/untested counts. Use `ffprobe` to verify
H.264, 1920 × 1080, 30 fps and 44 seconds. Do not commit rendered media.
