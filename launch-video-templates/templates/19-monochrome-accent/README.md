# 19 — Monochrome Accent

A 42-second, silent, 1920×1080 / 30 fps launch film. Large black-and-white
typography, blue-selective native iPhone imagery, and hard rectangular wipes.

## Edit and render

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 19-monochrome-accent
# Explicit delivery encoding:
npm run render -- 19-monochrome-accent --color-space=bt709 --muted
```

`config.ts` holds all primary headlines, scene boundaries (seconds), the brand
accent, font stacks, gesture labels, and entrance/wipe durations. Scene-specific
supporting captions and layout geometry live in `index.tsx`. If changing total
duration, update both `config.ts` and `template.json`. Composition ID is `Launch`.
No shared configuration changes are required.

The default render on the supplied macOS toolchain was reported by ffprobe as
full-range `yuvj420p`, despite the shared renderer requesting `yuv420p`. The
delivery command explicitly selects BT.709, yielding limited-range `yuv420p`,
and omits the otherwise silent AAC track. This is an option passed through the
existing render command; the shared renderer is unchanged.

Generated screenshots are committed inside this template for offline rendering.
To regenerate them, run the following from the collection root. Python 3 and
FFmpeg are the only preprocessing requirements; no Python package is needed.

```sh
python3 templates/19-monochrome-accent/prepare_assets.py
```

## Scene plan

| Time | Primary copy / purpose | Media | Concurrent motion families |
|---|---|---|---|
| 0–4.5 | Your apps. Now in reach. | Native Afterhours Maze iPhone crop | Static opening; outgoing rectangular wipe |
| 4.5–8.5 | Manual QA. Or 20+ min of CI. | Geometric wait motif | Rectangular wipe; eased type entrance |
| 8.5–14 | Native apps. Managed Mac VMs. | Supplied macOS session excerpt + native iPhone | Rectangular wipe; eased layout entrance |
| 14–19.5 | Tap. Type. Scroll. | Wisp iPhone screenshot; illustrative gesture ring | Rectangular wipe/entrance first; later one gesture family and discrete word emphasis |
| 19.5–25.5 | Reproduce. Fix. Retest. | Native Wisp report, including failure counts | Rectangular wipe; eased entrance / discrete word emphasis |
| 25.5–32 | Watch the work. | Actual supplied web QA clip, starting at source 6s | Source playback; wipe then eased layout entrance |
| 32–38 | A working app. In your session. | Native review screenshot + enlarged same iPhone crop | Rectangular wipe; eased layout entrance |
| 38–42 | Devin / macOS + iOS / Build. Run. See it. | Original supplied white Devin logo | Rectangular wipe; eased entrance, then still hold |

The `20+ min` statement describes the supplied prior CI context, not measured
latency or an achieved speedup. The outcome states the supplied launch fact,
“Same price as Linux VMs.” No performance, shipping, or all-tests-pass claim.
The blue bars at the foot are scene markers, not a measured job timeline.

## Color treatment

The single accent is the observed Figma blue `#1971c2`. Neutrals are black,
white, and their gray values. `prepare_assets.py` decodes pixels, calculates hue,
and retains **the original RGB values at full saturation** for blue hues from
194° through 224° with channel spread >8, around the brand blue's 210° hue.
Every other pixel is converted to Rec.709-weighted grayscale. This preserves
source cursor rings, blue desktop areas and compatible review highlights;
the more violet maze outline is desaturated. This is real selective color, not a grayscale screenshot with
an added accent overlay. The original shared media remains untouched.

`assets/provenance.json` records source crops and exact counts of preserved and
desaturated pixels. Each resulting image retains its crop's native aspect ratio.
Local assets use Remotion's bundled asset imports; the original logo and video
use `staticFile`. All imagery is displayed with `Img`; footage uses muted
`OffthreadVideo`. The web recording is grayscale to keep incidental purple and
green out of this design.

## Source provenance and representative UI

- `devin-web-14.png`: supplied Afterhours Maze native iPhone Simulator screenshot.
  The phone crop is used in the hook and build scene. Original in-app text and
  interface are preserved; color alone is treated.
- `devin-web-10.png`: supplied Wisp iPhone and report. The mixed result set
  (12 passed, 3 failed, 2 untested) is preserved. This film does not claim those
  failures were repaired. The repair scene illustrates the workflow capability.
- `devin-web-13.png`: supplied macOS agent-session text excerpt. The clean frame
  and Build → Run diagram are representative layout, not a newly recorded run.
- `devin-web-18.png`: supplied native iPhone review. The outcome enlarges the
  same phone shown in the review for legibility. These are two views of the
  **same supplied screenshot**, not two simultaneously controlled devices.
- `devin-testing-2.mp4`: supplied generic web-app QA recording, used at source
  6–12.5 seconds (plus a brief outgoing wipe). The on-screen label explicitly
  identifies it as an actual **web-app QA example**, never native iOS footage.
- `logo-white.png`: supplied original Devin wordmark, shown unmodified, at its
  original aspect ratio, on black. No reconstructed or recolored logo.

Native UI is supplied still imagery with representative motion layout. The
gesture ring and Tap/Type/Scroll emphasis illustrate available interaction
categories; they do not show a newly executed test. The build and interaction
scenes carry the “Illustrative workflow” label. Original native screenshots
may contain legacy model names, incidental metrics, and app-specific details;
those are source content, not launch performance claims.

## Motion, typography, and limitations

- Frame-based deterministic animation only; no random, wall-clock, CSS runtime
  animation, external network assets, or remote font.
- Cubic ease-out entrances; cubic ease-in-out wipes/gesture moves. Discrete
  emphasis changes are intentional hard cuts.
- Wipe and entrance phases do not overlap. The source-video scene uses at most
  playback plus one other family. Interaction begins after its layout entrance.
- The first frame is fully composed. Outgoing scenes remain underneath incoming
  wipes; no black filler, unintentional empty frame, or fade through blank.
- Geometric, heavy sans fallback: locally installed **Arial Black**, then
  Helvetica Neue / Arial. Supporting text uses Helvetica Neue / Arial. These
  are system fonts, not the unavailable NB International Pro font files.
  Figma reference is adapted, not pixel-copied.
- Intentionally silent; all incidental source audio is muted.
- No newly captured iOS video. No signing, distribution, real-device, or
  unsupported Apple-service claims.

## Offline media QA

The finished output and QA images belong under ignored `out/`, never in git.
Use `ffprobe` for dimensions, rate, codec, frame count and duration; sample
every scene and both sides / midpoint of all seven transitions. The poster
is a full-frame still from the final MP4, not a separate mockup.

On macOS, the supplied QA helper automates this extraction and creates a labeled
contact sheet using Swift/AppKit (no additional packages):

```sh
python3 templates/19-monochrome-accent/qa.py
```

It verifies H.264, yuv420p, 1920×1080, 30 fps, 1260 frames and 42 seconds, then
extracts 31 full-resolution frames: eight story moments, the first and last
frames, and three samples around each of seven scene changes. The Swift helper
is only for making the review sheet; the Remotion template also renders on
other platforms with its documented system-font fallbacks.
