# 19 — Graphic Storyboard

A reusable 16:9 Remotion launch-video template that tells the product story as a
composed storyboard: numbered panels on a paper page, a fixed 12-column grid with
consistent 24px gutters, one **active** panel at inspectable size, earlier panels
kept as quiet **context** in the left column, and one concise caption per beat
set in the margin (never over the UI). Screenshots are the stable story beats,
recordings are the moments where work happens, and the last panel grows into a
full-frame view of the delivered outcome.

- Composition `Launch`, 1920x1080 @ 30fps, duration derived from `scenes` via
  `calculateMetadata` (default 1350 frames = 45s). No audio.
- Media comes only from `launch-videos/assets/` via `staticFile()`
  (`Config.setPublicDir("../../assets")`). Nothing is copied or redrawn.

```sh
npm install
npm run dev        # Remotion Studio
npm run typecheck && npm run lint
npm run render     # out/launch.mp4
npm run still      # out/poster.png (frame 1010, the Verify beat)
```

## Scene table (default "Devin on Mac" launch)

| # | id | start | frames | stage | active panel (media) | caption |
|---|----|-------|--------|-------|----------------------|---------|
| 0 | `title` | 0:00.0 | 105 | – | 01 `hero` — `devin-web-1.png` crop of the prompt box (`macOS` chip) | headline / subhead in the left half |
| 1 | `establish` | 0:03.5 | 120 | Request | 02 `pick` — `devin-web-4.png` crop of the Hosted OS menu | 1 |
| 2 | `pick` | 0:07.5 | 180 | Request | 03 `selector` — `agent-selector-cloud.mp4` (9 cols) | 1 |
| 3 | `build` | 0:13.5 | 195 | Build | 04 `work` — `devin-working-4.mp4` (9 cols) | 2 |
| 4 | `run` | 0:20.0 | 180 | Run & test | 05 `simulator` — `androidios.mp4` cropped to the iPhone, full content height; caption *beside* | 3 |
| 5 | `live` | 0:26.0 | 120 | Run & test | 06 `live` — `devin-web-14.png` (Simulator + test list) opens beside the phone | 4 |
| 6 | `verify` | 0:30.0 | 180 | Verify | 07 `verify` — `devin-testing-2.mp4` from frame 750 (9 cols) | 5 |
| 7 | `ship` | 0:36.0 | 105 | PR | 08 `result` — `devin-web-12.png` (PR "Ready to merge" + passing test recording) | 7 |
| 8 | `full` | 0:39.5 | 90 | PR | 08 `result` grows to the full frame; header/chrome fade out | – |
| 9 | `outro` | 0:42.5 | 75 | – | – | logo, outro line, CTA |

Caption 6 ("Check iPhone and iPad sizes…") is present in `content.captions` but
unused by the default sequence; point any scene's `captionIndex` at `5` to use it.

## How a panel behaves

Each `scenes[i].panels[]` entry places a `slot` (a key into `media`) in a `rect`
with a `role`:

- A slot that was **not** on the previous page mounts with a boundary reveal: a
  thin ink line travels left→right across the rect while the media is unmasked
  behind it (`storyboard.revealFrames`, optional per-panel `revealDelay`).
- A slot that **was** on the previous page moves/resizes from its old rect to
  the new one over `storyboard.moveFrames` (cubic ease-in-out), dimming to
  `contextOpacity` when it becomes context.
- A slot missing from the new page fades out over `storyboard.exitFrames`.
- Videos keep playing across pages (one `<OffthreadVideo>` per run) and freeze
  on their last frame if a run outlives `media[slot].durationInFrames`.
- When a rect reaches `x = 0` the panel drops its border, radius and number so it
  reads as a true full-frame shot.

Captions appear after the layout settles (`moveFrames`), fade over
`captionFadeFrames`, and sit either in the bottom margin aligned to the active
panel's left edge (`captionPlacement: "bottom"`) or in the margin to its right
(`"beside"`, used for the tall Simulator panel). A mono speed badge
(`content.speedBadge`) is shown automatically when the active media has
`playbackRate > 1`.

## Editable props (`src/defaults.ts`, all validated by `src/schema.ts`)

| group | fields |
|-------|--------|
| `brand` | `paper surface line ink inkMuted inkSubtle accent white`, `fontFamily`, `monoFontFamily`, `logoLight`, `logoDark` |
| `content` | `featureName eyebrow headline headlineAccent subhead captions[] useCases[] stages[] cta{label,url} outroLine speedBadge` |
| `media[slot]` | `src` (relative to `launch-videos/assets`), `kind` image/video, `aspect` (source w/h), `startFrom`, `durationInFrames`, `crop{x,y,w,h}` (fractions), `playbackRate` |
| `scenes[]` | `id durationInFrames kind panels[] captionIndex captionPlacement stage showHeader` |
| `scenes[].panels[]` | `slot rect{x,y,w,h} role revealDelay` |
| `storyboard` | `margin gutter panelRadius contextOpacity revealFrames moveFrames exitFrames captionFadeFrames showPanelNumbers` |

Grid helpers in `defaults.ts` (`colX`, `colW`, `fitH`, `rect`) build rects from
column counts so re-arrangements stay on the 12-column / 24px-gutter grid. Panel
numbers are assigned automatically in first-appearance order.

## Swapping in another launch

1. Replace the copy in `content` (headline, `headlineAccent`, captions, stages,
   CTA, outro line) — keep captions to one or two lines.
2. Add/replace `media` slots. Set `aspect` to the real source ratio and, for
   video, `durationInFrames` at 30fps (`ffprobe`). Use `crop` to isolate a region
   of a screenshot; crops scale but never skew or recolor the source.
3. Edit `scenes`: reorder/resize panels, choose which slot is `active`, set the
   caption and stage per scene, and adjust `durationInFrames`. Total duration
   follows automatically.
4. Adjust `storyboard` timings if the new footage needs faster/slower moves.
5. `npm run typecheck && npm run lint && npm run render`.

## Decisions worth knowing

- **Fonts.** `brand.fontFamily` lists NB International Pro first and falls back
  to Inter (loaded via `@remotion/google-fonts/Inter`); the mono family falls
  back to Geist Mono (`@remotion/google-fonts/GeistMono`). No font files are
  bundled or fetched from the assets folder.
- **Reading order.** Context panels always sit in the left 3 columns, newest at
  the bottom, so the page reads left→right like a storyboard sheet; the header
  stage tracker marks the current workflow step.
- **"Live Simulator" beat** uses `devin-web-14.png` (a session whose Simulator
  recording and test list are visible) rather than the `androidios.mp4` crop
  again, so the beat is a stable screenshot as the direction asks.
- **Full-frame outcome** uses `devin-web-12.png` (macOS session, PR "Ready to
  merge" with a passing on-screen test) and is cover-fitted to 1920x1080 (the
  source is 1.836:1, so ~1.5% is trimmed on each side).
- **Avoid-list.** No characters, textures, bursts, or mosaics: panels are flat
  rectangles with a 1px line, the only accent-colored elements are the active
  stage dot, the caption index, and the headline accent word.
