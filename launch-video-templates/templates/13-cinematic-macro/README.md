# 13 — Cinematic Macro

A quiet 40.5-second launch film. Extreme UI details resolve into a native iPhone
workflow, with shallow focus, cool anamorphic streaks, and restrained lower-thirds.
The 1920×1080 delivery contains a 1920×804 picture (2.388:1, the nearest even-pixel
approximation to 2.39:1) with 138-pixel black bars. No music or voice-over; source
audio is muted.

## Edit and render

`config.ts` contains all headline copy, labels for the main narrative, scene starts,
scene lengths, fade length, typography, and colors. `index.tsx` contains the shot
layouts, labeled source crop coordinates, and frame-based camera moves.
`template.json` defines the delivery metadata. Keep its duration equal to the final
scene's start plus length, and keep scene starts contiguous when changing timing.
Each scene continues behind the next scene for an 18-frame opacity dissolve.

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 13-cinematic-macro
```

For a video-only final master with no silent audio track, add `--muted` to the
render command. The delivered master uses this flag.

No remote media, extra dependencies, or runtime font downloads are used. NB
International Pro and Inter binaries were not supplied. Display text uses
Helvetica Neue → Helvetica → Arial → sans-serif. Code uses SFMono-Regular →
Menlo → monospace. System fonts can differ across operating systems. Palette,
spacing, tracking, and restrained sans typography adapt the inspected Figma
tokens in `shared/brand.ts`; the composition is not a website replica.

## Scenes and motion budget

| Time | Beat / copy | Image or treatment | Concurrent motion families |
| --- | --- | --- | --- |
| 0–4.5 | Devin goes native. | Extreme `Done` button closeup from native iOS screenshot 18; localized sharp plane and blurred surroundings | Slow ease-in-out dolly; ease-out lower-third opacity |
| 4.5–8.5 | Manual QA. Or a CI wait. | Distant native iPhone; defocused `20+ min` references the prior CI context | Slow dolly; opacity dissolve/copy |
| 8.5–13.5 | A managed Mac. Ready to build. | Representative `xcodebuild build` command, sharp code line amid soft lines | Slow dolly; opacity dissolve/copy |
| 13.5–19 | Tap. Type. Scroll. | Wisp iPhone still and a macro of its existing cursor/input, with original typing label | Slow dolly; opacity dissolve/copy |
| 19–24.5 | Close the loop. | Illustrative Swift-style restore line and unchanged actual Wisp mixed-results excerpt | Slow dolly; opacity dissolve/copy |
| 24.5–30 | See what happened. | Muted actual web-app QA recording, source seconds 18–23.5, full aspect ratio | Source-video playback; opacity dissolve/copy |
| 30–35.5 | A working app. Yours to inspect. | Native rescue-charts iPhone screenshot with clean open framing; same Linux VM price | Slow dolly; opacity dissolve/copy |
| 35.5–40.5 | macOS + iOS / Build. Run. See it. | Supplied white Devin wordmark | Very slow dolly; opacity dissolve |

Only camera pushes with tiny lateral drift; no spring, parallax, spin, sweeping
cursor, fake typing, or scrolling animation. Lower-thirds stay anchored, enter
with ease-out, and leave before the next caption arrives. Camera moves use ease-in-out. Streaks and seeded SVG grain are
static photographic treatments, not additional motion families. Scene dissolves
share the opacity family; the outgoing camera is clamped at its endpoint during
the overlap. In the evidence transition, its outgoing source is held at its
endpoint once its scene ends.

## Source provenance and truthfulness

- All source assets are the supplied committed files under `public/assets`.
- `devin-web-18.png`: native iPhone rescue-charts UI. The hook uses its top-right
  Done button; context/outcome isolate the phone. Crops preserve source aspect
  ratio; UI is not redrawn. This is a supplied still, not newly captured footage.
- `devin-web-10.png`: Wisp iPhone with an existing typing/cursor annotation.
  The interaction shot is a representative motion layout of that still.
  The fix scene shows its actual review excerpt including **12 passed, 3 failed,
  2 untested**. These results are never changed or described as all passing.
- `devin-testing-2.mp4`: actual **web-app QA**, inserted at original speed from
  18 seconds and visibly labeled “Actual recording / web-app QA example”.
  It is not iOS footage. `OffthreadVideo` is muted. At the next scene's 18-frame
  dissolve the clip holds its last frame so only the incoming camera moves.
- `logo-white.png`: original white wordmark, unchanged and fitted by width with
  automatic height. It closes against a dark background.
- Build and fix code lines are staged illustrative workflow graphics, not logs
  from these demos and not a claim that the Wisp failures were fixed. A visible
  illustrative label distinguishes them. The source screenshots are separate
  examples; they are not presented as a measured before/after sequence.
- `20+ minutes` is the brief's prior CI context, not a measured benchmark. No
  time savings, pass-rate claims, signing, distribution, or real-device support
  are implied. One full iPhone is shown at a time; the interaction inset is an
  enlarged detail of the same screenshot.

## Offline media QA

Deliver the CRF 18 H.264/YUV420p render, a full-frame poster, and a contact sheet
from the encoded MP4 under ignored `out/`. Inspect all eight scenes and each
dissolve boundary, including the final frame. Confirm 1920×1080, 30fps and
40.5 seconds with ffprobe. Decorative screenshot microcopy outside the focal
plane is intentionally soft; primary narrative and provenance labels remain sharp.
The film is silent by design and demonstrates launch concepts using supplied
native stills, not a fresh end-to-end native testing session.

On macOS, after rendering, the optional self-contained AppKit helper extracts and
labels 24 chronological frames from the MP4, covering every scene and every
dissolve. It needs Swift and ffmpeg on PATH and writes only to ignored `out/`.
If scene timing changes, update its frame list.

```sh
swift templates/13-cinematic-macro/contact-sheet.swift
ffmpeg -y -i out/13-cinematic-macro.mp4 \
  -vf "select='eq(n,975)'" -frames:v 1 out/13-cinematic-macro/poster.png
ffprobe -v error -show_streams -show_format out/13-cinematic-macro.mp4
```
