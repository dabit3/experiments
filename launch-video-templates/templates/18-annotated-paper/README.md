# Annotated Paper

42 seconds · 1920 × 1080 · 30 fps · silent H.264.

Native app launch notes, laid out as printed screenshots on a warm neutral
work surface. Blue pen marks, restrained yellow highlighting, mint notes and
small paper rotations identify specific UI controls. Each scene has a single
primary headline. The annotation system intentionally leaves long, quiet holds.

## Edit and render

Run these commands from `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 18-annotated-paper --muted
swift templates/18-annotated-paper/qa.swift
```

`config.ts` contains scene copy and seconds, interaction subbeats, source media,
crop rectangles in original-image pixels, palette, typography and motion timing.
Interaction focus points are also in original-image pixels; annotation targets
follow the crop scale and paper rotation automatically.
`index.tsx` contains the layout and annotation paths. Change `scenes` to edit the
story; update `template.json` if the total duration changes. The three interaction
subbeats must sum to the interaction scene's duration.

Output: `out/18-annotated-paper.mp4`. The root renderer uses H.264 CRF 18,
yuv420p and concurrency 2. No runtime network URLs, hosted fonts, audio, random
values, CSS animation, or browser UI testing are used.
`--muted` removes the empty output audio track as well as the source clip's
component-level mute. The macOS-only `qa.swift` helper uses the installed Swift/
AppKit and FFmpeg tools to extract 24 full-resolution scene/transition frames, a
full-frame hook poster, and a labelled contact sheet in ignored `out/`.

## Scene timings and motion budget

| Time | Primary idea | Media / specific annotation | Motion families |
| --- | --- | --- | --- |
| 00–04 | Devin. Now on Mac. | iPhone charts print; pen circles the charts heading, note points into phone | Paper/text entrance; annotation reveal |
| 04–08 | QA meant waiting. | Typeset prior workflow receipt; circle around “20+ min” | Paper/text entrance; annotation reveal |
| 08–13 | Build it. Run it. | Session header + agent message; circle on macOS badge, highlight build/test sentence | Paper/text entrance; annotation reveal |
| 13–15 | Tap. Type. Scroll. / Tap | Maze iPhone still; circle on Push Start | Paper entrance; annotation reveal |
| 15–17 | Tap. Type. Scroll. / Type | Wisp iPhone still; circle on message field | Paper entrance; annotation reveal |
| 17–19 | Tap. Type. Scroll. / Scroll | Charts iPhone still; upward gesture over chart rows | Paper entrance; annotation reveal |
| 19–25 | Reproduce. Fix. Retest. | Original Wisp failure report; circle on failed count, sequential workflow highlights | Paper/text entrance; annotation reveal |
| 25–31 | Review the recording. | Live source web-QA video in the print; arrow toward per-step review evidence | Source-video playback; annotation reveal |
| 31–37 | A working app. Yours to inspect. | Charts iPhone print; note points into app, mint pricing note | Paper/text entrance; annotation reveal |
| 37–42 | Build. Run. See it. | Supplied black Devin logo on light paper | Paper entrance; annotation reveal |

Paper and headline entrances share a rigid transform/opacity system using
ease-out cubic, 18 frames. Pen marks use path-length stroke reveals with
ease-in-out cubic, 24 frames. Sticky notes are part of the annotation family,
using a 12-frame ease-out reveal. Between scenes and between phone source stills,
cuts are intentional; they preserve clear boundaries and avoid a third motion
family. The real-video scene has no animated paper entrance. No simulated cursor,
scrolling source pixels, fake video playback, fabricated pass result, or invented
execution timer is used. “Tap/Type/Scroll” is a labelled representative workflow
over original source stills, not newly captured native footage.

## Source provenance and truthful use

All image crops preserve the source aspect ratio. `Crop` scales the whole source
uniformly and clips to a documented rectangle; it never stretches an image.

- `public/assets/devin-web-18.png`: supplied iPhone Simulator charts UI. Used for
  the hook, scroll illustration and outcome. Its review UI is not re-authored.
- `public/assets/devin-web-14.png`: supplied Afterhours Maze iPhone Simulator
  title screen. “Push Start” annotation identifies the real button. The source
  has an untested check; this template does not caption it as fully passing.
- `public/assets/devin-web-10.png`: supplied Wisp iPhone Simulator UI and review.
  The native message-field crop appears during “Type.” The separate report crop
  preserves “12 passed / 3 failed / 2 untested” and the failed persistence/metadata
  explanation. The loop illustrates addressing failures without claiming this
  source report was fixed or that a retest passed.
- `public/assets/devin-web-13.png`: supplied native session. Two enlarged printed
  excerpts preserve the native session title/macOS badge and the agent's build/
  test message. These are separate crops of one still, not a live execution log.
- `public/assets/devin-testing-2.mp4`: actual supplied **web-app QA** recording,
  source 12–18 seconds at normal speed, rendered muted with `OffthreadVideo`.
  The on-screen caption explicitly identifies generic web QA, not iOS footage.
  Source assertions and their original counts are incidental source evidence,
  not launch metrics. No desktop model-selector clip is used.
- `public/assets/logo-black.png`: provided Devin logo, unchanged, rendered using
  `Img` at its original aspect ratio. It has a light background and ample space.

Native scenes carry “Illustrative workflow · supplied iOS stills.” The prior
“20+ min” statement is the supplied launch context, not a measured demo result.
The working app, live iPhone in session and same-price-as-Linux statements come
from the launch brief. No claims about hardware iPhones, App Store distribution,
remote notifications or unsupported Apple capabilities are added.

## Brand, typography, limitations

Uses the observed Figma ink `#191919`, blue `#1971c2`, pale mint `#d5f0e8` and
the 8/16/32/48/96 spacing rhythm from `shared/brand.ts`. Neutral warm paper and
yellow ink are direction-specific adaptations. This is not a pixel-copy of a
marketing page.

NB International Pro and Inter binaries were not supplied. Headlines/body use
the local `Helvetica Neue`, Arial, sans-serif system stack. Handwriting uses the
macOS `Chalkboard SE` font, then Comic Sans MS/cursive; labels are deliberately
short and large. Menlo is used for small archival labels. These system fonts are
not redistributed. Rendering on another OS can substitute fonts and needs a
fresh visual check. Exact brand typography needs licensed font files.

The video is intentionally silent; all source audio is muted. Native interaction
is representative annotation over stills; only the web-QA evidence inset is an
actual moving recording. Original small UI copy is supporting texture, while
the headline, explanatory caption and enlarged targeted UI regions carry the
story. Source media is supplied evidence, not fresh testing performed here.

## Verified delivery

`npm ci` completed with zero audit vulnerabilities. Root lint, TypeScript,
manifest validation and the full render passed. FFmpeg decoded the complete
file without errors. FFprobe verified H.264, 1920 × 1080, 30/1 fps, 1,260 video
frames, exactly 42 seconds, and no audio stream. The poster is 1920 × 1080; the
24-frame contact sheet is 1920 × 3216.

The contact sheet covers the opening, context, every feature including all three
interaction subbeats, outcome, final logo, scene cuts and exit frames. Targeted
full-size checks verify the Mac badge, build/test text, actual Push Start button,
message field and original failed-count annotation. All poster/contact-sheet
frames are extracted from the final MP4.

One encoder observation for integration: on this macOS machine the shared
renderer requests `yuv420p`, while FFprobe reports full-range `yuvj420p`/`pc`.
The output is H.264 4:2:0 and decoded successfully. No shared-toolchain files or
encoder settings were changed to conceal this difference.
