# 18 · Premium Broadcast Package

A reusable 16:9 Remotion launch-video template for Devin, directed like a polished
contemporary broadcast package: disciplined framing, a strong headline hierarchy, concise
lower thirds, small stable chapter markers, and modular segment transitions built from
hard-edged wipes and restrained typographic stings.

The video opens with a short title treatment and a large product view, then runs four
clearly numbered segments, each centred on one visible action. Footage is always shown
flat, front-facing, uncropped or crop-only, and never overlaid: captions live in a
reserved band below the media stage so they can never cover controls or code. A
secondary panel appears exactly once, next to the delivered result, to show the merged
PR. The package closes on the approved outro line and a simple slate.

No tickers, presenters, "LIVE" badges, invented statistics, or information bars.
No audio.

## Quick start

```sh
npm install
npm run dev        # Remotion Studio
npm run typecheck
npm run lint
npm run render     # out/launch.mp4 (45s at default props)
npm run still      # out/poster.png (frame 690)
```

If Remotion's headless browser did not download during install:
`npx remotion browser ensure`.

Media is read straight from the shared `launch-videos/assets/` directory
(`Config.setPublicDir("../../assets")` in `remotion.config.ts`); nothing is copied
into this template.

## Scene table (default props · 1350 frames · 45.0 s at 30 fps)

| # | Scene id     | Type       | Frames | Seconds | What it shows |
|---|--------------|------------|-------:|--------:|---------------|
| 1 | `title`      | title      | 105 | 3.5 | Light title treatment: lockup, `NEW · DEVIN ON MAC` eyebrow, headline with "Mac VM" in accent blue, subhead. |
| 2 | `hero`       | hero       | 105 | 3.5 | Large product view — new Devin session with macOS selected (`devin-web-1.png`). |
| 3 | `chapter-1`  | chapter    |  45 | 1.5 | Dark sting: `01 │ Build & test a feature`. |
| 4 | `pick`       | demo       |  90 | 3.0 | Virtual-environment menu with Ubuntu / macOS / Windows (`devin-web-5.png`). Caption 0. |
| 5 | `build`      | demo       | 150 | 5.0 | Devin working in a Mac session (`devin-working-4.mp4`). Caption 1. |
| 6 | `chapter-2`  | chapter    |  45 | 1.5 | Dark sting: `02 │ QA before shipping`. |
| 7 | `simulator`  | demo       | 210 | 7.0 | iPhone Simulator + Android emulator, cropped to the macOS desktop (`androidios.mp4`). Captions 2 → 3. |
| 8 | `chapter-3`  | chapter    |  45 | 1.5 | Dark sting: `03 │ Reproduce & fix a bug`. |
| 9 | `verify`     | demo       | 180 | 6.0 | Devin's recorded UI test with the pass/fail rail (`devin-testing-2.mp4`). Caption 4. |
| 10 | `chapter-4` | chapter    |  45 | 1.5 | Dark sting: `04 │ PR`. |
| 11 | `ship`      | evidence   | 180 | 6.0 | Delivered result: PR view with the app-working recording (`devin-web-12.png`) plus a secondary "Merged" panel (`devin-web-8.png`). Caption 6. |
| 12 | `closing`   | closing    | 150 | 5.0 | Dark slate: lockup, "The only coding agent with a cloud Mac.", CTA `Start a Mac session`, `app.devin.ai`. |

Every scene after the first wipes in over the previous one (`motion.wipeFrames`); the
previous scene is held underneath for the duration of the wipe, so scene durations add
up exactly to the composition length. Every lower third holds for at least 2.5 s, and the
result scene holds for 6 s.

## Composition

- Id `Launch`, 1920×1080, 30 fps. Duration is `calculateMetadata` →
  `totalDuration(props.scenes)`; edit scene durations and the video re-times itself.
- `Poster` is a 1-frame still composition at `POSTER_FRAME` (690 by default) so the
  poster matches the mid-demo frame used by `npm run still`.
- Schema: `launchPropsSchema` / `LaunchProps` in `src/schema.ts`, editable in Remotion
  Studio's props panel.

## Editable props

### `brand`
Devin design tokens from `brief/brand.md`. All colors are `zColor()`.

| Prop | Default | Notes |
|------|---------|-------|
| `paper`, `surface`, `surfaceAlt`, `line` | `#F7F6F5`, `#EFEFEF`, `#FCFCFC`, `#E7E7E7` | Light surfaces |
| `ink`, `inkMuted`, `inkSubtle` | `#191919`, `#7D7D7D`, `#919191` | Text |
| `accent` | `#2200FF` | One accent: headline word, lower-third rule, chapter rule |
| `black`, `blackRaised`, `blackRaisedAlt`, `white` | `#141414`, `#1F1F1F`, `#252525`, `#FFFFFF` | Dark stings / closing |
| `fontFamily` | `"NB International Pro", "Inter", …` | Inter is loaded via `@remotion/google-fonts/Inter` |
| `monoFontFamily` | `"Geist Mono", ui-monospace, …` | Loaded via `@remotion/google-fonts/GeistMono` |
| `fontFaceCss` | `""` | Optional `@font-face` CSS; relative `url("…")` paths resolve against `launch-videos/assets` |
| `logoLight`, `logoDark` | `logos/devin-lockup-horizontal-{black,white}.png` | Lockups, never redrawn |
| `safeMargin` | `96` | Outer safe area in px |
| `radius` | `16` | Media frame radius |

### `content`
Verbatim copy from `brief/launch-mac-vm.md`: `featureName`, `eyebrow`, `headline`,
`headlineAccent` (substring of the headline drawn in accent — set `""` for none),
`subhead`, `captions[]` (the seven approved captions, referenced by index from scenes),
`useCases[]`, `stages[]`, `cta { label, url }`, `outroLine`, `speedBadge`.

### `media`
A record of named slots. Each slot:

```ts
{
  src: "screenshots/devin-web-1.png", // relative to launch-videos/assets → staticFile()
  kind: "image" | "video",
  width: 2990, height: 1624,           // source pixel size, used for aspect-correct fitting
  startFrom?: 60,                      // video start frame
  crop?: { x, y, w, h },               // fractions 0–1 of the source; crop only, no skew
  playbackRate?: 1,
}
```

Default slots: `hero`, `pick`, `work`, `simulator`, `verify`, `result`, `merged`.
Scenes refer to slots by key, so retargeting a scene is a one-line change.

### `scenes`
An ordered array; the composition plays them back to back. Types:

| Type | Fields |
|------|--------|
| `title` | `id`, `durationInFrames` |
| `hero` | `media`, `label` |
| `chapter` | `index`, `title` |
| `demo` | `chapter`, `chapterTitle`, `media`, `lowerThirds[]`, `showSpeedBadge?` |
| `evidence` | as `demo` plus `evidence` (slot key) and `evidenceLabel` |
| `closing` | `id`, `durationInFrames` |

`lowerThirds[]` cues are `{ caption, from, durationInFrames }` — `caption` indexes
`content.captions`, `from` is a frame offset within the scene. Set `showSpeedBadge: true`
on a demo to show the small mono `content.speedBadge` chip when footage is sped up.

### `motion`
`wipeFrames` (scene wipe length, 14), `enterFrames` (ease-out entrances, 14),
`lowerThirdFrames` (lower-third in/out, 12). All easing is cubic; no bounce or overshoot.

## Swapping in a different launch

1. Edit `src/defaults.ts`: replace `defaultContent` with the new launch copy, point
   `defaultMedia` slots at the new screenshots/recordings under `launch-videos/assets/`
   (record their real pixel sizes), and adjust `defaultScenes` — chapter titles, which
   slot each segment shows, which caption index each lower third uses, and durations.
2. Or leave the code alone and render with a props file:

   ```sh
   npx remotion render Launch out/launch.mp4 --props=./my-launch.json
   npx remotion still Launch out/poster.png --frame=690 --props=./my-launch.json
   ```

   The JSON must satisfy `launchPropsSchema` (full object: `brand`, `content`, `media`,
   `scenes`, `motion`).
3. Duration follows the scene list automatically. Keep every lower third ≥ 75 frames and
   the result scene ≥ 75 frames so the viewer can read them.

## Components (`src/components`, `src/scenes`)

- `TitleScene`, `HeroScene`, `ChapterScene`, `DemoScene`, `EvidenceScene`, `ClosingScene`
- `Media` — `Img` / `OffthreadVideo` with aspect-correct fit and fractional crop
- `LowerThird` — accent rule + kicker + one-line caption, in the reserved caption band
- `ChapterMarker` — small stable `01 │ Title` marker with the feature name at right
- `Wipe` — hard-edged clip-path wipe (`left` / `right` / `down`)
- `Headline`, `Logo`, `SpeedBadge`

## Decisions on ambiguous points

- **NB International Pro** is not in the shared `assets/fonts/` (empty by design), so
  Inter renders everywhere. If you have the licensed `.woff2` files, drop them into
  `launch-videos/assets/fonts/` and set `brand.fontFaceCss` to
  `NB_INTERNATIONAL_PRO_FONT_FACE` from `src/fonts.ts` (or your own CSS). Nothing is
  vendored, and no 404s are emitted by default.
- **Chapter titles** are the brief's use-case labels, except the final segment, which
  uses the stage label `PR` because the segment is about the delivered pull request.
- **Caption 5** ("Check iPhone and iPad sizes…") is not used by the default scene list —
  there is no supplied footage of size/dark-mode checks, and the brief forbids
  fabricating UI. It stays in `content.captions` for launches with matching footage.
- **`androidios.mp4`** is cropped to the macOS desktop inside its playback chrome so the
  iPhone Simulator is the subject; it is a crop only, at native aspect.
- The **speed badge** is off by default because no default footage is sped up.
- **Lower thirds** wipe in from the accent rule and fade out whole so a caption is never
  half-visible while dimming.
