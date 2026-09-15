# 10 — Frosted Depth

A quiet, 40-second visionOS-inspired launch film. The camera moves through exactly
three depth planes: translucent architecture, editorial glass, then media.
The supplied iPhone screenshot is the hero. Real web QA footage appears only in
the explicitly labeled evidence chapter.

## Editing and rendering

`config.ts` owns headlines, supporting copy, scene timing in seconds, interaction
labels, source-video start, and native phone crop coordinates. `template.json`
owns the 1920×1080 / 30 fps / 40-second composition settings. If changing total
duration, update both the final scene boundary and the manifest. `index.tsx`
registers the required `Launch` composition.

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 10-frosted-depth
bash templates/10-frosted-depth/media-qa.sh
```

Rendered media belongs under ignored `out/`, never in this template's source.
No runtime network, remote fonts, optional services, or new dependencies.
The video is intentionally silent; the source insert is muted.

## Scene map and motion budget

Times below are editorial boundaries. Each incoming scene crossfades during the
preceding 18 frames (0.6 seconds), so there are no empty transition frames.
The first frame is fully composed and the supplied logo holds through the last.

| Time | Primary copy | Media | Motion families, maximum two |
| --- | --- | --- | --- |
| 0–4 s | Devin. Now native. | Rescue charts iPhone crop | Camera parallax + exit/entrance dissolve |
| 4–8 s | Build. Wait. Repeat. | Frosted 20+ minute CI context card | Camera parallax + dissolve/vertical entrance |
| 8–13 s | Give your code a Mac. | Native app in supplied Simulator evidence | Camera parallax + dissolve/vertical entrance |
| 13–19 s | Tap. Type. Scroll. | Rescue charts iPhone crop; staged gesture ring and command | Camera parallax + sequential action/entrance family |
| 19–25 s | Close the feedback loop. | Original Wisp evidence, failed checks retained | Camera parallax + sequential step selection/entrance family |
| 25–31 s | See what happened. | Actual web QA source video | Video + camera on hold; video + dissolve at boundaries (camera paused) |
| 31–36 s | A working app. In your session. | Supplied native review screenshot | Camera parallax + dissolve/vertical entrance |
| 36–40 s | Build. Run. See it. | Supplied black Devin logo | Camera parallax + dissolve/vertical entrance |

Transitions, action highlights and native gestures belong to one content family.
Gestures begin after the entrance completes; before a transition the gesture has
settled. No independent shimmer, bouncing decorations, CSS animation, spring
physics, random state, wall-clock time, or flashing carets.
The camera pauses for all 18-frame transitions. In the recording chapter, video
playback and camera travel are the only concurrent families during the hold;
video playback and the scene dissolve are the only families during transitions.

## Glass, light and depth

- **Plane 0:** the environment and architectural arcs. Camera gain 0.22.
- **Plane 1:** translucent editorial surface, branding and scene progress. Gain 0.56.
- **Plane 2:** phone, source recordings and evidence cards. Gain 1.0. All media
  elements in a scene share this same transform; there is no fourth spatial plane.

The single frame-based camera eases between configured stops within ±22 px
horizontally and ±12 px vertically. The relative motion creates depth without
arbitrary floating.
The glass uses real CSS `backdrop-filter: blur(30px) saturate(125%)`, with its
WebKit counterpart, over actual background geometry. This is blur-behind,
not a pre-blurred image or a blurred card's own text. White top/left highlights,
restrained cool tint, and shadows cast down/right establish a consistent
top-left light. Text remains dark and opaque.

## Provenance and truthful presentation

- Figma reference and tokens: shared `brand.ts` and project README, retrieved
  by the coordinator from `evS5ExlrnLrUCMPm395OHw`, node `0-1`. This is a spatial
  adaptation of the observed palette and spacing, not a marketing-page copy.
- Typography: **Helvetica Neue**, then Arial/sans-serif. NB International Pro
  and Inter binaries were not supplied. No claim of exact font matching.
- `assets/logo-black.png`: supplied original, rendered by Remotion `Img` with
  intrinsic aspect ratio. It also ends the film. No redraw, recolor or stretching.
- `assets/devin-web-18.png`: native rescue-charts iPhone Simulator review.
  The hook and interaction scenes use a documented pixel crop
  `(681,237,578,1183)` from the 2978×1626 original. Uniform scaling and a rounded
  mask retain the phone's geometry. Outcome shows the complete original.
- `assets/devin-web-14.png`: native Afterhours Maze evidence, shown in full in
  the build/run chapter. Its original untested result remains visible.
- `assets/devin-web-10.png`: original Wisp Simulator evidence in full, including
  **12 passed, 3 failed, 2 untested**. The three workflow steps are illustrative
  capability labels. They do not claim these observed failures were repaired.
- `assets/devin-testing-2.mp4`: actual **web QA** footage, source time 15.0–21.6 s
  including the entrance, inserted with muted `OffthreadVideo`. Both its frame
  and chapter caption identify it as web QA, not native iOS footage. Source
  frames at 18 and 23 seconds were inspected before selection.
- Native interaction is representative motion UI using a static supplied
  screenshot. The small ring illustrates a tap/scroll and the command card
  illustrates typing; neither is a newly captured native session. On-screen
  caption says **Illustrative workflow**. The rescue app does not pretend to
  update when the staged command is shown.

The context metric, 20+ minutes, is prior CI context from the brief, not a measured
result or a speed claim. Progress is scene selection, not an execution timer.
The outcome and pricing copy use only the launch facts: managed Mac VMs,
build/run/test, iOS Simulator interaction, a live iPhone visible in-session,
recorded evidence and the same price as Linux VMs. No signing, distribution,
real-device access or invented test outcomes.

## Offline media QA

Run the four root checks, render the H.264 output, then verify codec, dimensions,
pixel format, frame rate, frame count and duration with `ffprobe`. Extract the
poster from the rendered MP4, not an independent still render. A contact sheet
must include all eight chapters and before/mid/after samples for each of seven
transitions. Inspect at full resolution where copy or crop precision matters.
No UI testing agent or browser login is needed for rendered-media QA.
`media-qa.sh` generates the full-frame poster, eight full-size scene frames,
the 32-frame contact sheet (eight chapters plus transition triplets and endpoint
coverage), and `ffprobe.json`. Its non-Node prerequisite is ffmpeg/ffprobe.
On macOS, the included Swift/AppKit helper adds frame/time labels without
requiring ffmpeg's optional `drawtext` filter. Elsewhere the contact sheet still
renders, without labels; the ordered `FRAMES` array in the shell script is its map.

Known limits: silent film; fallback typography; native moments are supplied stills
with labeled representative interaction. Existing evidence is preserved and
does not substantiate a newly performed test run.
