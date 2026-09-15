# 03 · Architectural Section Drawing

A reusable 16:9 launch video in the language of architectural presentation drawings:
orthographic planes, a sectional overview that separates to explain the workflow, precise
hairlines, measured spacing, and short leader lines from captions to the exact UI region
being discussed. Product UI is always a flat, front-facing, pixel-preserved plane; every
drawing mark (grid, sheet corners, title block, dimension lines) sits visibly outside it and
fades when a demonstration needs attention.

Test launch: **Devin on Mac** (`launch-videos/brief/launch-mac-vm.md`), 45 s at 1920×1080 / 30 fps.

## Run

```sh
npm install
npm run dev        # Remotion Studio
npm run typecheck
npm run lint
npm run render     # out/launch.mp4
npm run still      # out/poster.png (frame 790)
```

Media is served from `launch-videos/assets` via `Config.setPublicDir("../../assets")` and
referenced with `staticFile()`. No audio.

## Scene table (defaults)

| # | Scene id   | Frames | Time         | What happens |
|---|------------|--------|--------------|--------------|
| 1 | `title`    | 120    | 0:00–0:04    | Sheet, logo, eyebrow, headline (`Mac VM` in accent), dimension rule, subhead. |
| 2 | `overview` | 165    | 0:04–0:09.5  | Five stage planes stacked as a closed section, then separated along a baseline; connections draw between them; stage numbers + labels; `Request → PR` dimension line. |
| 3 | `request`  | 195    | 0:09.5–0:16  | Request plane lifts forward out of the diagram (other planes settle away, grid fades). Home screen with macOS selected; at `swapAt` the OS picker is revealed by an aligned wipe. Leader → macOS chip. |
| 4 | `build`    | 180    | 0:16–0:22    | Slides in along the baseline. `devin-working-4.mp4` at reading size, leader → the worklog. |
| 5 | `run`      | 195    | 0:22–0:28.5  | `androidios.mp4` cropped to the iPhone Simulator; leader → the app on screen. |
| 6 | `verify`   | 180    | 0:28.5–0:34.5| Split layout: iPhone (dark) and iPad testing recordings side by side; leader → the iPad app. |
| 7 | `pr`       | 150    | 0:34.5–0:39.5| Session with the PR "Ready to merge" and embedded demo videos; leader → the embedded recording. Plane then returns to its overview position. |
| 8 | `close`    | 165    | 0:39.5–0:45  | The five planes slide along the baseline and resolve into the single PR plane; `Request → … → PR` dimension line, outro line (`cloud Mac` in accent), CTA. Result holds ≥ 2.5 s. |

The composition duration is derived from `scenes[].durationInFrames` via `calculateMetadata`,
so adding/removing/retiming scenes changes the length automatically.

A persistent stage rail (01 Request … 05 PR) replaces the sheet corners during stages and keeps
the current stage underlined in accent, so the viewer always knows where they are in the section.

## Editable props (`src/schema.ts`, defaults in `src/defaults.ts`)

- **`brand`** — all colors (`paper`, `surface`, `line`, `ink`, `inkMuted`, `inkSubtle`, `accent`, …),
  `fontFamily` and `monoFontFamily` (NB International Pro → Inter fallback; Geist Mono for mono),
  `logoLight`/`logoDark`, `gridOpacity`, `gridSize`.
- **`content`** — `featureName`, `eyebrow`, `headline` + `headlineAccent`, `subhead`, `overviewTitle`,
  `captions[]`, `useCases[]`, `stages[] { id, label, media }` (stage labels + which plane represents
  each stage), `connections[]` (diagram edges as `[from, to]` stage indices), `cta`, `outroLine` +
  `outroAccent`, `speedBadge`, and `sheet { number, title, scale }` for the title block.
- **`media`** — a record of named slots: `src` (relative to `launch-videos/assets`), `kind`
  (`image` | `video`), source `width`/`height`, optional `crop` (fractions of the source), `startFrom`,
  `playbackRate`, `speedBadge`. Crops only cut and scale; pixels are never skewed or recolored.
- **`scenes`** — an ordered list of `title` | `overview` | `stage` | `close` scenes. Stage scenes take
  `stage` (index into `content.stages`), `layout` (`wide` | `split`), `media[]`, optional `swapAt`,
  `enter` (`forward` from the overview or `slide` along the baseline), and `annotations[]`.
- **Annotation anchors** — each annotation has `media`, `anchor {x, y}` in fractions of the *full*
  source (so anchors stay put if the crop changes), `caption` (index into `content.captions`),
  `side` (caption column left/right), `y` (caption box position), `startFrame`.
- **`timing`** — `enter`, `move`, `leader` durations in frames; every ease in the template is driven
  by these three numbers.

## Swapping launches

1. Drop the new screenshots/recordings into `launch-videos/assets/` and add slots under `media`
   with their real pixel dimensions (needed for exact aspect ratios) and optional crops.
2. Replace `content` copy verbatim from the launch brief; keep `captions` in the order the stages
   use them.
3. Rename/reorder `content.stages` (any count ≥ 2 works; the overview lays them out evenly) and set
   `connections` if the flow is not a simple chain.
4. Point each `stage` scene at its media slot(s) and re-place `annotations[].anchor` on the UI
   region the caption discusses. Anchors are easiest to read off the source image as fractions.
5. Adjust `durationInFrames` per scene; the total updates automatically.

All of this can also be done from the Remotion Studio props panel since the schema is a Zod
object.

## Decisions on ambiguous points

- **Grid and drawing marks**: the drafting grid is visible on the title, overview and close
  sheets and fades to zero whenever a stage plane is forward. The stage rail and title block stay
  because they are the wayfinding for the "section", but are kept to hairlines and 11–13 px mono.
- **Leader lines** are drawn *over* the product plane (they have to reach the exact UI region) but
  are a single 1 px ink line with a small accent target ring; nothing else ever overlaps the UI.
- **Verify** uses a two-plane split (iPhone + iPad) because the caption is specifically about
  device sizes; both are crops of the supplied testing recordings.
- **Run & test** crops `androidios.mp4` to the iPhone Simulator only — the Android emulator on the
  right of that recording is outside the scope of the approved claims.
- **Close**: "resolving the stages into one completed result" is implemented as the five overview
  planes sliding along the baseline into the PR plane (the result of the workflow), rather than a
  new composite image, so no UI is fabricated.
- **Speed badge** is only rendered for slots that set `speedBadge: true`; none of the default footage
  is sped up.
- **Fonts**: `@remotion/google-fonts/Inter` and `GeistMono` are loaded in `src/fonts.ts`; the brand
  `fontFamily` lists NB International Pro first so a licensed install is picked up automatically.
