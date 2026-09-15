# 10 · Cinema Contact Sheet

A six-frame visual archive with genuine source pixels, numbered selections and
controlled expansion. The opening selects the environment still; each subsequent
selection opens one large product view. There are no film scratches, invented
timecodes, motion inside screenshots, or fake product states.

The two recordings play at 1× for their complete selected durations. Index
returns follow the end of each video, freezing its last selected frame. Index
transitions preceding a video live in the outgoing still's interval. This keeps
all source actions at stable reading size. The final selected frame is the real
Terra Table iPad artifact, with pricing and CTA outside it.

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
npx tsx --test src/templates/10-cinema-contact-sheet/timing.test.ts
npm run build
npm run render -- --template 10-cinema-contact-sheet
npm run still -- --template 10-cinema-contact-sheet --frame 0
npm run still -- --template 10-cinema-contact-sheet \
  --frames 0,100,150,249,330,405,450,509,570,641,750,887,930,1067,1140
npm run contact-sheet -- out/10-cinema-contact-sheet
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/10-cinema-contact-sheet/10-cinema-contact-sheet.mp4
```

Expected default: silent H.264 MP4, 1920 × 1080, 30 fps, 1200 frames / 40 seconds.
Rendered binaries and source assets belong in the foundation's ignored
directories. This producer changes no shared files and opens no individual PR.

## Editable inputs

Edit `config.ts`, or copy the generated `out/10-cinema-contact-sheet/resolved-props.json`
and pass the **complete** `{"config": ...}` object with `--props /path/to/props.json`.
Partial JSON is not deeply merged.

| Input | Purpose |
| --- | --- |
| `copy` | Feature name, opening, benefit, six chapter captions, pricing, CTA and URL |
| `durations` | Seven scene lengths in seconds; metadata derives the true total |
| `media` | Source selections, video source offsets, fit/crop/anchor positions |
| `brand.colors` | Neutral canvas, ink, media mat and type colors |
| `brand.typography` | Family, heading/body size, line-height and tracking |
| `layout` | Scene margin, column gutter, frame padding, caption reservation |
| `layout.grid` | Index top, tile height, row gap, product top and closing artifact geometry |
| `archive.labels`, `archive.kinds` | Six editable frame names and source-kind metadata |
| `archive.title`, `archive.context` | Index heading and separate-session context |
| `archive.agentIndexFrame`, `archive.webQaIndexFrame` | Frozen index sample, relative to the chosen source offset |
| `archive.agentFreezeFrame`, `archive.webQaFreezeFrame` | End freeze; `-1` follows the selected clip's last frame |
| `motion.returnFrames` | Contraction back into the archive |
| `motion.indexHoldFrames` | Quiet selection hold between contractions/expansions |
| `motion.expandFrames` | Expansion into the next large product plate |
| `motion.openingExpandFrames` | Initial environment selection reveal |
| `motion.iphoneSplit` | Fraction of the iPhone scene assigned to the first still |
| `motion.selectionStroke` | Selected archive frame keyline |

Transitions cap themselves to 30% of the supporting still scene. Changing motion
controls never increases video speed or trims live video actions. Explicit
freeze/index values outside a selected clip fail. Video durations must still fit
the supplied recordings; the shared `SourceVideo` rejects overruns.

The six-frame ordering is intentionally fixed to the comparable production edit:
environment → agent → Afterhours Maze → Large Dispatch → web QA → Terra Table.
Media can be replaced through config within the shared typed asset inventory.

## Alternate edit verification

For a 27-second diagnostic, copy full resolved props and change:

```json
{
  "durations": {
    "opening": 3, "environment": 4, "agent": 3, "iphone": 6,
    "webQa": 4, "ipad": 4, "closing": 3
  },
  "motion": {"iphoneSplit": 0.6},
  "copy": {"environment": "Choose a hosted Mac environment. Your next session starts here."}
}
```

The fragment above illustrates edits, **not** a standalone props file. Preserve
all other configuration fields. Optionally change `media.agent.sourceStartSeconds`
to `1` to verify independent source offsets. Render with `--props` and a separate
`--output`; select frame `120` to inspect the edited caption, and frame `780` to
inspect the ending. Expected metadata: 810 frames / 27 seconds.

A complete reproducible diagnostic is included:

```sh
npx tsx src/templates/10-cinema-contact-sheet/write-alternate-props.ts
npm run render -- --entry src/templates/10-cinema-contact-sheet/entry.tsx \
  --composition CinemaContactSheet \
  --props out/10-cinema-contact-sheet/alternate/props.json \
  --output out/10-cinema-contact-sheet/alternate/alternate.mp4
npm run still -- --entry src/templates/10-cinema-contact-sheet/entry.tsx \
  --composition CinemaContactSheet \
  --props out/10-cinema-contact-sheet/alternate/props.json \
  --frame 120 --output out/10-cinema-contact-sheet/alternate/caption.png
```

The diagnostic uses an independent CLI entry cache and metadata directory
(`out/cinema-contact-sheet`) so it does not overwrite default output metadata.

## Attribution and limitations

`attribution.json` maps each source and its actual treatment. The inherited
asset manifest records original hashes; the shared media attribution documents
provenance. Typography uses the supplied NB International Regular and the Geist
Mono website companion font, with the shared font-loading gate.

The environment's source-pixel crop removes empty surrounding canvas only:
`x=540, y=410, width=1900, height=1080`. All report screenshots are contained in
full, including the Afterhours Maze **1 untested** count. Neither MP4 is iOS
Simulator footage. Both index thumbnails and the large web QA recording retain
the **Web QA example** label. These are independent session examples.

The contact-sheet thumbnails provide orientation, not detailed reading. Critical
reports are shown as large, still, complete source images. End-card report size
is smaller than its preceding dedicated reading hold. No soundtrack, public
deployment, or browser UI testing is included.

## Validation record

- Default full MP4: H.264, 1920 × 1080, 30/1 fps, 1200 decoded frames,
  40.000 seconds, one video stream and no audio stream.
- Alternate full MP4: H.264, 1920 × 1080, 30/1 fps, 810 decoded frames,
  27.000 seconds, one video stream and no audio stream.
- The alternate changes scene durations, the environment caption, the iPhone
  split, and the agent source offset. Encoded frames at 120, 240, 540 and 780
  were inspected.
- Fifteen full-size default frames were extracted from the completed MP4 at
  `0,100,150,249,330,405,450,509,570,641,750,887,930,1067,1140`.
  The delivered contact sheet uses those frames; the poster is encoded frame 0.
  Inspection covered the opening, expansion, every archive return, product
  reading views, authentic report counts, persistent web QA label and CTA.
- Asset verification, template discovery, ESLint, TypeScript, the shared test
  suite, three direction-specific timing tests and the Vite production build
  passed.
