# 09 — Optical Laboratory

A 16:9 launch-video template built on the visual language of careful observation:
a stable field of view, one precisely outlined focus region, clean magnification,
and concise annotations in a dedicated margin.

The product UI is always shown whole and pixel-preserved on a fixed stage. For each
demonstrated action a single **inspection window** enlarges a real detail of the
footage (crop + uniform scale only), is connected to its original location by one
hairline, and is annotated in the left margin. The video ends by closing the window
and returning to the complete interface and its verified result.

Composition: `Launch`, 1920×1080, 30 fps, 1350 frames (45 s) by default. Duration is
derived from the sum of `scenes[].durationInFrames`.

## Commands

```sh
npm install
npm run dev        # Remotion Studio
npm run typecheck
npm run lint
npm run render     # out/launch.mp4
npm run still      # out/poster.png (frame 250)
```

Media is read from `../../assets` via `Config.setPublicDir` and referenced with
`staticFile()`. Nothing is copied into the template.

## Scene table (default Mac VM launch)

| # | id | kind | frames | time | media | inspected detail |
|---|---|---|---|---|---|---|
| 1 | `establish` | title | 105 | 0:00–0:03.5 | `screenshots/devin-web-1.png` | Full Devin interface, headline + subhead in margin |
| 2 | `pick` | inspect | 195 | 0:03.5–0:10 | `screenshots/devin-web-4.png` | Virtual environment picker (Ubuntu / macOS / Windows) |
| 3 | `build` | inspect | 180 | 0:10–0:16 | `recordings/devin-working-4.mp4` | Work log: build, test and screenshot steps |
| 4 | `taps` | inspect | 165 | 0:16–0:21.5 | `screenshots/devin-web-14.png` | Cursor tapping the app menu in the iPhone Simulator |
| 5 | `simulator` | inspect | 210 | 0:21.5–0:28.5 | `recordings/androidios.mp4` | Live iPhone 17 Simulator |
| 6 | `verify` | inspect | 195 | 0:28.5–0:35 | `recordings/devin-testing-2.mp4` | Test summary: 6 passed, 0 failed |
| 7 | `result` | inspect | 195 | 0:35–0:41.5 | `screenshots/devin-web-12.png` | PR "Ready to merge"; window closes at frame 120 and the full interface holds ≥ 2.5 s |
| 8 | `outro` | outro | 105 | 0:41.5–0:45 | — | Logo, outro line, CTA |

Each inspect scene opens its window at `openAt` (default frame 30) so the viewer
first sees the full interface, then the close observation.

## Editable props

All props are validated by the Zod schema in `src/schema.ts` and editable in
Remotion Studio or via `--props`.

- **`brand`** — colors (`paper`, `surface`, `surfaceAlt`, `line`, `ink`, `inkMuted`,
  `inkSubtle`, `accent`, `black`, `white`), `fontFamily`, `monoFontFamily`, and
  `logoLight` / `logoDark` public paths.
- **`content`** — `featureName`, `eyebrow`, `headline`, `accentWord`, `subhead`,
  `captions[]`, `useCases[]`, `stages[]`, `cta {label, url}`, `outroLine`,
  `speedBadge`. Copy comes verbatim from `launch-videos/brief/launch-mac-vm.md`.
- **`media`** — a record of named slots: `src` (path under `assets/`), `kind`
  (`image` | `video`), source `width`/`height`, optional `startFrom` (frames),
  `crop` (fraction rect) and `playbackRate`.
- **`scenes[]`** — `id`, `kind` (`title` | `inspect` | `outro`), `durationInFrames`,
  `media` (slot key), `captionIndex`, and `inspection`:
  - `focus {x, y, w, h}` — region of the media to enlarge, as fractions of the media.
  - `window {x, y, w}` — where the enlarged view sits on the stage (fractions of the
    stage). Height follows the focus aspect ratio; no distortion.
  - `label` — the annotation shown under the caption.
  - `openAt` / `closeAt` — frames within the scene.
- **`layout`** — `safeMargin`, `marginWidth`, `gap`, `stageRadius`, `windowRadius`,
  `windowBorder`, `showMagnification` (prints the real factor, e.g. `2.3x`, next to
  the label), `crossfadeFrames`.

### Magnification cap

The window width is capped at the number of source pixels across the focus region
(`focus.w × crop.w × media.width`), so one source pixel is never stretched beyond one
output pixel. If a window looks smaller than requested, the source resolution is the
limit — widen `focus` or pick a higher-resolution asset.

## Swapping launches

1. Replace `content` with the new launch's approved copy (headline, subhead,
   captions, CTA, outro line).
2. Point `media` slots at the new screenshots/recordings and set their real
   `width`/`height` (`ffprobe -show_entries stream=width,height file`).
3. For each inspect scene, set `focus` to the detail that demonstrates the caption
   (measure it as fractions of the source), choose a `window` position that does not
   cover the focus region, and write a `label` that names exactly what is shown.
4. Adjust `durationInFrames`; the composition length follows automatically. Keep the
   final full-interface hold ≥ 75 frames.
5. `npm run render` and check ~10 evenly spaced frames.

## Choices made

- Only one inspection window exists at a time; the outline, hairline connector and
  label are the entire "instrument". No measurements, scanlines or overlays.
- The focus outline and connector use the brand accent (`#2200FF`) at 1.5 px so they
  read as editorial marks, not UI.
- `assets/fonts/` is empty by design; optional `@font-face` rules for NB
  International Pro are declared and fall back to Inter (loaded through
  `@remotion/google-fonts/Inter`). Geist Mono is loaded through
  `@remotion/google-fonts/GeistMono`. Both families are `brand` props.
- Screenshots that show failing tests were not used for the demo scenes so the
  verified result reads cleanly.
