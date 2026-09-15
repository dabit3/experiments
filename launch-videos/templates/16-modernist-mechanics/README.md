# 16 · Modernist Motion Mechanics

A 16:9 Remotion launch-video template for Devin built from a small vocabulary of
purposeful shapes: one **product frame** (rectangle) that travels between
layouts, one **progression rule** (line + stage tiles) that advances along the
bottom, and one **caption plane** (flat ink rectangle) that carries the copy.
Shapes slide, divide and align on exact edges; the interface itself never moves
or fragments.

- 1920×1080 · 30 fps · 1350 frames (45 s) by default · no audio
- Media is read from the shared `launch-videos/assets/` directory via
  `Config.setPublicDir("../../assets")` and `staticFile()`; nothing is copied.
- Typography: NB International Pro with Inter (`@remotion/google-fonts/Inter`) as
  the deterministic fallback; Geist Mono for labels. Both families are props.

## Run

```sh
npm install
npm run dev        # Remotion Studio
npm run typecheck
npm run lint
npm run render     # out/launch.mp4
npm run still      # out/poster.png (frame 100)
```

If the headless browser download fails: `npx remotion browser ensure`.

## Shape roles

| Shape | Role | Behaviour |
| --- | --- | --- |
| Product frame (`shapes.frame`) | Establishes where the product lives | A solid ink plane in the opening; slides between layouts at every scene boundary. Media inside is anchored to its resting rectangle, so the frame *reveals* the UI rather than moving it. |
| Shutter (same `shapes.frame.fill`) | Divides one demo from the next | A flat plane that crosses the frame left→right during the boundary move, covering exactly at the midpoint. Skipped when consecutive scenes show the same media (result → outro). |
| Progression rule (`shapes.rule`) | Indicates where we are in the workflow | One hairline across the safe width; the accent segment advances to the active stage. |
| Stage tiles (`shapes.tiles`) | Introduce the supported stages of work | One square per `content.stages` entry; filled once reached. |
| Caption plane (`shapes.plane`) | Carries the explanatory copy | One flat ink rectangle per demo, aligned to the frame's top and bottom edges. |
| Extension lines | Resolve the structure around the result | From the result scene on, hairlines extend the frame's edges to the canvas and down to the rule. |

## Scenes (default props)

| # | id | Type | Frames | Time | Composition | Media | Copy |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `open` | open | 135 | 0.0–4.5 s | ink plane right, headline left | — | eyebrow, headline, subhead |
| 2 | `pick` | demo | 150 | 4.5–9.5 s | `media-right` | `pick` — `screenshots/devin-web-4.png` (cropped to the composer + OS picker) | caption 0 · stage 01 Request |
| 3 | `build` | demo | 180 | 9.5–15.5 s | `media-left` | `work` — `screenshots/devin-web-13.png` | caption 1 · stage 02 Build |
| 4 | `taps` | demo | 225 | 15.5–23.0 s | `media-right`, split 0.5 | `simulator` — `recordings/androidios.mp4` cropped to the iPhone Simulator | caption 2 · stage 03 Run & test |
| 5 | `verify` | demo | 210 | 23.0–30.0 s | `media-left` | `verify` — `recordings/devin-testing-2.mp4` | caption 4 · stage 04 Verify |
| 6 | `sizes` | demo | 150 | 30.0–35.0 s | `tiles`, split 0.78 | `ipad` (`devin-web-19.png`, iPad crop) + `darkPhone` (`devin-web-18.png`, dark-mode iPhone crop) | caption 5 · stage 04 Verify |
| 7 | `result` | result | 180 | 35.0–41.0 s | frame spans the safe width, caption below | `result` — `screenshots/devin-web-12.png` (chat input trimmed) | caption 6 · stage 05 PR · "Ready to merge" |
| 8 | `outro` | outro | 120 | 41.0–45.0 s | result frame left, copy + CTA right | `result` (continues) | feature name, outro line, CTA |

Every scene boundary is one `motion.transitionFrames` move (default 20 frames,
ease-in-out). Captions enter after the frame has settled and leave before the
next move, so copy is never read over a moving shape. The result holds for
6 s plus the 4 s outro.

## Editable props

All props are validated by `src/schema.ts` and editable in Remotion Studio.
Studio edits preview live; "save default props" is not available because the
defaults live in `src/defaults.ts` rather than inline in `Root.tsx` — edit that
file (or pass `--props`) to persist changes.

| Group | Fields |
| --- | --- |
| `brand` | `paper`, `surface`, `line`, `ink`, `inkMuted`, `inkSubtle`, `accent`, `white`, `fontFamily`, `monoFontFamily`, `logoLight`, `logoDark` |
| `content` | `featureName`, `eyebrow`, `headline`, `headlineAccent`, `subhead`, `captions[]`, `useCases[]`, `stages[]`, `cta.{label,url}`, `outroLine`, `speedBadge` |
| `media[]` | `name` (slot name scenes refer to), `src` (relative to `launch-videos/assets`), `kind` (`image`/`video`), `width`, `height` (intrinsic px), `startFrom`, `playbackRate`, `crop.{x,y,w,h}` (fractions; trim only) |
| `scenes[]` | discriminated on `type`: `open` · `demo` (`composition`, `media[]`, `caption`, `stage`, `label`, `split`, `showSpeedBadge`) · `result` (`media`, `caption`, `stage`, `label`) · `outro` (`media`); every scene has `durationInFrames` |
| `shapes` | `frame.{fill,border,borderWidth}` · `rule.{color,progressColor,thickness,y}` · `tiles.{size,fill,activeFill}` · `plane.{fill,text,textMuted,padding,captionSize}` |
| `motion` | `transitionFrames` (boundary move), `entranceFrames`, `slideDistance` (px a shape travels when entering), `stagger` |
| `layout` | `margin`, `gutter`, `radius`, `defaultSplit` (share of safe width given to the frame), `maxPlaneWidth` |

Compositions: `media-right` (plane left, frame right), `media-left`,
`media-wide` (frame spans the width, one caption line below), `tiles`
(two framed crops side by side, plane left).

The composition's duration is derived from the sum of `scenes[].durationInFrames`
via `calculateMetadata`, so changing scene lengths or adding/removing scenes
needs no other edits.

## Swapping launches

1. Replace `content` in `src/defaults.ts` (or pass props) with the new launch
   copy. Use the approved copy verbatim.
2. Point each `media[]` slot at footage in `launch-videos/assets/`, set its
   intrinsic `width`/`height`, and add a `crop` if only part of the frame is
   relevant. Crops scale uniformly and only trim — never skew or recolor.
3. Rebuild `scenes`: pick a `composition` per demo, reference slot names, and
   map `caption`/`stage` indices. Keep the result scene ≥ 75 frames.
4. `npm run typecheck && npm run lint && npm run render`.

## Decisions on ambiguities

- `recordings/androidios.mp4` shows an iPhone Simulator next to an Android
  emulator; only the iPhone is cropped in so the Android device is never
  implied as part of this launch.
- The `3x` speed badge is wired (`showSpeedBadge`) but off by default: the
  supplied recordings play at 1× in this template.
- `useCases` is kept in the content props for parity with the brief but is not
  rendered by this template; the five workflow stages are the rail's labels.
- Corner radius is 16 px on the product frame and caption plane (brand
  screenshot-frame token); every other shape is square-cornered.
