# 02 — Precision Industrial Product Film

A Remotion 4 launch-video template that treats the Devin UI like a premium
industrial product: a clean paper-coloured studio, one soft key light, a thin
display plane with a subtle shadow, slow deliberate camera moves, and short
captions in the surrounding negative space.

## Direction summary

- **Open on a detail.** The first shot is a 1:1 crop of the composer and the
  `macOS` pill from `devin-web-1.png`, filling the frame at the asset's native
  resolution (no upscaling), drifting very slowly.
- **Pull back to the plane.** The camera eases out until the whole screenshot
  sits on a thin plane on the right; the headline, eyebrow and subhead fade in
  on the left once the plane has settled.
- **Front-facing demonstrations.** Every recording is shown flat, unrotated and
  pixel-preserved (crop/scale only). Perspective (`tiltDegrees`, default 5°)
  and a small horizontal slide are applied *only* while a scene fades in or
  out; transitions dissolve through the studio background so two planes never
  overlap on screen.
- **Detail ↔ context.** Scenes alternate between crops of actual controls (the
  OS picker, the iPhone Simulator, the passed test list) and wider views that
  explain them (the session view, the PR page).
- **Richness outside the interface.** A radial key light, a soft vignette and a
  brand-token shadow do all the visual work. No hardware mock-ups, glass,
  particles or fabricated UI.
- **Stable ending.** The last two scenes hold a still, front-facing view of the
  real result (`devin-web-12.png`, the PR with the live recording) with the
  outro line and CTA.

## Scene table (default launch, 45 s @ 30 fps = 1350 frames)

| # | Scene id    | Frames | Time        | Media                                   | What is shown |
|---|-------------|--------|-------------|-----------------------------------------|---------------|
| 1 | `open`      | 120    | 0:00–0:04   | `screenshots/devin-web-1.png`           | Native-resolution close-up of the composer + `macOS` pill, slow drift |
| 2 | `reveal`    | 210    | 0:04–0:11   | `screenshots/devin-web-1.png`           | Pull back to the full home screen on a plane; logo, eyebrow, headline, subhead |
| 3 | `pick`      | 150    | 0:11–0:16   | `screenshots/devin-web-4.png`           | 4:3 crop of the open OS picker with macOS ticked — caption 1, stage `01 — Request` |
| 4 | `work`      | 150    | 0:16–0:21   | `recordings/devin-working-4.mp4`        | Devin working in a session, front-facing — caption 2, stage `02 — Build` |
| 5 | `simulator` | 180    | 0:21–0:27   | `recordings/androidios.mp4`             | 9:16 crop of the iPhone Simulator window — caption 3, stage `03 — Run & test` |
| 6 | `live`      | 150    | 0:27–0:32   | `screenshots/devin-web-10.png`          | Session view with the Simulator recording — caption 4, no stage label |
| 7 | `verify`    | 150    | 0:32–0:37   | `recordings/devin-testing-2.mp4`        | Test run, pushing in to the passed checklist — caption 5, stage `04 — Verify` |
| 8 | `result`    | 120    | 0:37–0:41   | `screenshots/devin-web-12.png`          | The PR page with the recording embedded — caption 7, stage `05 — PR` |
| 9 | `cta`       | 120    | 0:41–0:45   | `screenshots/devin-web-12.png`          | Same stable view; outro line + CTA button + URL |

Total duration is always `sum(scenes[].durationInFrames)` — see
`calculateMetadata` in `src/Root.tsx`.

## Editable props (`src/schema.ts`)

Everything below is a Zod-validated prop and editable in Remotion Studio or via
`--props`.

| Prop | Purpose |
|------|---------|
| `brand` | Colour tokens (`paper`, `surface`, `ink`, `accent`, …), `fontFamily`, `monoFontFamily`, `useLicensedFont`, logo paths |
| `content` | `featureName`, `eyebrow`, `headline`, `headlineAccent`, `subhead`, `captions[]`, `stages[]`, `useCases[]`, `cta {label,url}`, `outroLine`, `speedBadge` |
| `media` | Named slots → `{ src, kind: "image" \| "video", width, height, startFrom?, playbackRate? }`. Paths are relative to `launch-videos/assets/` and loaded with `staticFile()` |
| `scenes[]` | Ordered scenes. Each has `id`, `kind` (`film` \| `cta`), `durationInFrames`, `media` key, `camera`, `caption`/`stage` indices, `captionPlacement` (`left`/`right`/`above`/`below`), `captionWidth`, `showTitle`, `titleDelay`, `showLogo`, `transitionIn`/`transitionOut` (`none` \| `fade` \| `tilt`) |
| `scenes[].camera` | `from` / `to` camera views + `easing` (`linear`/`out`/`inOut`) + `settleFrames`. A view is `{ crop: {x,y,w,h} (source fractions), planeWidth (fraction of frame width), x, y (plane centre) }`. `src/defaults.ts` exports `detail()` and `full()` helpers that build views at native pixel density |
| `lighting` | `keyX`, `keyY`, `keyRadius`, `keyIntensity`, `vignette`, `shadowStrength`, `planeBorder` |
| `transitionFrames` | Length of every fade/tilt transition |
| `tiltDegrees` | Maximum Y-rotation of the plane during a `tilt` transition (never applied while a scene holds) |

Camera positions, lighting, media, captions, durations and the closing CTA are
therefore independent: change one without touching the others.

## Swapping the launch

1. **Copy:** edit `defaultProps` in `src/defaults.ts` (content, media slots,
   scenes), or
2. **Override at render time:**

   ```sh
   npx remotion render Launch out/launch.mp4 --props=./my-launch.json
   ```

   The JSON must satisfy `launchPropsSchema`. Any subset of scenes can be
   removed or re-ordered; durations drive the composition length.
3. **New footage:** drop files in `launch-videos/assets/…`, add a `media` slot
   with its real pixel `width`/`height`, and point a scene's `media` at it.
   `detail()` uses those dimensions to keep close-ups at ≤ 1 source pixel per
   frame pixel.

## Fonts

Inter (`@remotion/google-fonts/Inter`) and Geist Mono
(`@remotion/google-fonts/GeistMono`) load deterministically as fallbacks. To use
the licensed NB International Pro, place
`NBInternationalPro-Regular.woff2` / `NBInternationalPro-Medium.woff2` in
`launch-videos/assets/fonts/` and set `brand.useLicensedFont: true`; the
`@font-face` rules in `src/fonts.ts` then resolve through `staticFile()`.

## Scripts

```sh
npm install
npm run dev        # Remotion Studio
npm run typecheck
npm run lint
npm run render     # out/launch.mp4 (1920×1080, 30 fps, no audio)
npm run still      # out/poster.png (frame 270, the reveal)
```

If the headless browser download fails: `npx remotion browser ensure`.

## Decisions made where the brief was open

- Caption 6 ("Check iPhone and iPad sizes…") is not used in the default cut
  because no supplied footage shows multiple device sizes or dark mode; it
  remains in `content.captions` for launches that have it.
- `androidios.mp4` is cropped to the iPhone Simulator only (the Android
  emulator on the right is outside the crop) so the scene matches the macOS
  claim.
- The `live` scene uses `devin-web-10.png` rather than a second recording so
  the film alternates still/moving media and stays calm.
- `zod` is pinned to `4.5.4`, the version `@remotion/zod-types@4.0.524`
  requires.
