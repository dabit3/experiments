# 10 · Cinema Contact Sheet

A 16:9 product-launch template that borrows from film contact sheets and indexed
visual archives: a short row of numbered frames, one frame selected and enlarged
into a readable product view, a small chapter index at the edge, a freeze on the
meaningful end state, a brief return to the index, then the next frame.

Most of the film is one large product view. The contact sheet is for
orientation only; nobody is asked to read the thumbnails. Captions sit under the
footage, never on it. Clean cuts and controlled expansion only — no film burns,
scratches, projector effects, skew, or decorative timecodes.

- Composition `Launch`: 1920×1080, 30 fps, 1350 frames (45 s) by default.
  Duration is the sum of `scenes[].durationInFrames` (via `calculateMetadata`).
- Composition `Poster`: a still at frame 1290 (outro hero) using the same props.
- No audio track. All media comes from `launch-videos/assets` through
  `staticFile()`; `remotion.config.ts` sets `publicDir` to `../../assets`.

## Scripts

```sh
npm install
npx remotion browser ensure   # only if the headless browser download failed
npm run typecheck
npm run lint
npm run render                 # out/launch.mp4
npm run still                  # out/poster.png
npm run dev                    # Remotion Studio
```

## Scene table (default "Devin on Mac" launch)

| # | Scene id | Kind | Frames | Time | Index frame | Media | What is on screen |
|---|----------|------|-------:|------|-------------|-------|-------------------|
| 1 | `sheet`  | sheet | 0–119 | 0.0–4.0 s | — | all five thumbnails | Eyebrow, headline, subhead and the 5-frame contact sheet. Frame 01 is marked selected at local frame 72. |
| 2 | `pick`   | clip  | 120–299 | 4.0–10.0 s | 01 · Request | `screenshots/devin-web-4.png` | OS picker with macOS chosen. Caption: *Pick macOS when you start a session — same price as Linux.* |
| 3 | `build`  | clip  | 300–539 | 10.0–18.0 s | 02 · Build | `recordings/devin-working-4.mp4` (from source frame 90) | Devin working with the Desktop tab open; freezes 45 f on the finished admin page. Caption: *Devin builds the app in Xcode and runs the full test suite.* |
| 4 | `tap`    | clip  | 540–779 | 18.0–26.0 s | 03 · Run & test | `recordings/androidios.mp4`, cropped to the iPhone Simulator window | Live gameplay in the Simulator; freezes 45 f. Caption: *It taps, types, and scrolls through the app like a person.* |
| 5 | `verify` | clip  | 780–989 | 26.0–33.0 s | 04 · Verify | `screenshots/devin-web-18.png` | Recording viewer with the Pro Max review and passed checks. Caption: *Watch it live in the iPhone Simulator tab — and tap in yourself.* |
| 6 | `ship`   | clip  | 990–1199 | 33.0–40.0 s | 05 · PR | `screenshots/devin-web-12.png` | Session with the PR panel "Ready to merge". Caption: *Ship with a PR that shows the app working — not a 20-minute CI wait.* |
| 7 | `outro`  | outro | 1200–1349 | 40.0–45.0 s | 05 (hero) | `screenshots/devin-web-12.png` | Frame 05 re-selected and enlarged as the hero; closing line, CTA, lockup. |

Every clip scene follows the same beat: `expandFrames` growing the cell into the
stage → play/hold → optional `freezeHoldFrames` on the end state → return to the
index for `indexFrames`, during which the next frame is marked selected.

## Editable props

All props are validated by `launchPropsSchema` in `src/schema.ts` and editable
in Remotion Studio.

- `brand` — `paper`, `surface`, `surfaceAlt`, `line`, `ink`, `inkMuted`,
  `inkSubtle`, `accent`, `black`, `blackRaised`, `white`, `fontFamily`,
  `monoFontFamily`, `logoLight`, `logoDark`. Font families are plain CSS
  font-family strings; Inter (via `@remotion/google-fonts/Inter`) and Geist Mono
  are loaded as the fallbacks for NB International Pro.
- `content` — `featureName`, `eyebrow`, `headline`, `headlineAccentWord`,
  `subhead`, `captions[]`, `useCases[]`, `stages[]`, `cta {label,url}`,
  `outroLine`, `speedBadge`. Defaults are the approved copy from
  `launch-videos/brief/launch-mac-vm.md`, verbatim.
- `media` — a record of named slots. Each slot: `src` (path under `assets/`),
  `kind` (`image` | `video`), `startFrom`, `thumbFrame`, `playbackRate`,
  `crop {x,y,w,h}` (fractions of the source), `fit` (`cover` | `contain`),
  `sourceWidth`, `sourceHeight`. Crops and fits only scale/clip — never skew or
  recolor.
- `sheet` — `columns`, `cellWidth`, `gap`, `top`, `metadata` (the one-line
  footer, e.g. `Contact sheet · 5 frames · Devin on Mac`).
- `scenes[]` — ordered; the index is derived from every `clip` scene sorted by
  `frameIndex`, so adding or removing a clip changes the sheet automatically.
  - `sheet`: `durationInFrames`, `selectAtFrame`.
  - `clip`: `durationInFrames`, `frameIndex`, `media`, `caption`, `label`,
    `expandFrames`, `freezeHoldFrames`, `freezeAtFrame`, `indexFrames`.
  - `outro`: `durationInFrames`, `frameIndex`, `media`, `expandFrames`.

## Swapping in another launch

1. Drop the new screenshots/recordings into `launch-videos/assets/` (shared by
   all templates — do not copy them into this directory).
2. In `src/defaults.ts`, replace `defaultContent` with the new launch's copy and
   `defaultMedia` with slots pointing at the new files. Set `sourceWidth` /
   `sourceHeight` for anything that is not 1920×1080 so crops land correctly.
3. Edit `scenes`: one `clip` per index frame, in chronological order. Pick
   `media`, `caption`, `label`, and tune `startFrom` / `freezeAtFrame` so each
   freeze lands on a meaningful state. Keep the total at 1350 frames for a 45 s
   cut, or let it float — the composition follows the sum.
4. Set `sheet.metadata` and, if the frame count changed, `sheet.columns`.
5. `npm run typecheck && npm run lint && npm run render`, then sample the MP4
   with ffmpeg and check every caption is readable and every UI is legible.

## Decisions made where the brief was open

- The contact sheet shows five frames (Request → Build → Run & test → Verify →
  PR), one per stage of the workflow in `launch-mac-vm.md`. Two approved
  captions (bug reproduction, screen sizes) are kept in `content.captions` but
  not used by default scenes; swap them into a clip if you want a longer cut.
- Screenshots are shown with `fit: "contain"` so no UI edge is cropped away; the
  ~1.84:1 screenshots leave a thin strip of `brand.surface` above and below.
- `recordings/androidios.mp4` shows an iPhone Simulator next to an Android
  emulator; the default crop isolates the iPhone Simulator window so the Mac
  story stays factual. The crop only clips — pixels are not altered.
- Selected frames grow from their cell to a 1488×837 stage (77% of frame width),
  and the outro hero is 1104 px wide (57% of frame width, within the contract's
  ≥55% minimum for the subject).
- Chapter index (`01 / 05`) sits at the top-left edge, the stage label
  (`REQUEST`, `BUILD`, …) at the bottom-right in Geist Mono, both outside the
  footage. There are no timecodes.
