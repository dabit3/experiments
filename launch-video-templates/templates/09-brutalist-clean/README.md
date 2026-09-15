# 09 — Brutalist Clean

A 40-second, silent, 1920 × 1080 / 30 fps launch film. Massive black typography,
tight leading, warm off-white paper, a single hard blue underline, thick square
screenshot frames, and a black feature ticker that runs uninterrupted from the
first frame through the logo hold.

## Edit and render

Run from `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 09-brutalist-clean
```

For an MP4 with no silent audio track, render with
`npm run render -- 09-brutalist-clean --muted`. This is the final-deliverable
command. The composition also independently mutes its source video.

`config.ts` is the copy/timing control surface: `scenes` contains the ordered
headlines, durations in seconds, captions, underline targets, and type sizes.
`interactionStages` sets the tap/type/scroll source images and their cut times.
`media` controls crop coordinates, source clip in-point, provenance labels, and
ticker copy. `design` contains typography, colors, entrance duration, and ticker
speed. `index.tsx` contains the composition and reusable layout elements.
When changing scene durations, keep `template.json`'s `durationSeconds` equal to
their sum. Keep interaction stage offsets within that scene's duration.

The root command renders H.264, yuv420p, CRF 18 with two rendering workers.
Output is the ignored `out/09-brutalist-clean.mp4`. No media is fetched from the
network at render time; Remotion may install its own browser on first use.

## Scene timings and motion budget

| Time | Beat / primary copy | Media | Concurrent motion families |
| --- | --- | --- | --- |
| 00–04 | Hook: DEVIN. NOW NATIVE. | Native iPhone crop from web-18 | Linear ticker + one grouped ease-out entrance |
| 04–08 | Context: MANUAL QA. OR WAIT. | Typographic 20+ MIN CI context | Ticker + grouped ease-out entrance |
| 08–13 | 01: BUILD IT. RUN IT. | Native maze app from web-14, static illustrative pipeline | Ticker + grouped ease-out entrance |
| 13–19 | 02: TAP. TYPE. SCROLL. | web-14 → web-10 → web-18; changes at 13/15/17s | Ticker + grouped entrance during first 20 frames; subsequent changes are hard cuts |
| 19–24 | 03: REPRODUCE. FIX. RETEST. | Original Wisp mixed-result evidence crop from web-10 | Ticker + grouped ease-out entrance |
| 24–30 | 04: SEE WHAT HAPPENED. | Actual web-app QA clip, source seconds 12–18 | Ticker + source-video playback; all other elements static |
| 30–36 | Outcome: A WORKING APP. IN VIEW. | Native iPhone crop from web-18; same-price statement | Ticker + grouped ease-out entrance |
| 36–40 | Supplied Devin logo; BUILD. RUN. SEE IT. | Original black logo | Ticker + grouped ease-out entrance |

Everything is derived from Remotion's current frame. Scenes cut directly with no
empty interstitial frame. Entrances translate the scene body as one group by 28px,
using cubic ease-out over 20 frames; type, media, and underline do not animate
independently. The underline switches at hard cuts in the interaction scene.
The ticker is a continuous linear marquee, not a scene entrance. There are no
continuous moves other than the ticker, no oscillation, no runtime CSS animation,
no random values, and no independent cursor, progress, or staged success animation.
The video scene has no entrance, so its footage and the ticker exhaust the two
motion families. Audio is intentionally absent; source audio is muted.

## Source provenance and truthful framing

All sources are supplied files in `public/assets`:

- `devin-web-18.png`: native rescue-chart iPhone Simulator and review UI.
  A fixed crop of the complete phone with surrounding source desktop appears in
  hook, interaction, and outcome. It is an original screenshot, not new footage.
- `devin-web-14.png`: native Afterhours Maze iPhone Simulator. The complete
  portrait phone appears in build/run and the tap step. Its source result summary
  includes an untested case; this film does not claim the suite fully passed.
- `devin-web-10.png`: native Wisp screenshot. The type step uses its phone crop.
  The reproduce/fix/retest scene uses its **original mixed results**, retaining
  “12 passed / 3 failed / 2 untested” and the source explanation. We do not change
  failures into successes or imply a later fix was captured.
- `devin-testing-2.mp4`: supplied 1918 × 1080, 30 fps web QA recording. Its
  six-second insert is actual muted source video at normal speed, contained in
  a thick black frame with full original aspect ratio. The always-visible label
  says **SOURCE RECORDING / WEB-APP QA**. It demonstrates generic recorded
  evidence, not native iOS footage.
- `logo-black.png`: original supplied wordmark, rendered at its native aspect
  ratio. Multiply compositing removes only the white plate against off-white,
  leaving the black artwork unchanged.
- The desktop model-selector video is intentionally unused.

The pipeline, tap/type/scroll sequence, and overall native workflow are editorial
representations using supplied screenshots. Native phone scenes visibly say
“Illustrative workflow”; the reproduce/fix/retest footer says the same and notes
that source checks include failures. No synthetic phone content or test outcomes
are inserted. The sources depict different apps; hard cuts are editorial examples,
not a claim that they are a single continuous test. Only one phone is shown at a
time. The ticker names capabilities; it is not a live execution status.

“20+ minutes” is the prior CI context supplied in the brief, not a speed metric.
“Same price as Linux VMs” is supplied launch messaging. There are no claims about
shipping/signing, App Store distribution, physical devices, or guaranteed results.

## Brand and font limitations

The corrected Figma reference and observed values are recorded in the shared
README and `shared/brand.ts`. This direction adapts the dense Helvetica-like
headlines, restrained spacing, and observed `#1971c2` blue into a brutalist layout.
The warm paper `#f4f3ed`, near-black `#080808`, oversized 130–204px headline sizes,
and thick frames are deliberate template-specific treatments.

NB International Pro font binaries were not supplied. The explicit fallback is
**Helvetica Neue**, then Arial, then the system sans-serif; labels use Menlo,
Consolas, monospace. The final render uses the macOS system fonts. Rendering on
another OS can change glyph metrics; recheck headline fits if the fonts differ.
The source UI retains its original screenshot typography.

## Offline QA

Inspect the full-frame poster and a contact sheet of all eight scenes, the three
interaction stages, and the frames immediately before/at/after each scene change.
Use `ffprobe` to confirm H.264 / 1920 × 1080 / 30 fps / 40.0 seconds.
On macOS, `swift templates/09-brutalist-clean/qa.swift` regenerates the full-frame
poster at 2s and a labeled 36-frame contact sheet under ignored `out/`. It requires
FFmpeg and the system Swift/AppKit toolchain, with no additional packages. Update
its frame-sample table if you change scene timings. Remotion emits full-range
8-bit 4:2:0 H.264 on this machine (reported as `yuvj420p` by ffprobe).
Detailed product UI is documentary supporting media, not intended as main copy.
All primary headlines and provenance labels are large, high contrast, and within
the title-safe inset. The ticker intentionally enters/exits beyond the frame edge.
No browser login or newly recorded native test is part of this rendered-media QA.
