# 17 · Cinematic Noir

Restrained brand darkness, stationary typography, and a two-stage mechanical
aperture: first a narrow slit, then a clean rectangular opening. Thin white rails
sit strictly outside the product. The environment menu includes a user-requested
recreated Ubuntu-to-macOS selection animation. Other source UI is unchanged;
no atmospheric effects, dimming or sound.

## Render

From `product-launch-videos/`, after installing the shared foundation and asset ZIP:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run templates:list
npm run lint
npm run typecheck
npm test
npx tsx --test src/templates/17-cinematic-noir/motion.test.ts
npm run build
npm run render -- --template 17-cinematic-noir
npm run still -- --template 17-cinematic-noir --frame 240
npm run still -- --template 17-cinematic-noir \
  --frames 60,127,155,171,191,240,330,450,600,750,960,1140
npm run contact-sheet -- out/17-cinematic-noir
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/17-cinematic-noir/17-cinematic-noir.mp4
```

The independent entry is `src/templates/17-cinematic-noir/entry.tsx`;
composition ID is `CinematicNoir`. Gallery discovery requires no registry changes.
All outputs are ignored under `out/17-cinematic-noir/`.

## Edit

`config.ts` is the complete typed input. Alternatively copy the generated
`out/17-cinematic-noir/resolved-props.json` and pass the complete edited
`{"config": ...}` to `--props`. Partial configurations are not deep-merged.

- **Copy:** `copy` contains all seven captions, feature name, benefit, CTA,
  pricing and URL. `labels` contains the separate-session, still and 1× labels.
  The shared web recording footer always says **Web QA example**.
- **Media:** every image/video selection has source asset and `framing`.
  Set `framing.crop` using original-source pixels; fit and normalized anchors
  are editable. The default environment crop is `(560,410,1920,1030)`.
  All report stills and both recordings are fully contained by default.
  Source replacements use the shared verified asset inventory.
- **Durations:** all seven `durations` are in seconds. Remotion metadata derives
  the composition duration; it is not fixed at 1200 frames. Keep the iPhone
  duration at least 2 seconds to leave two readable still holds.
- **Video trims:** `sourceStartSeconds` is independent of scene placement.
  Playback remains 1×, and out-of-bounds source trims fail. The agent source has
  9.166667 seconds and the Web QA source has 59.133333 seconds.
- **Brand:** approved dark exterior `brand.colors.ink` and white
  `brand.colors.white`; typography family, size, line height and tracking remain
  editable. The default is NB International Regular. The shared font gate
  waits for the original WOFF2 files.
- **Layout:** `layout.margin`, `gutter`, `padding` (exterior rail distance),
  `captionHeight`, and `layout.grid` control title position/width, logo width,
  bottom rule, caption size and footer size. Increase the caption reserve for
  longer captions; all copy sits outside media.
- **Masks:** `shutterFrames`, `shutterAxis`, `slitSize`, `slitPhase`, and
  `stillExitFrames` configure the aperture. Transitions automatically shorten
  to at most a quarter of the available hold. Shutters never mask source videos.
- **Holds:** `intertitleFrames` sets the quiet iPhone title; `iphoneSplit`
  allocates remaining time between the two screenshots. `resultHoldFrames`
  carries the unchanged iPad result into closing before the CTA.
- **Titles:** `titleFadeFrames` changes opacity arrival only. Captions and all
  typography remain stationary during recordings.
- **Lighting:** `lightingEnabled`, `edgeLightOpacity`, `edgeLightLength`,
  `edgeLightTravel` change the exterior rails only. No source pixels are tinted.
- **Environment selection:** `environmentAnimationEnabled`,
  `environmentHoldFrames`, `environmentMoveFrames`, `environmentClickFrames`
  control the initial Ubuntu hold, highlight/pointer movement and macOS click.
  Timing compresses automatically in shorter scenes to reserve the final macOS
  hold. Disabling animation holds macOS highlighted and checked. Older complete
  configs without these optional fields use the default animation.
  The reconstruction uses source-coordinate icon/text crops from `devin-web-4.png`
  and follows the configured media framing. Ubuntu's grey sprite background is
  normalized before compositing onto the moving highlight. The initial trigger
  and check show Ubuntu; they switch to macOS after the pointer arrives.
  Replacing the environment asset disables the source-specific reconstruction.
  `labels.environment` defaults to **Environment selection animation**.

## Default edit

| Time | Treatment |
| --- | --- |
| 0–4 | Spacious logo/opening/benefit on #191919 |
| 4–9 | Recreated Ubuntu-to-macOS selection, then highlighted/checked macOS hold |
| 9–13 | Unmasked agent-selection recording, source 0–4 seconds |
| 13–13.6 | Brief quiet iPhone caption composition |
| 13.6–17.8 | Afterhours Maze full still and original report |
| 17.8–22 | Large Dispatch full still and original report |
| 22–29 | Unmasked Web QA recording, source 0–7 seconds, persistent label |
| 29–35 | Terra Table full iPad still and report |
| 35–36.4 | Same iPad still held under pricing copy, then shutter closes |
| 36.4–40 | Logo, CTA, pricing and URL held on dark canvas |

This is a montage of separate examples. iPhone/iPad sources are honest stills;
neither video is Simulator footage. The first iPhone report's **1 untested**
count remains visible. See `attribution.json` and the shared
`MEDIA-ATTRIBUTION.md` for provenance. Attribution times describe the default
sample; edits to scene timing require corresponding attribution updates.

## Verification and constraints

An executable editability example produces a complete config with a longer
caption, a vertical shutter and durations totaling **41.5 seconds / 1245 frames**:

```sh
npx tsx src/templates/17-cinematic-noir/write-example-props.ts
npm run still -- --template 17-cinematic-noir \
  --props out/17-cinematic-noir/editability/props.json --frame 180 \
  --output out/17-cinematic-noir/editability/caption.png
```

Check the resulting metadata for 1245 frames and the PNG for the alternate
caption. The shared CLI writes metadata/props to the template's output root even
when `--output` is custom: render the default sample afterward to restore its
metadata. The example only renders an editability still, not a second full film.

Validated 2026-09-15:

- Full H.264 sample: **1920 × 1080**, **30/1 fps**, **1200 decoded frames**,
  **40.000 seconds**, silent. Full FFmpeg decode completed without errors.
- `assets:check`, template discovery, ESLint, TypeScript, Vite build and the
  shared test suites passed (8 TypeScript tests and 3 Python tests).
  Five template-specific tests cover the selection sequence, compressed timing,
  disabled animation, zero-duration transitions and older configurations.
- The alternate config above resolved to **1245 frames / 41.5 seconds**;
  frame 180 rendered with its edited caption fully visible.
- Original full-size stills and frames decoded from the final MP4 were
  inspected across titles, shutters, all five product scenes and closing.
  No unintended clipping, caption/source overlap or missing media was found.
  The first iPhone report retains **8 passed / 0 failed / 1 untested**.
- Revision poster is final MP4 frame **240**, showing macOS highlighted and
  checked. The revised contact sheet uses actual decoded MP4 frames **60, 127,
  155, 171, 191, 240, 330, 450, 600, 750, 960, 1140**, in reading order.
  Frames 155–240 show the initial Ubuntu state, moving highlight, macOS selection
  and stable final hold. The environment clip is the full 4–9 second scene.

The final artifact URLs are reported with the producer handoff.
UI testing and public deployment are outside this media-rendering task.
Source media, font binaries and rendered artifacts are not committed.

Very long custom copy requires widening the title or increasing caption reserve.
Changing a report crop is an editorial choice: preserve all failed and untested
counts. Do not extend a source recording past its original duration.
