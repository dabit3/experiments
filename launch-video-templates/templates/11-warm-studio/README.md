# 11 — Warm Studio

A quiet 42-second launch film. Cream and warm-gray surfaces, sage and clay
accents, generous margins, rounded studio frames, and conversational second-person
on-screen narration put the viewer inside the native development workflow.

## Edit and render

All headline copy, scene durations, palette, font stack, and the 24-frame / 800ms
fade duration live in `config.ts`. `index.tsx` contains the scene layouts and
explicit screenshot crops. Keep the sum of scene durations equal to the
`durationSeconds` in `template.json`. Composition ID: `Launch`.

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 11-warm-studio
# Delivery export: explicit Rec.709, lossless intermediate frames, no audio track.
npm run render -- 11-warm-studio --image-format=png --color-space=bt709 --muted
node templates/11-warm-studio/qa.mjs
```

The delivery export produces `out/11-warm-studio.mp4` at 1920×1080, 30fps,
H.264, CRF 18, Rec.709 yuv420p. Nothing is fetched remotely during frame rendering.
Remotion may download its headless browser during initial setup.

The unqualified shared command also renders successfully. In Remotion 4.0.522,
its default JPEG/color pipeline reports full-range `yuvj420p` in ffprobe, and
the muted source clip can leave a silent AAC track with 48ms of container
padding. The delivery command uses supported per-render flags to make the
color space and silent container explicit. Shared files are unmodified.

The optional QA helper requires `ffmpeg` and `ffprobe`. It asserts codec,
dimensions, frame rate, pixel format, frame count, and exact duration, then
extracts a full-frame poster and 24 full-frame samples from the finished MP4.
The contact sheet reads left-to-right, top-to-bottom:

| Row | Frames (30 fps) | Coverage |
| --- | --- | --- |
| 1 | 0, 90, 150, 162 | Opening, hook hold, context boundary and fade |
| 2 | 210, 270, 282, 360 | Context, build boundary/fade, build hold |
| 3 | 435, 447, 480, 540 | Interaction boundary/fade, tap and type |
| 4 | 600, 615, 627, 705 | Scroll, fix boundary/fade, fix hold |
| 5 | 780, 792, 870, 960 | Review boundary/fade/hold, outcome boundary |
| 6 | 972, 1035, 1122, 1259 | Outcome fade/hold, end-card fade and final frame |

The poster uses frame 90. All generated files remain under ignored `out/`.

## Scene map and motion budget

| Time | Beat and headline | Media | Motion families (maximum two) |
| --- | --- | --- | --- |
| 0–5s | Hook: Your next app. Now with Devin. | Native rescue app from `devin-web-18.png` | Opacity across boundary; 20px eased vertical drift |
| 5–9s | Context: You know the wait. | Two calm text cards | 800ms opacity fades; small eased translation |
| 9–14.5s | Build/run: You bring the idea. Devin builds and runs. | Wisp onboarding from `devin-web-11.png`; illustrative Mac workflow card | 800ms opacity fades; small eased scene translation |
| 14.5–20.5s | Interact: You can see every interaction. | Maze tap, Wisp typing, rescue scroll views | 800ms opacity fades; eased translation of scene/touch indicator |
| 20.5–26s | Reproduce/fix/retest: You spot a rough edge. Devin works it through. | Original Wisp review summary with failed and untested results intact | 800ms opacity fades; small eased scene translation |
| 26–32s | Review: You get the evidence. | Actual generic web QA video, source 7–13s | Scene opacity; source clip activity (no frame translation) |
| 32–37s | Outcome: Your working app. Right here with you. | Single rescue iPhone Simulator screenshot; same-price statement | 800ms opacity fades; eased vertical drift |
| 37–42s | Supplied Devin logo end card | Black supplied wordmark | 800ms opacity fade; small eased translation, then static hold |

Scenes overlap for 24 frames so there is always content beneath the next 800ms
fade. All timing is frame-based. Entrances use cubic ease-out. Drifts and gesture
paths use cubic ease-in-out. No springs, random values, CSS animations, or
decorative loops. Only a single native phone is presented at a time; overlapping
images during a dissolve represent successive views of that one viewport.
The review clip holds its final frame during the outgoing dissolve so source
playback does not overlap the next scene's phone drift.

## Source provenance and truthfulness

The coordinator supplied assets in `public/assets`. No new native test was
captured for this film.

- `devin-web-18.png` (2978×1626): real supplied rescue app in iPhone Simulator.
  Phone crop is x=686, y=238, width=572, height=1182. Used in hook, scroll
  illustration, and outcome. Original phone pixels are kept at a uniform scale.
- `devin-web-11.png` (2986×1630): Wisp onboarding screenshot. Phone crop
  x=688, y=239, width=568, height=1184. It illustrates a native app launching;
  it does not certify a completed build or passing checks.
- `devin-web-10.png` (2990×1624): Wisp interaction and review. Phone crop
  x=689, y=238, width=569, height=1182. Its original `typing...` annotation
  remains. The fix scene uses the unaltered review-summary region, including
  **12 passed, 3 failed, 2 untested**. It is never presented as an all-pass result
  or an issue that this video demonstrates was fixed.
- `devin-web-14.png` (2986×1626): supplied native Maze screen. Phone crop
  x=707, y=253, width=530, height=1094. Its illustrative tap ring does not claim
  that the static image is new gameplay footage.
- `devin-testing-2.mp4` (1918×1080, 30fps): actual generic **web-app QA**
  recording. Source seconds 7–13 appear in the review scene using a muted
  `OffthreadVideo`, uncropped and at native aspect ratio. The film visibly
  labels this insert “Recorded example / Web-app QA” and “generic testing
  example.” Its incidental source audio is muted.
- `logo-black.png`: supplied wordmark, unmodified and at original aspect ratio.
  Multiply compositing removes its white canvas against the cream surface
  while preserving the black artwork. No logo redraw.

The Mac workflow card, tap/scroll indicators, and stage labels are representative
motion UI. The visible “Illustrative workflow” labels distinguish them from new
native recordings. Tap/type/scroll uses three supplied app views to illustrate
the available actions, not a continuous test of one app.

## Design, audio, and limitations

The Figma design reference and observed brand tokens are documented in the shared
README and `shared/brand.ts`. This direction adapts the large sans-serif headlines,
tight tracking, 32/48px spacing, quiet borders, and pale-green accent into a warmer
studio palette. It is not a marketing-site replica.

NB International Pro binaries were not supplied. The explicit fallback is
**Helvetica Neue → Helvetica → Arial → sans-serif**. The verified macOS render
uses Helvetica Neue, medium weight. Rendering on another OS can change font
metrics; review line breaks and crops after substituting fonts.

The film is intentionally **silent**, with second-person narration expressed as
on-screen copy. There is no synthetic voice or music. No speedup or pass-rate
claim is invented. The long-CI context is qualitative to avoid metric noise.
“Same price as Linux VMs” is the supplied launch fact.

Source interfaces contain small incidental text. Large editorial copy carries
the story; the source inset is authentic evidence rather than a replacement for
opening the full recording. All screenshots preserve scale and aspect ratio.
Phone crops omit surrounding desktop chrome; no app content or outcome is
fabricated. There is no claim of physical-device control, signing, distribution,
or simultaneous interactive devices.
