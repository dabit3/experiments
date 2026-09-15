# 06 · Contemporary Museum Gallery

Three exhibition walls: **Hosted Mac**, **iPhone Simulator**, and **Test & review**.
Each has an accession number, short side label, quiet architectural seam, soft
light and a large front-facing display. The first still on a wall approaches
gently; recordings are locked in position at normal speed. Deliberate cuts
separate examples, with a short lateral departure between the second and third
walls. The final iPad result gives way to a minimal pricing / CTA wall.

The seven-part edit uses the shared 4 / 5 / 4 / 9 / 7 / 6 / 5 second durations:
40 seconds, 1920 × 1080, 30 fps, silent H.264. Product occupies 31 seconds.
Source reports are full-frame contained, including the Maze untested count.
The environment crop magnifies the actual macOS menu and composer.

## Setup and render

From `product-launch-videos/`, using the shared foundation:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run templates:list
npm run lint
npm run typecheck
npm test
npm run build
npm run render -- --template 06-contemporary-museum-gallery
npm run still -- --template 06-contemporary-museum-gallery --frame 450
npm run still -- --template 06-contemporary-museum-gallery \
  --frames 0,60,120,150,269,300,390,450,550,659,690,780,900,1020,1080,1170
npm run contact-sheet -- out/06-contemporary-museum-gallery
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/06-contemporary-museum-gallery/06-contemporary-museum-gallery.mp4
```

Generated outputs and all source media/fonts stay in the foundation's ignored
directories. No font binaries, screenshot copies, original ZIPs or MP4s are part
of this template.

## Editable inputs

Edit `config.ts`, or copy the generated `resolved-props.json` and pass the full
object to `--props /absolute/path/to/edited-props.json`. Partial props are not
merged. `index.ts` publishes control descriptions to the comparison gallery.

- `copy`: all shared titles, benefit, captions, pricing, CTA and URL.
- `durations`: all seven scene lengths, in seconds; metadata derives their sum.
  Both source clips retain 1× speed and fail if the duration overruns the source.
- `media`: original filenames, source starts, contain/cover, anchors, optional
  crop rectangles in **original source pixels**. Keep native reports contained.
- `brand`: colors, font families, heading/body size, line height and tracking.
  The local brand font gate must succeed before frames render.
- `layout`: outer margin, gaps and display mat padding. `gallery` controls the
  display rectangle, side-label width/type sizes, floor seam and quiet lighting.
- `exhibition`: three exhibit labels/numbers, source-medium descriptions,
  per-exhibit front-facing camera offsets, source detail labels and the montage
  disclosure. Newlines in short side labels are supported.
- `motion`: still approach frames/initial scale, lateral travel, iPhone departure
  frames, wall travel, title settle duration and the two-iPhone-still split.
  Arrival clamps to 20% of a scene; the remainder is a stable reading hold.
  Footage, important captions and labels never orbit or tilt during interaction.

For an editability check, change `durations.opening` from 4 to 2, change
`copy.opening` to `Devin on Mac.`, then render using `--props`. That edit should
produce **1140 frames / 38 seconds**, with the new title. Restore the default
render afterward if using the same output directory, because metadata and props
are written there on every render.

The included script generates exactly that complete diagnostic config:

```sh
npx tsx src/templates/06-contemporary-museum-gallery/edit-props.ts
npm run render -- --template 06-contemporary-museum-gallery \
  --props out/06-contemporary-museum-gallery/edited-props.json \
  --output out/06-contemporary-museum-gallery/edited-38s.mp4
npm run still -- --template 06-contemporary-museum-gallery \
  --props out/06-contemporary-museum-gallery/edited-props.json \
  --frame 30 --output out/06-contemporary-museum-gallery/edited-title.png
```

## Source fidelity / intentional adaptation

`attribution.json` maps the default timeline to original source files.
See the project's `MEDIA-ATTRIBUTION.md` and ignored
`public/assets/brand-reference.md` for verified provenance.

The supplied iPhone/iPad sources are screenshots; neither recording is native
Simulator footage. This edit uses still approaches followed by deliberate cuts
to the genuine agent-selection and web-review recordings. It does **not** invent
a matching native screenshot-to-recording transition. The source-medium labels
and persistent “Web QA example” label make that distinction visible. All examples
are presented as separate sessions, never as one causal app-building workflow.

Longer replacement copy can wrap; keep captions within the reserved header and
side labels concise. Camera offsets and new crops need fresh frame inspection.
Only the regular NB International font is visible in this direction.
