# 20 — Screencast Studio

A 44-second, silent, 1920 × 1080 / 30 fps launch film. A soft, static
lavender/blue/sand wallpaper holds a centered recording window with restrained
shadows. The window remains the central visual until the supplied Devin logo
end card. Large narration captions sit below the recording.

## Edit and render

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 20-screencast-studio
```

`config.ts` owns headline copy, chapter captions, scene lengths, video choice and
in-point, camera tracks, and cursor tracks. `index.tsx` owns the studio window,
representative native layouts and crop coordinates. `motion.tsx` implements the
interpolation. Keep `template.json` duration in sync after editing scene lengths.
The registered composition ID is `Launch`.

### Motion editing

All coordinates are local to the 1408 × 674 recording viewport, below its title
bar. Cursor `{frame, x, y}` points are relative to each scene; duplicated
coordinates create holds. Cubic ease-in-out interpolation smooths the synthetic
cursor between points without tracking mouse events or using real time.
Click rings are part of that cursor family. The original cursor embedded in a
source screenshot or source recording is unchanged; smoothing applies only to
the representative overlay cursor, not to the supplied recorded pointer.
The overlay becomes a small circular touch indicator in the native phone region,
so it does not add a second arrow over the source screenshot's captured pointer.

Camera `{frame, scale, x, y}` points are also scene-relative and use cubic
ease-in-out. The native camera starts after the 24-frame entrance, zooms to 1.055
toward the Simulator, then returns. A short 0.984→1 window scale and upward
movement provide the recording's entrance. These transforms form one camera/
window motion family. The live recording zoom is 1→1.36→1 around the actual
web deletion dialog. Its source playback is the second motion family.

Captions enter with the window's entrance; they stop before the camera/cursor
interaction begins. Step selections and screenshot swaps are hard cuts,
not additional animation families. Scene changes are clean editorial cuts
followed by a 24-frame ease-out entrance, keeping consecutive headlines from
overlapping. The end card remains visible from its first frame. The
wallpaper does not animate. No CSS animation, spring randomness, remote image,
remote font, or time-dependent rendering is used.

## Scene plan

| Time | Beat / narration caption | Window media | Motion families (maximum two) |
| --- | --- | --- | --- |
| 00–04 | Hook: Devin now runs on macOS + iOS. | Representative session, real rescue-chart iPhone crop | Unified window/caption/camera entrance; smoothed cursor |
| 04–08 | Context: Feedback used to mean waiting. | Same iPhone, manual QA / prior 20+ minute CI context | Window/caption entrance only |
| 08–14 | Build/run: Build and run in a managed Mac VM. | Representative Xcode → Simulator workflow, native iPhone | Window/camera; smoothed cursor |
| 14–21 | Interact: Tap. Type. Scroll. In iOS Simulator. | Supplied game, Wisp typing and rescue-chart phone crops, one at a time | Window/camera; smoothed gesture cursor |
| 21–28 | Loop: Reproduce the bug. Fix it. Test again. | Wisp screenshot with an explicit source failure note; illustrative stages | Window/camera; smoothed cursor |
| 28–35 | Evidence: Review the recording. See what happened. | **Actual web QA video**, source seconds 11–18 | Window/camera; original video playback |
| 35–40 | Outcome: A working app you can inspect. | Representative session with native iPhone; same Linux VM price | Window/camera only |
| 40–44 | Logo end card: macOS + iOS / Build. Run. See it. | Supplied black Devin wordmark | Unified ease-out logo/type reveal |

The stage captions are editorial narration, not a spoken voice track.
Audio is intentionally silent; source audio is muted. The root encoder retains
a silent AAC stream alongside the H.264 video.

## Media provenance and truthfulness

- `public/assets/devin-web-18.png`: supplied native iPhone Simulator rescue-chart
  screen. The phone crop preserves image proportions and screenshot contents.
  It is used for hook, context, build, scroll and outcome.
- `public/assets/devin-web-14.png`: supplied Afterhours Maze iPhone Simulator,
  used for the tap moment. No new game result is invented.
- `public/assets/devin-web-10.png`: supplied Wisp Simulator typing screenshot,
  used for the type and feedback-loop moments. The source reports **12 passed,
  3 failed and 2 untested**. The film explicitly notes the context/pricing
  failure and never replaces it with a passing result.
- `public/assets/devin-testing-2.mp4`: supplied **web-app QA recording**, displayed
  with the persistent label “Source recording · Web app QA.” Source seconds
  11–18 show the real ticket deletion dialog and cancellation. This is neither
  native iOS footage nor a Mac VM provisioning demonstration. The embedded
  evidence counts belong to that historical web test only.
- `public/assets/logo-black.png` and `mark-black.png`: supplied brand assets,
  used unmodified with preserved aspect ratios on light surfaces.

The native session chrome, build steps, cursor, click rings and gesture
storytelling are **representative motion UI**, visibly labeled “Illustrative
workflow.” Native screenshots are stills. The film is not a newly captured
native test run; cursor movement over a screenshot does not assert a newly
executed tap/keystroke/scroll. The three interaction examples use separate
supplied apps, one visible phone at a time. Reproduce → fix → retest is a
capability sequence, with no fabricated fix diff or successful retest.

The 20+ minutes statement is the launch brief's prior CI context, not a measured
benchmark. No execution-time claims, shipping/signing claims, real-device
claims, or unsupported sensors are included. Phone crops deliberately omit
unrelated desktop wallpaper and evidence panels; no test results are recolored.

### Replaceable recordings

Change `studio.sourceVideo.file` to another local `public/assets` recording and
adjust `startSeconds`, label and camera coordinates to its truthful content.
Use the matching scene duration, ensure the file contains enough frames, and
retain `OffthreadVideo muted`. The frame uses `objectFit: contain`; the
programmed zoom deliberately crops surrounding UI while preserving image
proportions. Native replacements are controlled by `phoneCrops` in `index.tsx`:
source dimensions/crop coordinates are in original source pixels; scale is
uniform. Use `Img` for stills and keep every dependency local at render time.

## Brand and limits

The reference is the coordinator-inspected Figma website file
`evS5ExlrnLrUCMPm395OHw`, nodes `1:5911`, `1:6790` and `1:5923`, described in
the root README and `shared/brand.ts`. This direction adapts its pale surfaces,
blue/green accents, compact radii and typographic restraint to a screencast.

NB International Pro and Inter binaries were not provided. The explicit font
fallback is **Helvetica Neue → Helvetica → Arial → sans-serif**, using installed
system fonts. Font metrics may differ on another operating system. No font
download is required. Full-resolution supplied crops may contain small embedded
UI text; editorial captions and workflow labels are independently typeset for
legibility. Generic source recording audio is muted. No original Socials file
was used.

## Offline QA and outputs

The final MP4 is `out/20-screencast-studio.mp4`. Full-frame poster and labeled
scene/transition contact sheets are generated from this encoded MP4 under
ignored `out/`. These rendered files must not be committed. Verification uses
the root lint/typecheck/validate scripts, the prescribed full-quality H.264
render, ffprobe and extracted stills, with no browser UI testing.

On macOS, regenerate the poster and a labeled 32-frame contact sheet from the
finished encode (requires the installed Swift toolchain and ffmpeg):

```sh
swift templates/20-screencast-studio/qa.swift out/20-screencast-studio.mp4 out
ffprobe -v error -show_streams -show_format out/20-screencast-studio.mp4
```

`qa.swift` samples each scene, all three interactions, all loop stages, the
actual dialog zoom, the first/last frame and every scene-boundary entrance. Adjust
its sample frames after changing the timeline. It only writes under the supplied
existing output directory.
