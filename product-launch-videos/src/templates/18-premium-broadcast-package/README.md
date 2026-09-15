# 18 — Premium Broadcast Package

A broadcast ident built from one repeatable visual grammar: a split opening
panel, a large stable product bay, a small chapter marker, and a numbered lower
third. The opening and closing mirror the same aligned rule and arrow tile.
The five demonstration segments have no ticker, fabricated telemetry, or
controls covered by captions.

## Render

From `product-launch-videos/`, after the shared README setup:

```sh
npm ci
npm run assets:setup -- /absolute/path/to/shared-assets.zip
npm run assets:check
npm run templates:list
npm run lint
npm run typecheck
npm test
npm run render -- --template 18-premium-broadcast-package
npm run still -- --template 18-premium-broadcast-package --frame 60
npm run still -- --template 18-premium-broadcast-package --frames 0,10,60,126,180,330,396,450,540,600,750,960,1080,1140
npm run contact-sheet -- out/18-premium-broadcast-package
npm run build
```

Default output: silent H.264 MP4, 1920 × 1080, 30 fps, 1200 frames / 40 seconds.
Outputs and original media/font binaries remain in ignored directories.
Do not publish the source bundle or redistribute the fonts.

## Edit

`config.ts` is the typed, JSON-serializable authoring surface. The root Remotion
composition derives its duration from all seven `durations` values, including
changed values supplied via a complete `{"config": ...}` JSON file:

```sh
# Start from the full resolved props produced by a first render.
node --input-type=module -e '
import fs from "node:fs";
const p = JSON.parse(fs.readFileSync("out/18-premium-broadcast-package/resolved-props.json", "utf8"));
p.config.durations.opening = 2;
p.config.durations.environment = 3;
p.config.copy.environment = "Choose your hosted Mac environment.";
fs.writeFileSync("out/18-premium-broadcast-package/alternate-props.json", JSON.stringify(p, null, 2));
'
npm run render -- --template 18-premium-broadcast-package \
  --props out/18-premium-broadcast-package/alternate-props.json \
  --output out/18-premium-broadcast-package/alternate.mp4
```

The example changes the total to 36 seconds. Props are **not** partially merged.
Render it to a separate output file; the shared renderer overwrites metadata and
resolved props on every call, so rerun default still selection last if collecting
the default metadata.

- `copy`: feature, opening, benefit, captions, pricing, CTA and URL.
- `media`: supplied assets, source start times, `contain`/`cover`, crop anchors
  and optional source-pixel crop windows. The environment uses
  `{x:580,y:460,width:1840,height:910}` to retain the composer and macOS menu.
  Reports and recordings use the complete source viewport.
- `brand`: editable presentation colors, family, font sizes, tracking and
  line height. Use locally supplied fonts; `defineTemplate` waits for them.
- `layout`: safe margin, gutter, title-panel padding, reserved caption height,
  and `grid.mediaTop` / `grid.headerHeight`.
- `broadcast`: chapter labels/numbers, source-context labels, logo selections
  and width, title product-panel fraction, marker size and caption size.
- `motion.wipeFrames`: short linear-edge wipes uncover composed stills only.
- `motion.stingFrames` / `panelTravel`: aligned numbered-tile entrance, outside UI.
- `motion.titleRevealFrames`: opening panel and closing arrow reveal duration.
- `motion.iphoneSplit`: fraction of the iPhone segment for the first still.

All motion is deterministic and frame-driven. Transition durations clamp to
a fraction of their scene so shorter holds settle correctly. Caption text stays
still from the first video frame; moving footage is never covered by a transition.
Recordings play once at 1×; shared media validation rejects source overruns.
Keep enough time for real actions when editing. Extreme typography/layout inputs
or unusually long copy need a new frame inspection.

## Components and evidence

`components.tsx` exports `Title`, `Demonstration`, `Evidence`, `ChapterMarker`,
`LowerThird`, `Transition`, and `Closing`. `Evidence` keeps the entire authentic
screenshot, including its existing report pane; an extra duplicate panel would
reduce legibility and is intentionally unnecessary in this sample.

Default edit: 0–4 title/environment preview; 4–9 environment; 9–13 agent clip;
13–17.5 Afterhours Maze still; 17.5–22 Large Dispatch still; 22–29 web QA clip;
29–35 Terra Table iPad still; 35–40 closing slate. These are separate examples,
not a continuous app-building session. Native examples are explicitly labeled
stills. The web recording always displays **Web QA example** outside the source.
The Afterhours report retains **8 passed, 0 failed, 1 untested**.

`attribution.json` maps each use to the supplied original and default output
times. The shared manifest provides source SHA-256 values. Provenance and
product limitations are in the shared `MEDIA-ATTRIBUTION.md`.

## Verified delivery

- Full sample rendered: H.264, 1920 × 1080, 30/1 fps, 1200 frames, 40.000 seconds,
  no audio stream. FFmpeg decoded the complete file without errors.
- Fourteen full-size frame renders and their genuine contact sheet were checked
  across the title, wipes, both clips, native reports and closing. An extracted
  encoded iPhone frame also preserves the 8/0/1 report counts.
- An independent 10-second diagnostic render used durations
  `1,2,1,2,1,1,2`, the caption “Choose your hosted Mac environment.”, iPhone
  split `0.35`, and an eight-frame wipe. FFprobe confirmed 300 frames at 30 fps,
  and a rendered frame confirmed the edited caption. This diagnostic does not
  replace the readable default sample.
- Asset verification, lint, typecheck, eight TypeScript tests, three Python
  tests, template discovery, and production build passed. Vite reports a
  non-fatal ignored `use client` directive in the shared Remotion Player package.
- No browser UI testing, public deployment, or individual producer PR.
