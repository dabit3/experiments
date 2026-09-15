# 16 · Modernist Motion Mechanics

A two-part black rectangle assembles into an aperture. Five numbered tiles
introduce five editorial examples, then reduce to quiet footer indices. A single
vertical line advances only at scene changes. Opposing matte planes reveal
intact stills; recordings are visible in full from their first frame. The final
genuine iPad result resolves from the product frame into an asymmetric CTA.
There are no gradients, springs, fragmented interface pixels or perpetual motion.

## Source and rendering

From `product-launch-videos/`, with Node 22.12+, npm, Python 3.9+ and FFmpeg:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run templates:list
npm run lint
npm run typecheck
npm test
npm run build
npm run render -- --template 16-modernist-motion-mechanics
npm run still -- --template 16-modernist-motion-mechanics --frame 450
npm run still -- --template 16-modernist-motion-mechanics \
  --frames 0,18,75,126,180,330,450,540,750,960,1056,1140
npm run contact-sheet -- out/16-modernist-motion-mechanics
```

Entry: `entry.tsx`; composition: `ModernistMotionMechanics`. Default metadata is
1920 × 1080, 30 fps, 1200 frames / 40 seconds. Artifacts go to the ignored
`out/16-modernist-motion-mechanics/` directory. Nothing is deployed.

The supplied archive must be installed locally; original media/font binaries
and generated deliverables are deliberately excluded from git. See the shared
`MEDIA-ATTRIBUTION.md` for provenance and `attribution.json` for exact use/crops.
The complete original direction is §16 of the installed
`public/assets/pasted-1789430547875.txt`.

## Editing

`config.ts` is a complete typed, serializable `ModernistConfig`. Edit it, or copy
the generated `resolved-props.json`, change its full `config` object, and render
with `--props /absolute/path/to/custom-props.json`. Partial props do not merge.
The descriptor exposes controls for the gallery/collection tooling.

| Input | Meaning |
| --- | --- |
| `copy` | Feature name, all seven captions, benefit, pricing, CTA, URL. |
| `durations` | Seven scene lengths in seconds, rounded independently to 30 fps. Metadata and every sequence derive from these values. |
| `media` | Original filenames, `contain`/`cover`, normalized crop anchors, optional original-pixel crop rectangles and video source offsets. |
| `brand` | Neutral colors, original font family, size, tracking, line height, spacing. |
| `layout` | Margin, rail gutter, matte padding, header reservation, rail/footer geometry. |
| `composition` | Title/caption/index sizing, logo size, opening motif geometry and closing text/result positions. Coordinates use the 1920 × 1080 canvas. |
| `geometry.rectangleRole` | `frame` outlines the product; `plane` keeps a flat mat. |
| `geometry.lineRole` | `progression` changes line length once per editorial segment; `rule` stays full-length. Never represents execution telemetry. |
| `geometry.showTiles` | Show/hide the five example tiles. |
| `geometry.frameThickness`, `lineThickness`, `tileSize` | Shape weights and tile dimensions. |
| `labels` | Five example names, separate-session notice and genuine-still labels. |
| `motion.revealFrames` | Symmetric aperture reveal length for stills; short scenes cap it at one quarter of their duration. Videos are never covered by it. |
| `motion.revealAxis` | `x` or `y`, applied to matte planes only. |
| `motion.transitionDistance` | Opening rectangle and closing tile travel in pixels. |
| `motion.openingAssembleFrames` | Opening plane alignment time, capped at one third of opening length. |
| `motion.tileTravel` | Intro and scene-index tile travel in pixels. |
| `motion.closingResolveFrames` | Intact result placement time, capped at one third of closing length. |
| `motion.iphoneSplit` | Fraction of the iPhone scene for the first still, default 0.5. |

Keep a readable hold after transitions. Source video plays at 1×; extending
`agent` beyond its remaining 9.17-second source (or `webQa` beyond its remaining
59.13 seconds) fails rather than fabricating a loop/frozen action. Keep report
sources in `contain` with no crop. The default environment crop retains the
entire composer and actual macOS menu, removing only excess blank canvas.

### Non-default editability check

`validate-config.ts` writes a complete custom config into ignored output,
changing the opening duration/caption, iPhone split and mechanical controls.

```sh
npx tsx src/templates/16-modernist-motion-mechanics/validate-config.ts
npm run render -- --template 16-modernist-motion-mechanics \
  --props out/16-modernist-motion-mechanics/variant-props.json \
  --output out/16-modernist-motion-mechanics/variant.mp4
```

The diagnostic configuration is 12 seconds / 360 frames, includes all seven
scenes and both video sources, and retains the original sources' 1× speed. It is
an editability diagnostic, not a replacement for the full launch sample.

## Fidelity

The opening benefit refers to Simulator workflows. Agent selection footage is
not macOS selection. Web QA footage retains its persistent label. Native
examples are genuine stills from separate sessions, explicitly labeled. The
Afterhours Maze report remains 8 passed, 0 failed, 1 untested. The still in the
closing CTA is contextual and smaller; its full readable report is presented
in the preceding iPad scene. Supplied artwork keeps its aspect ratio. Original
fonts load through the shared blocking font gate; no network fonts or fallback.

## Validation results

Validated on 2026-09-15:

- Full H.264 sample rendered at 1920 × 1080, 30 fps, exactly 1200 frames /
  40.000 seconds. The film is intentionally silent.
- Non-default captions, all seven durations, reveal axis, iPhone split, line role
  and transition distance rendered at 1920 × 1080, 30 fps, 360 frames /
  12.000 seconds. The duration assertions passed.
- Both MP4s passed an FFmpeg decode check; `ffprobe` verified their metadata.
- Inspected encoded frames 0, 18, 75, 126, 180, 330, 450, 540, 750, 960,
  1056 and 1140 for framing, caption placement and source fidelity. Opening
  geometry stays clear of the headline; closing tiles wait until the report
  has resolved. Stable report views preserve the supplied counts, including
  the iPhone report's untested count. Web QA retains its label.
- The contact sheet uses frames extracted from the final MP4. The poster is
  the full 1920 × 1080 iPhone composition at frame 450.
- ESLint, TypeScript, 8 TypeScript tests, 3 Python tests, template discovery,
  asset verification (45 originals) and the Vite production build passed.
  Vite emitted a non-fatal warning about ignoring Remotion Player's
  `"use client"` directive.

Native examples remain stills, not Simulator recordings. The closing report
is intentionally smaller than its preceding demonstration. Very long custom
copy or arbitrary layout changes need a new frame inspection before delivery.
