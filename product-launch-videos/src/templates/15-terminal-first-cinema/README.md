# 15 — Terminal-First Cinema

An editorial command-line rhythm, using the verified dark brand surface and
original white lockup. NB International Regular carries the launch statements;
Geist Mono is restricted to chapter numbers and source context.

A completed opening line yields to a horizontal caret baseline that opens into
the actual hosted Mac menu. Full-size, stable product views dominate the next
31 seconds. Incoming video captions complete over the preceding still, so both
recordings begin fully visible at source frame zero with settled typography.
Chapter indices advance only on editorial cuts; they are not execution telemetry.
The final Terra Table result remains visible briefly, then returns to a baseline
and the minimal feature name, pricing and CTA. There are no synthetic commands,
logs, app transitions, generated dashboards, simulated tests, or audio.

## Integration

- Independent Remotion entry: `entry.tsx`; composition ID `TerminalFirstCinema`.
- Named `template` export in `index.ts` follows shared contract version 1.
- `config.ts` is the complete JSON-serializable input. No shared files or registry
  edits are needed. The collector owns the combined PR.
- Original source media and fonts come from the authenticated shared ZIP.
  They remain in ignored `public/assets/`. See `attribution.json` for the
  exact default edit/source map and `../../../MEDIA-ATTRIBUTION.md` for provenance.

## Setup and render

From `product-launch-videos/`, using Node >=22.12, npm and FFmpeg:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run templates:list
npm run lint
npm run typecheck
npx tsx --test src/templates/15-terminal-first-cinema/motion.test.ts
npm test
npm run build
npm run render -- --template 15-terminal-first-cinema
npm run still -- --template 15-terminal-first-cinema --frame 450
npm run still -- --template 15-terminal-first-cinema \
  --frames 60,110,150,270,330,450,600,660,750,960,1062,1140
npm run contact-sheet -- out/15-terminal-first-cinema
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_frames:format=duration \
  -of json out/15-terminal-first-cinema/15-terminal-first-cinema.mp4
```

Default output: silent H.264 4:2:0 MP4, 1920 × 1080, 30 fps, 1200 frames,
40 seconds. Poster and contact sheet are genuine composition renders.
Nothing is publicly deployed.

## Editing

Edit `config.ts`, or copy the generated `resolved-props.json`, edit its complete
`config` object and pass `--props /path/to/props.json` to `render` or `still`.
Inputs are not deeply merged.

| Input | Behavior |
| --- | --- |
| `copy` | All launch lines, benefit, captions, feature name, pricing, CTA and URL |
| `durations` | Seven scene durations in seconds; actual Remotion metadata is derived from their sum |
| `media` | Shared asset selections, source offsets, contain/cover, anchors and original-pixel crops |
| `brand` | Colors, loaded font families, sizes, tracking, line heights and title spacing |
| `layout` | Margins, gutter, padding, caption area; `grid` controls index gutter, footer, opening Y and proportional logo box |
| `editorial` | Series, section names, source-context labels and closing kicker |
| `motion.typingFrames` | Editorial line entry; zero disables typing |
| `motion.lineDelayFrames` | Opening pause before the benefit |
| `motion.baselineRevealFrames` | Opening reveal and closing collapse; capped at 25% of scene length |
| `motion.baselineThickness` | Caret baseline thickness in pixels |
| `motion.caretWidth` | Cursor width; logo aspect ratio remains independent |
| `motion.caretBlinkFrames` | Optional blink half-period; zero disables blinking |
| `motion.blinkDuringHolds` | Default false, keeping typography and caret stationary over demonstrations |
| `motion.lineTravel` | Opening statement vertical departure, in pixels |
| `motion.iphoneSplit` | Fraction of iPhone scene given to first still, default 0.5 |
| `motion.closingResultFrames` | Additional final-artifact hold before the CTA transition |

Use the supplied loaded families `nbInternationalPro`, `nbInternationalPro Light`
or `Geist Mono`; arbitrary family names require a corresponding blocking loader.
Keep captions on one line within the reserved header (reduce the body size or
shorten the line if needed). For light backgrounds, switch both text tokens and
the original logo selection appropriately. Some shared brand/layout fields are
generic contract inputs; only fields referenced by this composition affect it.

The default environment crop is `(560,430,1880,960)` in the original 2988 × 1622
source and retains the complete composer and menu. All report screenshots use
uncropped contain. Source images retain aspect ratio. Native examples are stills
from different sessions. The 8 passed / 0 failed / 1 untested report is intact.
The web testing recording retains its persistent **Web QA example** footer.
Both videos play at 1×. Increasing video duration beyond remaining source time
fails rather than looping, freezing or speeding up.

## Editable-config verification

Generate a separate 11-second diagnostic edit with changed environment caption,
CTA, margins, iPhone split and motion timing:

```sh
npx tsx src/templates/15-terminal-first-cinema/make-variant.ts
npm run render -- --template 15-terminal-first-cinema \
  --props out/15-terminal-first-cinema/variant/props.json \
  --output out/15-terminal-first-cinema/variant/variant.mp4
npm run still -- --template 15-terminal-first-cinema \
  --props out/15-terminal-first-cinema/variant/props.json --frame 75 \
  --output out/15-terminal-first-cinema/variant/caption.png
```

Expected: 330 frames, 11 seconds, with “Choose your hosted Mac.” visible at frame 75.
The shared renderer always writes metadata/resolved props in the primary template
output folder even with a custom `--output`; run a default still afterward to
restore the default metadata. Keep the short diagnostic separate from the final
40-second sample. The default sample is the comparison deliverable.

## Validation

Verified with the supplied assets:

- `assets:check`: 45 original assets passed integrity checks.
- `lint`, `typecheck`, and `build`: passed.
- Tests: 3 direction-specific tests, 8 shared TypeScript tests and 3 asset-setup
  Python tests passed.
- Full default MP4: ffprobe reports H.264, 1920 × 1080, 30/1 fps, 1200 frames,
  exactly 40 seconds and no audio stream. The shared renderer requests
  `yuv420p`; ffprobe identifies its full-range output as `yuvj420p`.
- Custom edit: full render and ffprobe confirm 330 frames / 11 seconds at
  1920 × 1080 / 30 fps. Frame 75 visibly contains “Choose your hosted Mac.”
  with the changed margins.
- FFmpeg decoded both complete videos without errors.
- Twelve full-resolution frames were inspected across the title, baseline
  transition, all product sources and closing. Fonts load correctly, logos
  retain aspect ratio, captions stay outside the UI, and the complete
  8 passed / 0 failed / 1 untested report remains visible.
- Poster: actual frame 450, 1920 × 1080. Contact sheet: twelve genuine rendered
  frames at 1960 × 842.

Native examples are supplied stills, not Simulator recordings. The Web QA
recording stays explicitly labeled. Long replacement text needs an appropriate
font size to fit the header; video extensions must fit the remaining source.
Rendering validation did not use browser UI testing or publish a deployment.
