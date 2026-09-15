# 14 — Cause-and-Effect Diptych

A 16:9 Remotion template that tells a launch story as a two-panel composition:
the user's action (or Devin's action) on the left, the observed consequence on
the right. The divider gives the active side more room, then settles to a
balanced ratio once both views are worth comparing. The final result grows out
of its panel to fill the frame before a dark CTA outro.

```sh
npm install
npm run dev        # Remotion Studio
npm run typecheck
npm run lint
npm run render     # out/launch.mp4  (1920x1080, 30fps, 45s by default)
npm run still      # out/poster.png  (frame 720)
```

Assets are served from `../../assets` via `Config.setPublicDir` and referenced
with `staticFile()`. Nothing is copied into this directory.

## Scene table (default props — Devin on Mac)

| # | id | kind | frames | left (action) | right (result) | caption |
|---|---|---|---|---|---|---|
| 1 | `title` | title | 120 (4.0s) | headline + subhead | empty, divider only | — |
| 2 | `pick` | pair | 210 (7.0s) | `devin-web-4.png` — macOS picker (cropped) | `devin-web-1.png` — session set to macOS | captions[0] |
| 3 | `build` | pair | 240 (8.0s) | `devin-working-4.mp4` — Devin working, live Desktop | `devin-web-9.png` — iOS session, PR ready to merge | captions[1] |
| 4 | `taps` | pair | 270 (9.0s) | `androidios.mp4` — iPhone Simulator crop | `androidios.mp4` — checklist crop of the same recording, in sync | captions[2] |
| 5 | `verify` | pair | 240 (8.0s) | `devin-testing-2.mp4` — test run, 6 passed | `devin-web-12.png` — PR with demo videos | captions[6] |
| 6 | `result` | result | 180 (6.0s) | — | `devin-web-12.png` grows from its panel to the full frame | — |
| 7 | `outro` | outro | 90 (3.0s) | outro line, CTA label + URL on `black` | | — |

Total: 1350 frames = 45s. Duration is derived from `scenes[]` via
`calculateMetadata`, so adding/removing/re-timing scenes changes the length.

### Pair-scene timeline

Within each `pair` scene:

1. Frame 0: divider animates from the previous scene's ratio to `split.active`
   (action side gets more room). Action panel enters.
2. `sync.revealAt`: result panel enters. The label of each panel appears with it.
3. `sync.balanceAt`: divider moves to `split.balanced` so both views can be
   compared. Result holds for the rest of the scene (≥ 2.5s in the defaults).
4. Last frames: both panels fade; the divider position hands off to the next
   scene so the line never jumps.

The `result` scene picks up the media from the right panel at the previous
ratio, then at `expandAt` grows it to the full 1920x1080 frame (cropping, never
stretching) while the chrome fades.

## Editable props (`src/schema.ts`)

| Prop | What it controls |
|---|---|
| `brand.*` | Colors (brand tokens), `fontFamily`, `monoFontFamily`, logo paths |
| `content.headline`, `headlineAccent`, `subhead`, `eyebrow` | Title scene. `headlineAccent` is the substring set in accent blue (`""` for none). |
| `content.captions[]` | Caption pool; pair scenes reference by `captionIndex` |
| `content.cta`, `content.outroLine` | Outro |
| `media.<key>` | `src` (relative to assets), `kind`, `srcWidth`/`srcHeight`, `startFrom`, `crop` (fractions of the source), `playbackRate` |
| `scenes[].durationInFrames` | Per-scene length |
| `scenes[] (pair).actionMedia / resultMedia` | Media pairing per scene |
| `scenes[] (pair).actionLabel / resultLabel` | Short, literal panel labels |
| `scenes[] (pair).split.active / balanced` | Panel ratio (fraction of width for the action side) |
| `scenes[] (pair).sync.revealAt / balanceAt` | Synchronization points (frames within the scene) |
| `scenes[] (result).media / label / expandAt` | Which result fills the frame and when |
| `layout.margin / gutter / panelRadius / moveDuration / enterDuration` | Safe margin, panel gap, corner radius, motion timings |

Crops only select a window of the source (`overflow: hidden`, uniform scale).
Media is never stretched, skewed, or recolored.

## Swapping launches

1. Copy `src/defaults.ts` (or pass a JSON props file to
   `remotion render Launch out/launch.mp4 --props=./my-launch.json`).
2. Replace `content` with the new launch copy (headline, subhead, captions, CTA).
3. Point `media.*` at the new screenshots/recordings under `launch-videos/assets/`
   and set their `srcWidth`/`srcHeight` (needed for crop aspect). Use recordings
   for actions/interactions and screenshots for stable outcomes.
4. Rebuild `scenes[]`: one `pair` per cause→effect beat, then a `result` scene for
   the artifact that should fill the frame, then `outro`. Keep the `result`
   media the same as the last pair's `resultMedia` for a seamless hand-off.
5. `npm run typecheck && npm run render`.

## Decisions / notes

- **Honest pairings.** Labels describe exactly what each panel shows. The `taps`
  scene pairs two crops of the *same* recording (`androidios.mp4`) so the
  checklist on the right is literally the consequence of the run on the left,
  in sync. The `build` and `verify` scenes follow the footage map in
  `launch-mac-vm.md`; their two panels come from different sessions, so labels
  name each panel's content rather than asserting they are one run.
- **No speed badge.** No footage is sped up in the defaults, so `speedBadge` is
  not rendered. Set `playbackRate` > 1 on a media slot and it would apply.
- **Zod 3.** Remotion prints a hint preferring zod 4.5.4; zod 4 changes
  `z.record` and inference and breaks `@remotion/zod-types` typing here, so the
  template stays on zod 3.22.x (the version Remotion's `@remotion/zod-types`
  peer range supports).
- **Fonts.** Inter (`@remotion/google-fonts/Inter`) stands in for NB
  International Pro; Geist Mono for mono. Both are plain string props in
  `brand.fontFamily` / `brand.monoFontFamily`.
- **No audio**, no connector lines between panels; the only relationship cue is
  the shared divider and synchronized reveal/balance timing.
