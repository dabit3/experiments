# 14 — Gradient Mesh

A restrained native-app launch film. A near-white UI card floats above broad,
low-saturation blue, green and purple mesh fields. Color changes identify
chapters; the foreground remains quiet and legible. 40 seconds, 1920×1080,
30 fps, H.264. Silent by design.

## Editing and rendering

`config.ts` owns the scene order, copy, durations, accents, entrance duration,
source-video in point and font stack. Scene starts and composition duration are
derived from these values. If changing total duration, also update
`template.json`. Keep the total between 28 and 50 seconds.

`index.tsx` contains the card layout, mesh, native screenshot crop coordinates,
step rail and source recording. The crop data in `Phone` is in original source
pixels. Its scale is uniform: changing `width` preserves aspect ratio. Keep
headlines to the authored two or three short lines. All media resolve from the
committed shared `public/assets` directory; no network or remote fonts at render
time.

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 14-gradient-mesh
```

The mastered delivery uses explicit Rec.709 color and no audio track (the
default render otherwise includes a silent AAC track with encoder padding):

```sh
npm run render -- 14-gradient-mesh --color-space=bt709 --muted
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate,pix_fmt \
  -show_entries format=duration -of json out/14-gradient-mesh.mp4
```

## Scene plan and motion budget

Times are film positions, not purported execution durations. The bottom marks
indicate chapters, not app/test progress.

| Time | Beat / headline | Media | Concurrent motion families |
| --- | --- | --- | --- |
| 0–4.5 | Hook: Devin for macOS + iOS. | Large native rescue-app iPhone screenshot crop | Mesh; coherent foreground ease-out entrance |
| 4.5–8.5 | Context: Build. Wait. Repeat. | Editorial 20+ min CI context and manual QA | Mesh; foreground ease-out entrance |
| 8.5–13.5 | Build: From code to running app. | Native iPhone crop with representative Mac action rail | Mesh; foreground entrance, then hard-cut action emphasis |
| 13.5–18.5 | Interact: Tap. Type. Scroll. | Wisp iPhone screenshot and action rail | Mesh; foreground entrance, then hard-cut action emphasis |
| 18.5–24 | Iterate: Reproduce. Fix. Retest. | Wisp iPhone crop, real source finding and staged next actions | Mesh; foreground entrance, then hard-cut action emphasis |
| 24–30 | Review: See what happened. | Actual generic web QA video, source 12–18s | Mesh; source-video playback. No foreground entrance. |
| 30–35.5 | Outcome: A working app. In your session. | Native rescue-app iPhone crop; same price as Linux VMs | Mesh; foreground ease-out entrance |
| 35.5–40 | End: supplied Devin logo / macOS + iOS / Build. Run. See it. | Unmodified black logo | Mesh; foreground ease-out entrance |

At most two concurrent families. Foreground entrances are 22 frames, cubic
ease-out, one shared translation. Action emphasis begins after 28 frames and
uses deliberate hard cuts; it does not simulate elapsed test time. Mesh hue
changes use cubic ease-in-out over 28 frames; its spatial drift is a smooth
frame-driven sine cycle. No CSS animation, random values, wall clock, device
input simulation or autonomous browser actions. Headlines remain readable at
scene boundaries; no black/empty fade frames.

## Source provenance and truthfulness

- Design reference: coordinator-inspected Figma
  `evS5ExlrnLrUCMPm395OHw/Devin`, nodes `1:5911`, `1:6790`, `1:5923`.
  Colors are the observed `#1971c2`, `#0ca678`, `#956cde`, mixed with paper at
  low opacity. Hairline borders and spacious hierarchy adapt the supplied
  `shared/brand.ts`; this is not a pixel-copy of the website.
- Font fallback: Helvetica Neue, Helvetica, Arial, sans-serif. NB International
  Pro and Inter binaries were not supplied. The render uses the local system
  Helvetica Neue; no licensed font files are claimed or bundled.
- `devin-web-18.png` (2978×1626): large rescue-game iPhone Simulator crop.
  This is a supplied native screenshot, not newly captured iOS footage.
  Used for hook, build and outcome. Only one phone is visible at once.
- `devin-web-10.png` (2990×1624): Wisp Simulator phone crop, used for interaction
  and iteration. The source's `typing...` overlay is retained. Its original
  report contains **12 passed, 3 failed and 2 untested**; this film never
  recasts it as an all-passing run. “Model details absent” summarizes the
  source's documented missing context/pricing details. The staged action rail
  names reproduce/fix/retest but does not claim a fix or successful retest.
- `devin-testing-2.mp4`: actual source footage at 12–18 seconds, preserving
  the complete 1918×1080 frame in the evidence card. This is a generic web
  ticket-delete QA recording, explicitly labeled “generic web QA, not iOS.”
  Its existing web test results belong only to that web example. Uses
  Remotion `OffthreadVideo`, muted. The native screens are never described
  as frames from this clip.
- `logo-black.png` and `mark-black.png`: supplied black assets, unmodified,
  uniform scaling, light-background contrast. The end card uses the full
  supplied logo and preserves its aspect ratio.

The representative Mac action rail and iOS workflow are explicitly labeled
“Illustrative workflow.” They communicate launch capabilities, not recorded
execution of these source apps. The native phone crop intentionally excludes
the surrounding old report. Source screenshots were visually inspected before
choosing the crop. Source video was sampled before selection.

## QA and limitations

The required full-quality output is `out/14-gradient-mesh.mp4`; poster and
contact sheet also live under ignored `out/`. No rendered assets belong in git.
On macOS with Swift and ffmpeg available, generate the full-frame poster and
33 labeled scene/transition samples with:

```sh
swift templates/14-gradient-mesh/contact-sheet.swift
```

The helper samples the authored 40-second edit; update its sample frames if
scene timings change. It extracts from the finished MP4, never from a storyboard.
Review a scene midpoint plus immediately-before, boundary and entrance frames
for each cut. Review first and final frames. Use ffprobe to confirm 40.0 seconds,
1200 frames, H.264/yuv420p, 1920×1080 and 30/1 fps.

No source recording depicts actual iOS motion; native imagery is an honest,
labeled screenshot-led reconstruction. Action text is editorial rather than a
literal reproduction of the Devin UI. Source UI contains small incidental
text; launch headlines and action labels are the intended reading layer.
There is no narration, music or incidental source audio. “20+ min” describes
the supplied prior CI workflow, not a measured benchmark or promised speedup.
No app signing, physical-device, App Store or unsupported capability claims.
