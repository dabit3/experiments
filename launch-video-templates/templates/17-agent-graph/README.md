# 17 — Agent Graph

A 42-second, silent, 1920×1080 / 30 fps launch film. A directed four-node plan
becomes the product view: each active node expands into its screen, returns to
the graph, and hands activity to the next node. The explicit `ITERATE → INTERACT`
return edge represents the fix/retest loop. It is a meaningful execution diagram,
not a particle network. Graph status means **narrative progress**, never a test
pass, execution speed, or live job status.

## Edit and render

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 17-agent-graph
```

`config.ts` holds headline copy, scene starts/durations in seconds, colors, motion
boundaries in frames, and the source-recording in point. `template.json` contains
delivery metadata. Keep its duration and `config.durationSeconds` synchronized.
`index.tsx` contains the graph layout, media crops and reusable graphic components.
Feature durations are six seconds; adjust the return animation frame boundaries
in `config.motion` if changing that duration. All timing is deterministic.

The root renderer writes `out/17-agent-graph.mp4` using H.264, yuv420p, CRF 18
and concurrency 2. No remote fonts, APIs, generated data or network media are used
during rendering. The first render may install Remotion's headless browser.
Sound is deliberately absent; the supplied clip is muted. The shared renderer
emits a silent AAC track.

## Scenes and motion budget

| Time | Beat / copy | Media | Motion families (maximum two) |
| --- | --- | --- | --- |
| 0–4 | Your agent. Now native. | Prominent Rescue iPhone source still | Text entrance; phone entrance. Both settle and hold. |
| 4–8 | Feedback used to wait. / Manual QA / 20+ min | Minimal feedback-gap diagram | Unified text entrance; edge reveal. |
| 8–14 | Build + run. On managed Macs. | Representative managed-Mac task panel, real native Rescue phone still | Graph activity then node expansion/return; screen/copy entrance then task-row activity. |
| 14–20 | Tap. Type. Scroll. | Two original Wisp phone crops | Graph activity then node expansion/return; staged input cues and discrete still swap. |
| 20–26 | Reproduce. Fix. Retest. | Wisp phone plus unmodified mixed-results review crop | Graph/feedback-edge activity then node expansion/return; screen/copy entrance. Screen holds. |
| 26–32 | See what happened. / Review recorded evidence. | Actual supplied web-app QA clip, source 8s onward | Graph activity then node expansion/return; video playback. Copy is static while video plays. |
| 32–38 | A working app. Yours to inspect. / Same price as Linux. | Full original native Rescue review screenshot | Text entrance; screenshot entrance. Both settle and hold. |
| 38–42 | Devin / macOS + iOS / Build. Run. See it. | Supplied white logo | Unified logo/text entrance; static final hold. |

Each feature opens with 20 frames of graph state, followed by a 24-frame
ease-in-out expansion from the active node. The screen holds through the feature,
then returns to its graph node. Accent connection packets only animate during
the graph phase. Text entrances use cubic ease-out; layout and pointer moves use
cubic ease-in-out. During the live clip the graph is hidden and the copy holds.
No CSS runtime animations, randomness, wall-clock timing, decorative background
motion, or simultaneous interactive devices.

## Source provenance and truthfulness

All files below are the supplied assets under `public/assets`.

- `devin-web-18.png`: Rescue iPhone Simulator and native review evidence.
  The phone is cropped for hook/build. The outcome uses the complete original
  screenshot, preserving the visible source results. It is not a new capture.
- `devin-web-11.png`: Wisp onboarding iPhone still. Used briefly in the
  interaction beat. Original cursor and typing overlay remain part of the image.
- `devin-web-10.png`: Wisp conversation still and mixed native checks. Used for
  interaction and iteration. The original **12 passed / 3 failed / 2 untested**
  results remain visible in the iteration panel. The screenshot is never
  presented as an all-passing run or proof that those specific failures were fixed.
- `devin-testing-2.mp4`: actual generic web-app QA, starting at source 8 seconds
  when the review panel is fully open, and playing about 4.5 seconds. On-screen
  labels explicitly say “SOURCE RECORDING / WEB-APP QA” and “ACTUAL SOURCE VIDEO”.
  It is not iOS footage, a Mac VM selector, or a recording made for this template.
  The source was inspected at 8 and 11 seconds before selection.
- `logo-white.png`: supplied full Devin logo, used unchanged at natural aspect
  ratio on the dark background. No logo was redrawn.

Source screenshots 12, 13 and 14 were also inspected during selection but are not
used. The desktop model-selector clip is not used. Native phone content is
always an original screenshot crop. Source dimensions and crop rectangles are
explicit in the `native` map in `index.tsx`; scaling is uniform in both axes.
`Img` and muted `OffthreadVideo` load the shared local assets through `staticFile`.

The task rows, node states, pointer rings and timeline are representative motion
UI. Their scenes visibly say “ILLUSTRATIVE WORKFLOW”. They communicate the supplied
launch capabilities, not a claim of a newly executed native test. No simulated
pass results, speed gains, signing, distribution, hardware-device access or
parallel interactive-device support are claimed. “20+ min” is the brief's prior
CI context, not an observed duration in the footage.

## Design and limitations

This adapts the coordinator-inspected Figma website tokens in `shared/brand.ts`:
green `#0ca678` connections, purple `#956cde` feedback edges, 16/24/32/48/96
spacing, and thin low-contrast borders. A dark navy surface and lighter mint
active state provide readable graph contrast; this is not a pixel-copy of Figma.

NB International Pro and Inter binaries were not supplied. Display copy uses
the macOS system fallback **Helvetica Neue**, then Helvetica/Arial/sans-serif.
Graph labels use **SFMono-Regular**, then Menlo/Consolas/monospace, from the shared
brand stack. No unlicensed font is bundled. On another OS, fallback font metrics
may differ; re-inspect the contact sheet after changing platforms.

Small source-UI text is contextual evidence; primary launch copy and native
phone imagery are deliberately larger. Wisp's original source includes failed
checks. The iteration beat illustrates the supported reproduce/fix/retest
workflow and does not document resolution of those source-specific failures.

## Offline QA deliverables

Render first, then use `qa.mjs` to extract a full-frame poster and a labeled
contact sheet from the finished MP4:

```sh
node templates/17-agent-graph/qa.mjs
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate,nb_frames:format=duration out/17-agent-graph.mp4
```

The helper uses installed `ffmpeg`, preserving all frames at 16:9. Its contact
sheet includes the hook/context, all four feature holds, outcome/end card, and
each graph-to-screen expansion and return. Generated MP4/PNG files stay under
ignored `out/`; they are uploaded as attachments and never committed.

Verified production output:

- `npm ci`, lint, typecheck, manifest validation and full render passed.
  Install audit reported zero vulnerabilities.
- `ffprobe`: H.264, 1920×1080, 30/1 fps, 1,260 video frames, exactly 42.000
  seconds of video. The silent AAC padding makes container duration 42.048 seconds.
  The renderer's full-range 4:2:0 output is reported as `yuvj420p`, range `pc`.
- Complete decode passed. Audio `volumedetect` reported −91 dB maximum, the
  tool's silence floor; incidental source audio is not audible.
- Poster is 1920×1080; contact sheet is 1920×2236 and contains 28 labeled
  scene/transition frames. Both were inspected, with full-frame checks of the
  graph, native UI crops, every feature, mixed Wisp results, outcome and logo.
  No clipped launch text, distorted media or missing assets were found.
