# 08 — Editorial / The Native Edition

A 40-second, silent moving magazine: warm stock, Georgia headlines, a restrained
blue accent, folios, hairline rules, generous margins and native screenshots
treated as photographs. Full HD, 30 fps, composition `Launch`.

## Editing and rendering

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 08-editorial
```

`config.ts` is the editorial desk: scene copy, start/end seconds, figure captions,
publication metadata, gesture/iteration labels, the source-video in-point and
transition/entrance durations. Keep scenes contiguous; update `template.json`
duration to match the final scene's end. The type sizes and fixed page geometry
live in the named layout components in `index.tsx`; recheck frames if replacing
copy with longer text. Crop centers and crop heights use original source pixels.
The crop helper scales each image uniformly and masks the photograph window.

Default output: ignored `out/08-editorial.mp4`, H.264 / CRF 18 / 8-bit 4:2:0.
There are no network assets at render time. The initial toolchain may download
Remotion's headless browser. No new packages or shared files are required.
The delivered silent master uses `npm run render -- 08-editorial --muted` to omit
the otherwise silent AAC track and its container padding.

## Scene plan and motion budget

Incoming pages wipe from right to left over 18 frames, with a subtle paper-edge
shadow. Each page is readable after 0.6 seconds; the outgoing page stays underneath.
The cover's 26-frame, 18-pixel text/photo entrance is ease-out. Wipes and photographic
drifts are ease-in-out. Motion is entirely driven by Remotion frames.

| Time | Page / primary copy | Media | Motion families |
| --- | --- | --- | --- |
| 0–4s | Introducing / A new chapter. | Native harbor iPhone photo | Group entrance, then restrained photo drift |
| 4–8s | Context / The wait between builds. | Editorial `20+` CI pullquote | Page wipe; then a hold |
| 8–13s | 01 / Build it. Run it. | macOS desktop and native Maze Simulator | Wipe; photo drift starts afterward |
| 13–18s | 02 / Tap. Type. Scroll. | Wisp native iPhone screenshot | Wipe; then one gesture-annotation family |
| 18–23s | 03 / Find it. Fix it. Try again. | Wisp report crop with original mixed results | Wipe; then one discrete step-selection family |
| 23–29s | 04 / Review the record. | Actual web QA video, 12–18s source | Wipe + source playback |
| 29–36s | Outcome / A working app. In view. | Native harbor Simulator screenshot | Wipe; photo drift starts afterward |
| 36–40s | End / Build. Run. See it. | Supplied black Devin logo | Wipe; then a static logo hold |

Only the cover uses the group entrance. On the video page, the wipe and recorded
playback are its only simultaneous motion families. During its exit, the next
page's wipe is the sole template motion until source playback disappears.
Gesture annotations start after the entrance, using simple linear opacity pulses
and an ease-in-out vertical motion for the illustrative scroll. The still itself
never pretends to type or scroll. Step selectors are discrete editorial chapter
markers, not measured execution times. No native test outcome is synthesized.

## Source provenance and truthfulness

All media was supplied by the user in `public/assets` on base commit
`b47b8b85bdb4af2489c83c5b07e95eb79ff5f4ca`.
Source PNGs and a six-frame sampling of the web QA video were inspected before
crop selection.

- `devin-web-18.png` (2978 × 1626): the supplied native harbor app in the review
  viewer. Cover/outcome use its Simulator photograph only. These are still images,
  not a newly captured live native session.
- `devin-web-14.png` (2986 × 1626): native Afterhours Maze app in Simulator on a
  macOS desktop. The build/run page crops to the desktop photograph and preserves
  the app, Simulator title bar and Dock.
- `devin-web-10.png` (2990 × 1624): supplied Wisp feature-check view. The interact
  page crops to the iPhone; the iterate page crops to the report. The report
  retains its **12 passed, 3 failed, 2 untested** status and failure prose.
  It is never described as an all-passing run. The gesture ring and loop selectors
  are representative motion UI and visibly labeled `ILLUSTRATIVE WORKFLOW`.
- `devin-testing-2.mp4` (1918 × 1080): actual **web-app QA** recording. Source
  seconds 12–18 play at normal speed via muted `OffthreadVideo`. The outgoing
  page overlap may show up to 18.6 seconds while being covered. It is explicitly
  labeled `SOURCE FOOTAGE / WEB APP QA` and `Not iOS footage.` No use is made
  of the desktop model-selector clip, and no clip represents Mac VM selection.
- `logo-black.png` (2984 × 1024): supplied full logo, faithfully displayed at
  its original aspect ratio against white. No redrawn logo.

“20+ minutes” describes the prior CI context in the launch brief, not the measured
speed of this workflow. Same pricing as Linux, managed Mac VMs, native build/run,
Simulator interaction, reproduce/fix/retest and inspectable recorded evidence
are launch-brief claims, not benchmarks independently established by this video.

## Typography, brand and audio

Figma reference: `evS5ExlrnLrUCMPm395OHw`, observed nodes `1:5911`, `1:6790`,
`1:5923`; the coordinator's measured values are in `shared/brand.ts` and the root
README. This direction adapts the ink, blue, white and measured spacing to
magazine typography rather than copying the website.

NB International Pro / Inter binaries were not supplied. **Georgia** is the
intentional editorial serif fallback; **Helvetica Neue** is the metadata/body
system fallback. Both are available on this macOS render host. Generic Times New
Roman/Helvetica/Arial fallbacks are declared for other hosts; line breaks can
change there, so inspect a new render. Fonts are not downloaded or bundled.

The film is intentionally silent. Source incidental audio is muted. No synthetic
audio, stock music or unsupported capability claims are included.

## QA and known limits

Inspect all eight settled pages and the midpoint/boundaries of every page wipe.
Poster and contact sheet must be extracted from the final MP4, not a separate
mockup. Use `ffprobe` to check H.264, 1920 × 1080, 30 fps and 40.0 seconds.
Rendered media belongs in ignored `out/`, never in git.

Delivery QA passed `npm ci`, lint, typecheck, manifest validation and full render.
`ffprobe` verified H.264, 1920 × 1080, 30/1 fps, 1,200 video frames, exactly
40 seconds and no audio stream. This macOS encoder reports full-range `yuvj420p`.
The final-MP4 contact sheet covers all eight pages, all seven wipe midpoints and
the last frame. A second QA sheet checks the first frame and each wipe boundary;
full-size scene frames were checked for crop, headline and caption legibility.

Native footage is representative still-based editorial treatment; the single
actual moving insert is web QA. UI screenshot prose is supporting photographic
detail; the launch story is carried by the large editorial headlines and captions.
This template makes no real-device, signing/distribution or quantified
performance claim. Only one iPhone photograph is shown on each settled page.
