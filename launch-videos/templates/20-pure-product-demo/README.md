# 20 · Pure Product Demonstration

A 16:9 launch template in which the real product UI is the only visual material. One brief
feature statement, then straight into the workflow: pristine screenshots establish states,
recordings show actions, and one short caption per beat sits in reserved space below or
beside the footage. Hard match cuts between genuine interface states, restrained eased
zooms, no device mockups, no interludes, no animated backgrounds.

Default props are the **Devin on Mac** test launch (`brief/launch-mac-vm.md`) styled with the
Devin tokens (`brief/brand.md`). Output: `Launch`, 1920×1080, 30 fps, 1350 frames (45 s), no audio.

```sh
npm install            # if the headless browser fails: npx remotion browser ensure
npm run dev            # Remotion Studio
npm run typecheck && npm run lint
npm run render         # out/launch.mp4
npm run still          # out/poster.png (frame 470)
```

## Scene table (default props)

| # | id          | Frames | Time        | Footage (`assets/`)                                          | Caption / label                                     |
|---|-------------|--------|-------------|--------------------------------------------------------------|-----------------------------------------------------|
| 1 | `statement` | 75     | 0.0 – 2.5 s | —                                                            | Lockup · eyebrow · headline (accent “Mac VM”) · subhead |
| 2 | `request`   | 150    | 2.5 – 7.5 s | `devin-web-1.png` → match cut → `devin-web-4.png` (OS picker) | 01 · Request — “Pick macOS when you start a session…” |
| 3 | `build`     | 144    | 7.5 – 12.3 s| `devin-working-4.mp4` at 3× (badge shown)                     | 02 · Build · `3x` — “Devin builds the app in Xcode…” |
| 4 | `simulator` | 210    | 12.3 – 19.3 s| `androidios.mp4`, cropped to the iPhone Simulator, 1×        | 03 · Run & test (right column) — “It taps, types, and scrolls…” |
| 5 | `live`      | 165    | 19.3 – 24.8 s| `devin-web-14.png` (testing recording, 8 passed / 0 failed)  | 03 · Run & test — “Watch it live in the iPhone Simulator tab…” |
| 6 | `sizes`     | 180    | 24.8 – 30.8 s| `devin-web-19.png` (iPad) → match cut → `devin-web-18.png` (dark iPhone) | 04 · Verify — “Check iPhone and iPad sizes, dark mode…” |
| 7 | `result`    | 246    | 30.8 – 39.0 s| `devin-web-12.png` (PR “Ready to merge” with Simulator demo videos) | 05 · PR — “Ship with a PR that shows the app working…” |
| 8 | `outro`     | 180    | 39.0 – 45.0 s| —                                                            | Outro line · CTA button · URL · lockup              |

Total duration is derived from the scene list by `calculateMetadata`; add, remove, or
retime scenes and the composition length follows.

## Editable props (`src/schema.ts`, defaults in `src/defaults.ts`)

- **`brand`** — all colors, `fontFamily`, `monoFontFamily`, light/dark lockup paths, and
  optional `fontFaces` (`{family, src, weight}`) for a licensed NB International Pro dropped
  into `assets/fonts/`. Inter and Geist Mono are loaded from `@remotion/google-fonts` as the
  fallbacks; the family stacks are plain strings so any launch can override them.
- **`content`** — `featureName`, `eyebrow`, `headline`, `headlineAccent` (substring set in
  the accent color; `""` for none), `subhead`, `captions[]`, `stages[]`, `useCases[]`,
  `cta {label, url}`, `outroLine`, `speedBadge`.
- **`media`** — named slots: `src` (path under `assets/`), `kind` (`image` | `video`),
  source `width`/`height`, and for video `startFrom` (source frame) and `playbackRate`.
  Optional `crop {x, y, w, h}` in fractions of the source frame (0–1). Footage is always
  flat and front-facing; the only transforms are crop and uniform scale.
- **`scenes`** — ordered list. `statement` and `outro` take only `durationInFrames`.
  `demo` scenes take `shots[]` (`media` slot key, `at` frame within the scene, optional
  `zoom {from, to, originX, originY}` eased over the shot), `caption` and `stage` indexes
  into `content`, `captionSide` (`bottom` | `right`), and `speedLabel` (badge shown next to
  the stage label when footage is sped up; `null` otherwise).
- **`layout`** — margins, `captionBand` height, `captionColumn` width, `gap`,
  `frameRadius`, `captionSize`.
- **`posterFrame`** — frame used by the `Poster` still composition.

## Swapping launches

1. Add the new screenshots/recordings to `launch-videos/assets/` (shared, never copied here).
2. Either edit `src/defaults.ts`, or write a JSON file with the full `LaunchProps` object
   and render with `npx remotion render Launch out/launch.mp4 --props=./my-launch.json`.
3. Keep captions to one line at `layout.captionSize` (≈70 characters) and keep result
   holds ≥ 2.5 s. Use `speedLabel` whenever a recording plays faster than 1×.

## Decisions on ambiguous points

- `brief/assets.md` describes `devin-web-9…12` slightly out of step with the files: on disk
  `devin-web-10/11` are the Wisp testing-recording viewer (12 passed / 3 failed) and
  `devin-web-12` is the Starcap Circuit PR (“Ready to merge”, Simulator demo videos). The
  template uses `devin-web-14` (Afterhours Maze, 8 passed / 0 failed) for the “watch it live”
  beat and `devin-web-12` for the delivered result so no beat shows failing checks.
- `androidios.mp4` shows an iPhone Simulator beside an Android emulator; it is cropped to
  the iPhone side (with the Simulator menu bar for context) because the launch is
  iOS-only. The crop is a prop.
- The speed badge lives in the caption line (next to the stage label) rather than over the
  footage, so it never covers product UI.
- `useCases` is carried in props for future scenes but not rendered by default; the five
  captions used map to the brief's stages in order (caption 4, “Reproduce a bug…”, is
  unused because no bug-fix footage exists in the asset set).
