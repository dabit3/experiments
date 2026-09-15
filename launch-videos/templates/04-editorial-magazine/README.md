# 04 — Luxury Editorial Magazine

A reusable 16:9 Remotion launch-video template for Devin, art-directed like a
contemporary print magazine: confident typography at contrasting scales,
tight/unexpected crops of the real product UI, asymmetric margins, and a
deliberate alternation between dense and quiet pages.

- Composition `Launch`: 1920×1080 @ 30fps. Duration is derived from the sum of
  `scenes[].durationInFrames` (defaults total 1200 frames = 40s).
- Composition `Poster`: a still of the cover at frame 60 (`npm run still`).
- No audio track.

## Run

```sh
npm install                # first time; run `npx remotion browser ensure` if the browser download fails
npm run dev                # Remotion Studio — every prop below is editable in the right-hand panel
npm run typecheck
npm run lint
npm run render             # → out/launch.mp4
npm run still              # → out/poster.png
```

All media is served from `launch-videos/assets` via
`Config.setPublicDir("../../assets")` and referenced with `staticFile()`.
Nothing is copied into this directory.

## Scene table (default "Devin on Mac" launch)

| # | id          | Layout    | Frames (s)  | Reveal | Media (asset)                                              | Copy |
|---|-------------|-----------|-------------|--------|------------------------------------------------------------|------|
| 1 | `cover`     | `cover`   | 135 (4.5s)  | cut    | `screenshots/devin-web-1.png` — tight crop of the prompt box with the macOS selector, bleeding off the right edge | Headline with accent word, subhead (optional eyebrow when `content.eyebrow`/`featureName` are set) |
| 2 | `pick`      | `spread`  | 135 (4.5s)  | wipe   | `screenshots/devin-web-4.png` — OS picker open (Ubuntu / macOS / Windows) | caption 0 |
| 3 | `work`      | `full`    | 180 (6.0s)  | cut    | `recordings/devin-working-4.mp4` — Devin working in a session | caption 1 in a narrow left column |
| 4 | `simulator` | `spread`  | 135 (4.5s)  | wipe   | `screenshots/devin-web-10.png` — iPhone Simulator + "It should…" checklist | caption 2, margin word "Taps." |
| 5 | `live`      | `full`    | 180 (6.0s)  | cut    | `recordings/androidios.mp4` — live iPhone Simulator (cropped to the iPhone half) | caption 3, margin word "Live." |
| 6 | `sizes`     | `dense`   | 135 (4.5s)  | wipe   | `screenshots/devin-web-17.png` (six iPhone screenshots incl. dark mode) + `screenshots/devin-web-19.png` (iPad Pro) | caption 5 |
| 7 | `pr`        | `spread`  | 150 (5.0s)  | cut    | `screenshots/devin-web-12.png` — PR "Ready to merge" panel | caption 6, margin word "Shipped." |
| 8 | `closing`   | `closing` | 150 (5.0s)  | cut    | `screenshots/devin-web-8.png` — merged PR header (the actual outcome) | `outroLine`, CTA button + URL, on `brand.black` |

Every caption is on screen for the whole scene (≥ 4.5s), well above the 2.5s
minimum. Captions are `content.captions[captionIndex]` — caption 4
("Reproduce a bug…") is in the default copy but unused by the default scene
list; add a scene with `captionIndex: 4` to use it.

### Layouts

| Layout    | Composition |
|-----------|-------------|
| `cover`   | Magazine cover. Eyebrow + oversized display headline + subhead on the left; one tightly cropped screenshot on the right (bleeds off-frame when `bleed: true`). |
| `spread`  | Large media on one side (`mediaSide`, `mediaWidth`), small kicker + caption typeset at the bottom of the opposite column. Optional `marginWord` sits in the empty top corner of the text column — never over the media. |
| `full`    | Generous, readable full-height media; a narrow caption column on the other side. Used for recordings. |
| `dense`   | Two media blocks (a wide one bottom-left, a tall one right) with the caption top-left. The "busy" page in the dense/quiet rhythm. |
| `closing` | Quiet dark spread: outcome screenshot top-left, `outroLine` top-right, CTA + URL bottom-right. |

### Transitions

Per the direction only three moves exist: a clean `cut`, an aligned image
replacement (consecutive scenes share the same margin grid, so media blocks
land on the same edges), and a brief horizontal `wipe` reveal
(`layoutTokens.revealFrames`, default 10 frames). No page flips, no
ornamental effects, no stock or lifestyle imagery.

## Editable props (`src/schema.ts`, defaults in `src/defaults.ts`)

| Prop | What it controls |
|------|------------------|
| `brand.*` colors (`paper`, `surface`, `ink`, `inkMuted`, `accent`, `black`, …) | Brand tokens from `brief/brand.md`. |
| `brand.fontFamily`, `brand.monoFontFamily` | Font stacks. Defaults: `"NB International Pro", Inter, …` and `"Geist Mono", …`. Inter and Geist Mono are loaded via `@remotion/google-fonts`. |
| `brand.customFontFaces[]` | Optional `@font-face` declarations (`family`, `src` under `assets/`, `weight`) — drop the licensed NB International Pro files into `launch-videos/assets/fonts/` and list them here; the stack already prefers that family. |
| `brand.logoLight` / `brand.logoDark` | Lockups shown top-left on paper / black pages (`layoutTokens.logoHeight`, default 40px). |
| `content.featureName`, `eyebrow`, `headline`, `accentWord`, `subhead` | Cover copy. `accentWord` is the first matching substring of `headline`, set in `brand.accent` and kept on one line. |
| `content.captions[]` | Scene explanations, referenced by `scenes[].captionIndex`. |
| `content.cta`, `outroLine` | Closing spread. |
| `content.issueLabel` | Optional running head, top-right; hidden unless `layoutTokens.showRunningHead` is true. |
| `content.useCases`, `stages`, `speedBadge` | Available for custom scenes/variants (not used by the default layouts). |
| `media.<key>` | `src` (under `assets/`), `kind` (`image` \| `video`), `aspect` (source w/h — needed to place the crop correctly), `startFrom`, `playbackRate`, `crop` `{x,y,w,h}` in 0–1 source fractions. Crops only *window* the pixels — media is never stretched, skewed or recolored. |
| `scenes[]` | Order, `durationInFrames`, `layout`, `reveal`, `media` keys, `captionIndex`, `kicker`, `marginWord`, `mediaSide`, `bleed`, `dark`, `mediaWidth`. |
| `layoutTokens` | `margin`, `gutter`, `radius`, `revealFrames`, `textEnterFrames`, `showFolio` (corner logo), `showRunningHead`, `showPageNumbers` (both off by default), `logoHeight`. |
| `type` | Type scale in px: `display`, `heading`, `body`, `small`, `eyebrow`, `marginWord`. |

## Swapping in a new launch

1. Add the new screenshots/recordings to `launch-videos/assets/` (the shared
   public dir).
2. In `src/defaults.ts` replace `content` with the new launch's approved copy
   (headline, accent word, captions in the order you want to tell the story,
   CTA, outcome line).
3. Point each `media` slot at the new files. Set `aspect` to the real
   width/height of the source and adjust `crop` so the relevant UI region is
   framed. Check crops in Studio at the scene's first frame.
4. Edit `scenes[]`: pick a layout per beat, alternate `full`/`spread` with one
   `dense` page, keep captions ≥ 2.5s (≥ 75 frames), and let margin words
   only appear on pages whose text column has room.
5. `npm run typecheck && npm run lint && npm run render`.

Alternatively pass a props JSON at render time:
`npx remotion render Launch out/other.mp4 --props=./other-launch.json`.

## Decisions / ambiguities

- The cover shows the prompt box from `devin-web-1.png` cropped tight so the
  macOS selector is readable at cover scale, rather than the full window.
- `androidios.mp4` is cropped to its left half so only the iPhone Simulator
  is shown (the Android emulator half is out of scope for the Mac launch).
- The closing "actual outcome" is the merged-PR header from `devin-web-8.png`;
  the PR-review scene uses the "Ready to merge" panel from `devin-web-12.png`.
- Margin words ("Taps.", "Live.", "Shipped.") describe visible actions in the
  adjacent media and stay inside the text column.
- ESLint is pinned to 9.x because `@remotion/eslint-config-flat` does not yet
  load under ESLint 10.
