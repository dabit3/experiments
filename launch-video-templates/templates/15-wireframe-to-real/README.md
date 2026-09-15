# Wireframe to Real

A 40-second, 1920 × 1080, 30 fps launch film. A quiet drafting surface, graphite
double-stroke wireframes, and an emerald resolve edge make the progression from
idea to built native app visible. Each feature begins as a spatially matched
wireframe, resolves to supplied screenshot content in exactly 18 frames / 600 ms,
and then introduces representative workflow motion or an actual recording.

## Edit and render

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 15-wireframe-to-real
```

`config.ts` contains headlines, supporting copy, scene starts/durations, frame
rate, resolve timing, action start, fonts, and the source-video trim.
`template.json` contains the collection metadata; keep its duration consistent
with `config.ts`. `index.tsx` owns geometry, source crop coordinates, and action
overlays. Crops use a single scale factor for both axes. `PhoneSketch`,
`SketchCard`, and `EvidenceSketch` match the corresponding image regions.

The local composition has no network assets, browser setup, runtime clocks, CSS
animations, or random values. It uses Remotion `Img` and muted `OffthreadVideo`.
The shared renderer writes `out/15-wireframe-to-real.mp4` at CRF 18 / H.264.

## Scene timing and motion budget

All times are editorial scene time, never claimed execution time. Feature
wireframes hold for 0.6 s, resolve during 0.6–1.2 s, and hold screenshot content
before representative activity begins at 1.8 s. The evidence insert starts at
2.2 s in its scene. A hard scene cut separates each primary idea.

| Time | Primary copy | Source / treatment | Maximum concurrent motion families |
| --- | --- | --- | --- |
| 0–4 s | Your ideas. Now native. | Native maze iPhone from `devin-web-14.png`; sketch resolves at 1–1.6 s | Ease-out text entrance; matched image reveal |
| 4–8 s | Build. Wait. Check by hand. | Hand-drawn CI waiting card; 20+ min is prior-context copy | Text entrance; card text entrance |
| 8–14 s | Make the idea run. | `devin-web-13.png` session message and `devin-web-14.png` iPhone; illustrative Xcode/build/run stages | Text entrance then reveal; later discrete workflow state |
| 14–20 s | Tap. Type. Scroll. | `devin-web-10.png` iPhone; staged action rows and pointer | Text entrance then reveal; later pointer movement + action/text state |
| 20–26 s | Close the feedback loop. | `devin-web-10.png` iPhone and original mixed-result issue report; reproduce/fix/retest highlight | Text entrance then reveal; later discrete workflow stage |
| 26–32 s | See what happened. | `devin-web-18.png` full native review screenshot; then actual web QA recording | Text entrance then reveal; later source playback + crossfade |
| 32–36 s | A working app. Right here. | Large native charts iPhone crop from `devin-web-18.png`; live-session outcome and same-price line | Ease-out text entrance only |
| 36–40 s | Devin / macOS + iOS / Build. Run. See it. | Supplied black logo, original proportions | Unified ease-out end-card entrance |

Resolve/move easing is cubic ease-in-out. Entrances use cubic ease-out.
Progress marks and action highlights change discretely. No decorative continuous
motion runs alongside the feature action. The dot grid and hand-drawn borders
are static, deterministic vectors. There are never more than two concurrent
motion families.

## Source provenance and truthfulness

The supplied assets live in `public/assets`; none is downloaded at render time.

- `devin-web-14.png`: documented native Afterhours Maze iPhone Simulator. The
  actual phone region is shown in the hook and build scene.
- `devin-web-13.png`: supplied macOS Devin session, using the original message
  crop. The build/run progress beneath it is an illustrative workflow, not a new
  recording or proof that this particular app was built during this render.
- `devin-web-10.png`: documented Wisp iPhone Simulator screenshot. Its original
  report contains **12 passed, 3 failed, 2 untested**. The fix scene preserves the
  mixed-result count and failure narrative. The editorial highlight advances
  through reproduce/fix/retest without claiming a newly successful retest.
- Simulator action motion is representative: a pointer/gesture marker is
  overlaid on an unchanged iPhone screenshot, and a separate action card types
  “Check this flow.” The phone does not secretly swap to fabricated app results.
  The pointer's upward motion indicates scrolling; this is not newly captured
  native gesture footage. Each such scene displays **Illustrative workflow**.
- `devin-web-18.png`: native iPhone rescue charts and supplied review evidence.
  The complete review screenshot resolves from a matching wireframe before the
  actual recording insert. The outcome uses only the actual phone crop.
- `devin-testing-2.mp4`: original web QA recording, source seconds **14–17.8**
  (approximately 3.8 s at real-time 1× speed). Displayed from film 28.2–32 s
  with the prominent label **SOURCE RECORDING / WEB QA — NOT IOS FOOTAGE**.
  This is a truthful generic recorded-evidence example, not footage of the
  native app shown just before it. The native screenshot and clip are different
  examples. Its incidental audio is muted.
- `model-selector-local.mp4` was sampled during source inspection but is not
  used; it is desktop model selection and cannot illustrate Mac VM selection.
- `mark-black.png` and `logo-black.png` are supplied assets, used faithfully
  against the light surface. Neither is redrawn, stretched, or combined with
  its white variant.

The film is intentionally silent. No voiceover, sound effects, or music are
required for this direction, and incidental source audio is excluded.

## Brand / typography

Brand adaptation uses the supplied Figma-derived `shared/brand.ts` ink, paper,
and emerald colors, restrained 24/32/48/96 spacing, and generous negative space.
It is a drafting-table interpretation, not a copy of the marketing site.
Figma source: `evS5ExlrnLrUCMPm395OHw`, node `0-1`, as retrieved by the coordinator.

NB International Pro and Inter binaries were not supplied. The explicit system
fallback is **Helvetica Neue → Arial → sans-serif**, with
**SFMono-Regular → Menlo → monospace** for labels. This render uses macOS system
fonts; text metrics may differ slightly on other systems. No font or new package
dependency is added.

## QA / deliverables

The final MP4, full-frame poster, and scene/transition contact sheet belong under
ignored `out/`, not in source control. Use `ffprobe` to confirm H.264, 1920 × 1080,
30/1 fps, 1200 frames, and 40 s. The poster should be taken from the finished
render at 11 s (frame 330). The contact sheet must include the hook, context,
every feature at wireframe/mid-resolve/real/action states, the screenshot-to-video
transition, outcome, end card, and last frame. Review at least one full-size frame
from each scene in addition to the contact sheet.

On macOS, `swift templates/15-wireframe-to-real/qa.swift` uses the system AppKit
and `ffmpeg` on PATH to extract 30 full-frame checkpoints from the finished
render, save the poster, and assemble a labeled 2400 × 1848 contact sheet. This
optional QA helper adds no project dependency. Other platforms can extract the
same frame numbers listed at the top of that script with their image tools.

Known limits: native motion is representative and labeled, not newly recorded
iOS footage; no actual build or tests are run by this video template. Same-price
and managed-Mac capability statements are from the launch brief. The 20+ minute
wait is context, not a measured benchmark or guaranteed speedup. The film makes
no claims about physical devices, signing, App Store distribution, or universal
Apple-platform support.
