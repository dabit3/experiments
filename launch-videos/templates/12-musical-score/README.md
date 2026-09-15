# 12 · Musical Score

A 16:9 launch-video template that borrows the structure of a musical score. A narrow
strip along the bottom holds one horizontal track per workflow stage. A playhead moves
left to right, introduces each stage, and cues a large product recording above it.
Meaningful events in the footage ("macOS selected", "All assertions passed",
"Ready to merge") are marked on the tracks and set the rhythm: a cue can pulse an accent,
swap the caption, swap the media, or hand off to the next stage. At the end the tracks
resolve into a single accent line under the demonstrated result.

Horizontal position on the score is narrative progression, not elapsed execution time.
Tracks are drawn one after another because the source footage shows sequential work;
overlapping `span`s are supported for launches where the footage shows parallel work.
No decorative notes, no audio visualizer, silent by default — captions carry the story.

## Commands

```sh
npm install
npm run dev        # Remotion Studio
npm run typecheck
npm run lint
npm run render     # out/launch.mp4 (1920x1080, 30 fps, 45 s)
npm run still      # out/poster.png (frame 700)
```

Media is read from `../../assets` via `Config.setPublicDir` and `staticFile()`;
nothing is copied into the template.

## Scene table (default launch: Devin on Mac)

| # | Scene   | Frames      | Track       | Media                                                     | Caption                                                                  | Cues (frame in scene → event)                                                        |
|---|---------|-------------|-------------|-----------------------------------------------------------|--------------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| 0 | intro   | 0–119       | —           | —                                                         | Eyebrow, headline (accent on "Mac VM"), subhead; empty score fades in     | —                                                                                    |
| 1 | request | 120–329     | 01 Request  | `devin-web-4.png` → `devin-web-1.png`                     | Pick macOS when you start a session — same price as Linux.               | 105 → "macOS selected" (media swap)                                                  |
| 2 | build   | 330–539     | 02 Build    | `devin-working-4.mp4` (from source frame 150)             | Devin builds the app in Xcode and runs the full test suite.              | 90 → "PR opened"; 190 → "All assertions passed"                                      |
| 3 | run     | 540–779     | 03 Run & test | `devin-web-11.png` → `androidios.mp4` (Simulator crop)  | It taps, types, and scrolls… → Watch it live in the iPhone Simulator tab… | 105 → "Live iPhone Simulator" (media + caption swap)                                 |
| 4 | verify  | 780–1019    | 04 Verify   | `devin-testing-2.mp4` (from source frame 1110) → `devin-web-17.png` | Reproduce a bug, fix it… → Check iPhone and iPad sizes, dark mode…   | 135 → "5 passed · 0 failed" (media + caption swap)                                   |
| 5 | pr      | 1020–1199   | 05 PR       | `devin-web-12.png`                                        | Ship with a PR that shows the app working — not a 20-minute CI wait.     | 60 → "Ready to merge"                                                                |
| 6 | outro   | 1200–1349   | —           | —                                                         | The only coding agent with a cloud Mac. + CTA                            | Tracks collapse into one accent line, then the result and CTA arrive                  |

Every stage: the playhead eases to the start of the track (`layout.playheadEaseFrames`),
the label brightens, the bar fills as the stage plays, and the media/caption cross-fade
in. Completed tracks stay ink-black with their cue markers filled accent.

## Editable props (`src/schema.ts`, defaults in `src/defaultProps.ts`)

- `brand` — colors (`paper`, `surface`, `line`, `ink`, `inkMuted`, `inkSubtle`,
  `accent`, `white`), `fontFamily`, `monoFontFamily`, `logoLight`, `logoDark`.
- `content` — `featureName`, `eyebrow`, `headline`, `headlineAccent`, `subhead`,
  `captions[]`, `useCases[]`, `stages[]` (track labels), `cta`, `outroLine`, `speedBadge`.
- `media` — a record of named slots `{ src, kind, width, height, startFrom, playbackRate, crop }`.
  `crop` is fractional and only crops/scales (never skews). A speed badge appears only
  when `playbackRate > 1`.
- `scenes[]` — ordered `intro | stage | outro` entries with `durationInFrames`. Stage
  scenes take `track`, `mediaSlot`, `captionIndex`, optional `span` (fractions 0–1 of
  the score width; omit for equal sequential bars, overlap for parallel work) and
  `cues[]` (`at`, `label`, optional `mediaSlot`, `captionIndex`, `accent`).
  The composition length is derived from the scenes (`calculateMetadata`).
- `layout` — `margin`, `mediaWidth/Height/Top`, `captionGap`, `stripTop`, `stripHeight`,
  `labelColumnWidth`, `playheadEaseFrames`.
- `sound` — `enabled` (default `false`), `cueAccentSrc` (path under `assets/`), `volume`.
  When enabled, a short accent plays at every cue; the render is silent otherwise.

## Fonts

Inter (`@remotion/google-fonts/Inter`) and Geist Mono (`@remotion/google-fonts/GeistMono`)
are loaded deterministically as the fallbacks named in `brand.fontFamily` /
`brand.monoFontFamily`. If licensed NB International Pro files are placed under
`assets/fonts/`, `src/fonts.ts` registers `@font-face` rules for them and the first
family in the stack takes over with no other change.

## Swapping in another launch

1. Replace `content` copy and `stages` labels in `src/defaultProps.ts` (or pass props
   from Studio / `--props`).
2. Point `media` slots at files under `launch-videos/assets/`. Record real `width`/`height`
   so the view keeps the aspect ratio; use `startFrom` to pick the meaningful part of a
   recording and `crop` to isolate a region (for example the Simulator window).
3. Rewrite `scenes`: one stage per track, `durationInFrames` for each, and `cues` at the
   frames where the footage shows an event. Cue labels should state what is visible on
   screen at that moment.
4. Run `npm run render`; the duration follows the scenes automatically.

## Decisions on ambiguous points

- Track spans are equal sequential bars by default. The supplied Mac VM footage shows
  the stages one after another, so no overlap is drawn; `span` exists for launches that
  demonstrate parallel work.
- Cue labels quote what the footage shows at that frame (e.g. `5 passed · 0 failed`
  from `devin-testing-2.mp4`), not aggregate claims.
- `assets.md` numbering for some `devin-web-*.png` files is off by one relative to the
  actual files; the defaults reference the files that visibly show the intended UI
  (`devin-web-12.png` = Starcup Circuit PR "Ready to merge", `devin-web-17.png` = dark
  Simulator-testing screenshot grid).
- The outro opens with a ~2 s pause on the resolved score before the result line and
  CTA arrive — the "deliberate pause" of the direction.
- The poster is frame 700 (live Simulator with the score mid-way), which reads well as a
  thumbnail.
