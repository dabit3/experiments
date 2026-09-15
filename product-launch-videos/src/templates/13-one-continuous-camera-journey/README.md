# 13 · One Continuous Camera Journey

Eight destinations occupy one long, left-to-right canvas. The camera follows a
thin continuous baseline, settles exactly at each stop and stays still while the
UI is read. A restrained 2.5% pullback is confined to the 0.6-second travels.
Nothing rotates, dissolves or swaps between screens. The two iPhone screenshots
are separate spatial destinations, explicitly labeled as stills from different
apps. The title and CTA are large, quiet typographic destinations.

## Render

From `product-launch-videos/`, with Node 22.12+, npm, Python 3.9+ and FFmpeg:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run render -- --template 13-one-continuous-camera-journey
npm run still -- --template 13-one-continuous-camera-journey --frame 450
npm run still -- --template 13-one-continuous-camera-journey \
  --frames 0,108,150,270,330,399,450,516,570,650,750,879,960,1040,1140,1199
npm run contact-sheet -- out/13-one-continuous-camera-journey
```

The expected full film is 1920 × 1080, 30 fps, 1,200 frames / 40 seconds, silent
H.264. Outputs stay in the ignored `out/13-one-continuous-camera-journey/`.
Original footage, screenshots, logos and fonts stay in ignored `public/assets/`.
No network fonts or generated replacement product media are used.

## Editability

`config.ts` is the complete typed input. Alternatively copy the render's
`resolved-props.json`, change values and pass `--props your-complete-props.json`.
Props must contain the complete `{ "config": ... }` object, not a partial patch.

Generate a diagnostic edit with a changed caption, a camera stop offset and
43-second duration:

```sh
npx tsx src/templates/13-one-continuous-camera-journey/example-props.ts \
  > out/13-one-continuous-camera-journey/edited-props.json
npm run still -- --template 13-one-continuous-camera-journey \
  --props out/13-one-continuous-camera-journey/edited-props.json --frame 210 \
  --output out/13-one-continuous-camera-journey/edited-poster.png
```

| Input | Effect |
| --- | --- |
| `copy.*`, `labels.*` | Launch captions, benefit, pricing, CTA and editorial context |
| `durations.*` | Seven scene durations; recomputes actual Remotion duration and all camera stops |
| `media.*.asset` | Original image/video selection; iPhone is an ordered two-still tuple |
| `media.*.framing` | Contain/cover, normalized anchors and optional source-pixel crop |
| `media.*.sourceStartSeconds` | Explicit recording trim; playback always remains 1× |
| `brand.colors`, `brand.typography` | Brand surfaces, families, heading/body sizes, tracking, line heights |
| `layout.margin`, `layout.padding`, `layout.gutter`, `layout.captionHeight` | Caption and media layout |
| `canvas.stops.*.{x,y}` | Actual product-plane locations and camera stopping points |
| `canvas.titleSize`, `titleWidth`, `logoWidth`, `captionSize`, `labelSize` | Canvas typography and proportional logo scale |
| `canvas.mediaTop`, `mediaBottom`, `railY` | Reserved caption/footer areas and continuous baseline |
| `motion.travelSeconds` | Travel duration, capped at 18% of the shortest scene to retain readable holds |
| `motion.iphoneSplit` | 0.25–0.75 fraction at which the second iPhone stop is reached |
| `motion.travelPullback` | 0–0.1 temporary scale reduction; every hold returns to exactly 1 |
| `motion.railWeight` | Continuous baseline stroke width; 0 hides it |

Keep stops ordered left-to-right with at least 1,980 px horizontal spacing.
Small y offsets are supported; the baseline follows the same editable points.
The default path is deliberately straight. Long copy or changed margins should
be checked with fresh full-resolution stills. Font names must resolve to the
original families loaded by the shared font gate.

## Timing and source fidelity

Default stop arrivals: 0, 4, 9, 13.6, 17.5, 22, 29.6, 35 seconds.
Agent playback is exactly source 0–4s at output 9–13s. Web QA playback is
exactly source 0–7s at output 22–29s. The camera never moves during either
recording. Camera arrivals happen before video playback, departures after it.
First/last genuine clip frames are held during surrounding travel, without
altering the complete 1× recording interval. These brief edge-frame holds are
framing bridges, not additional captured action.

The Mac environment screenshot uses a fixed, configurable crop
`{x:560,y:440,width:1920,height:990}` to enlarge the authentic composer/menu.
All report screenshots remain uncropped. Captions and editorial source labels
are outside the UI. The shared video component supplies the persistent **Web QA
example** footer. The Afterhours report's 8 passed / 0 failed / 1 untested summary
remains visible. This is a montage, not a causal story between unrelated apps.
See `attribution.json` and the project's `MEDIA-ATTRIBUTION.md` for provenance.

## Checks

```sh
npm run lint
npm run typecheck
npm test
npx tsx --test src/templates/13-one-continuous-camera-journey/journey.test.ts
npm run build
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/13-one-continuous-camera-journey/13-one-continuous-camera-journey.mp4
```

The direction tests check full recording-interval camera stability, monotonic
continuous travel, return to exact scale 1, and recalculation under edited
durations and positions.

### Production validation

- Original asset inventory and SHA-256 validation passed for all 45 files.
- ESLint, TypeScript, gallery build, 11 shared/script tests and 3 direction tests
  passed.
- The complete default MP4 rendered with concurrency 2. `ffprobe` verified H.264,
  1920 × 1080, 30/1 fps, 1,200 frames and 40.000000 seconds. FFmpeg decoded the
  entire film without errors. The encoder reports full-range 4:2:0 (`yuvj420p`).
- Sixteen exact frames were inspected across the intro, every travel, all
  product destinations and the final CTA. The deliverable poster is frame 450;
  the final contact sheet and poster are extracted from the encoded MP4.
- The diagnostic configuration resolved to 1,290 frames / 43 seconds. Rendered
  frame 210 displays “Choose your hosted Mac.” and frame 1289 displays the CTA.
  This verifies actual metadata and rendered copy changes, beyond unit tests.

### Limits

Native Simulator examples are authentic stills, not recordings. Fine report
body text is constrained by the supplied screenshots and full-report framing;
the summary counts remain visible. As the camera travels, outgoing and incoming
planes naturally cross the screen edge; all reading holds are fully framed.
Long or unusual replacement copy and extreme layout changes need fresh frame
inspection. Longer video scenes must fit the supplied recording duration and
will fail explicitly on source overrun. The 43-second diagnostic was validated
with metadata and stills, not a second full MP4.
