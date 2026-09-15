# 03 · Architectural Section Drawing

An orthographic launch drawing: original screenshot planes separate on the cover,
section datums align them, and the active view expands into a quiet demonstration.
Short leaders use original source coordinates. Drawing grids and leaders disappear
for reading holds. The five linked stage labels are **editorial order**, not a
diagram of infrastructure or an asserted causal workflow across unrelated apps.
Recordings remain fixed, unobscured and at 1× from their first frame.

## Run

From `product-launch-videos/`, use the shared installed dependencies and ignored
source bundle:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run templates:list
npm run lint
npm run typecheck
npm test
npm run build
npm run render -- --template 03-architectural-section-drawing
npm run still -- --template 03-architectural-section-drawing --frame 450
npm run still -- --template 03-architectural-section-drawing --frames 0,60,130,180,300,450,600,720,960,1140
npm run contact-sheet -- out/03-architectural-section-drawing
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/03-architectural-section-drawing/03-architectural-section-drawing.mp4
```

Independent entry: `src/templates/03-architectural-section-drawing/entry.tsx`.
Composition ID: `ArchitecturalSectionDrawing`. No registry changes are needed.
The expected default is 1920 × 1080, 30 fps, 1200 frames / 40 seconds, silent.
All generated output and original binaries remain ignored.

## Editing

`config.ts` is the primary typed input. `index.ts` describes discoverable controls.
Alternatively copy the generated `out/03-architectural-section-drawing/resolved-props.json`
and pass a **complete** `{"config": ...}` to `--props`. Props are not deep-merged.

| Input | Meaning |
| --- | --- |
| `copy` | Opening, benefit, all captions, pricing, CTA, URL |
| `durations` | Seven scene lengths in seconds; metadata follows their sum at 30 fps |
| `media` | Source files, fit, anchorX/Y, optional source-pixel crop, video offsets |
| `brand` | Colors, font families, heading/body size, line heights, tracking, title gap |
| `layout` | Margins, gutters, mat padding, caption height and numeric grid positions |
| `stages` | Stage IDs and editable labels for the five-part explanatory drawing |
| `connections` | Links between IDs, used only on the separate editorial stage strip |
| `annotations` | Caption label, original source-pixel x/y, top/bottom edge, enabled flag per still |
| `drawing` | Sheet title, montage/still/recording labels, index size, grid and hairlines |
| `motion.sectionRevealFrames` | Plane and line entrance duration; clamped to one quarter scene length |
| `motion.planeSeparation` | Cover plane gap in pixels |
| `motion.planeTravel` | Cover and still entrance travel in pixels; no video translation |
| `motion.introResolveFraction` | Cover duration fraction at which planes assemble |
| `motion.annotationHoldFrames` / `annotationFadeFrames` | Short leader lifetime |
| `motion.iphoneSplit` | Portion of iPhone scene using the first supplied still |

The default environment crop is source `x=550, y=450, width=1900, height=950`;
it retains the composer and complete menu. Every report uses the full source.
If replacing an asset or changing crop, update the source-coordinate annotation.
Invalid/outside anchors are omitted. Keep the report counts and all meaningful
interaction visible. Videos cannot exceed their genuine source duration.
Use longer `captionHeight` / lower `grid.mediaTop` for multiline copy, and inspect
the rendered result after major typography or geometry changes.

## Non-default edit verification

This creates a complete 20-second config with changed opening, caption and CTA,
different motion, iPhone split, and nonzero source trims:

```sh
npx tsx src/templates/03-architectural-section-drawing/verify-editability.ts
npm run render -- --template 03-architectural-section-drawing \
  --props out/03-architectural-section-drawing/edited/props.json \
  --output out/03-architectural-section-drawing/edited/edited.mp4
npm run still -- --template 03-architectural-section-drawing \
  --props out/03-architectural-section-drawing/edited/props.json --frame 90 \
  --output out/03-architectural-section-drawing/edited/caption.png
```

The edit should render 600 frames at the same resolution and frame rate.
Rerun a default still afterward to restore the shared CLI's default metadata files.

## Provenance and factual limits

`attribution.json` maps every use, default output time, source trim and font.
`../../../MEDIA-ATTRIBUTION.md` and the original ignored brand reference cover
the source bundle. Regular NB International is the primary font; Geist Mono is
used sparingly for indices. The original transparent black logo is never redrawn.

The default seven-part edit follows 0–4 / 4–9 / 9–13 / 13–22 / 22–29 / 29–35 /
35–40 seconds. iPhone changes stills at 17.5 seconds. Afterhours Maze retains
**8 passed, 0 failed, 1 untested**. Native app examples are static screenshots
from separate sessions. The review recording is explicitly **Web QA example**.
The closing assembled sheet is a recap, not a fabricated passing result.

No public deployment, UI testing, new dependency, source-media redistribution,
or individual producer PR is part of this template.
