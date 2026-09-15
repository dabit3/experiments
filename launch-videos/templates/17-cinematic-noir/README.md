# 17 · Cinematic Noir

A restrained noir treatment of the Devin launch footage: expansive darkness on the
darkest brand surface (`#141414`), strong contrast, tightly controlled shutter reveals,
and deliberate pauses. Product UI is shown flat and pixel-preserved at all times; the
only "lighting" is a faint rim light and a very slight center lift of the stage, both
drawn *outside* the interface. No smoke, bloom, particles, flares, or invented imagery.

Structure: a feature statement in a mostly empty frame → large product views revealed
through a clean shutter mask and held while the recording plays → short quiet title
cards between them → a clear view of the result → a restrained CTA.

## Run

```sh
npm install
npm run dev        # Remotion Studio
npm run render     # out/launch.mp4 (1920x1080, 30fps, 45s with default props)
npm run still      # out/poster.png (frame 480, the build scene fully revealed)
npm run typecheck && npm run lint
```

Media is loaded from `launch-videos/assets/` via `Config.setPublicDir("../../assets")`
and referenced with `staticFile("recordings/…")` / `staticFile("screenshots/…")`.
Node 20+. If Remotion's headless browser is missing, run `npx remotion browser ensure`.

## Scenes (default props, 1350 frames)

| # | Scene id      | Type      | Frames | Shows                                                                                             |
|---|---------------|-----------|--------|---------------------------------------------------------------------------------------------------|
| 1 | `open`        | statement | 120    | Eyebrow "New · Devin on Mac", headline "Devin now runs in a **Mac VM**" (accent word), subhead, lockup. Mostly empty frame. |
| 2 | `pick`        | product   | 180    | `screenshots/devin-web-4.png` — home with the OS picker open (Ubuntu / macOS / Windows). Horizontal shutter reveal. Caption 1. |
| 3 | `title-build` | title     | 60     | Quiet title card: "Build & test a feature".                                                       |
| 4 | `work`        | product   | 255    | `recordings/devin-working-4.mp4` — Devin working through a task with the timeline and the Desktop tab. Caption 2. |
| 5 | `title-qa`    | title     | 60     | Quiet title card: "QA before shipping".                                                           |
| 6 | `simulator`   | product   | 225    | `recordings/androidios.mp4` cropped to the iPhone Simulator (Android emulator cropped out), split layout with the caption beside it. Vertical shutter. Caption 3. |
| 7 | `verify`      | product   | 210    | `recordings/devin-testing-2.mp4` from 0:37 — recording player with the "It should …" checklist reaching 6 passed / 0 failed. Caption 5. |
| 8 | `result`      | product   | 150    | `screenshots/devin-web-9.png` — session with the iOS PR "Ready to merge" and the Wisp Simulator recording embedded. Iris reveal. Caption 7. |
| 9 | `outro`       | outro     | 90     | Lockup, "The only coding agent with a cloud Mac.", CTA button "Start a Mac session", `app.devin.ai`. |

Captions used (in the brief's order): 1, 2, 3, 5, 7. Every product hold is >= 2.5s and
the footage plays at 1x (no speed badge shown; `scene.speedBadge: true` shows
`content.speedBadge` in the frame's corner if you speed a slot up with `playbackRate`).

## Editable props (`src/schema.ts`, defaults in `src/defaults.ts`)

- `brand` — all color tokens from `brief/brand.md`, `fontFamily`, `monoFontFamily`,
  `logoLight`, `logoDark`. The font stack lists `"NB International Pro"` first; Inter
  (loaded from `@remotion/google-fonts/Inter`) is the deterministic fallback and
  Geist Mono the mono face. Dropping `NBInternationalPro-Regular.woff2` /
  `NBInternationalPro-Medium.woff2` into `launch-videos/assets/fonts/` activates the
  `@font-face` rules in `src/Root.tsx` automatically.
- `content` — `featureName`, `eyebrow`, `headline`, `headlineAccentWord` (the single
  accent-colored word/phrase; empty for none), `subhead`, `captions[]`, `useCases[]`,
  `stages[]`, `cta {label,url}`, `outroLine`, `speedBadge`.
- `media` — named slots `{ src, kind, startFrom?, crop?, playbackRate?, aspect? }`.
  `crop` is fractional (0–1) and pixel-preserving (scale/crop only). `aspect` is the
  source width/height and is needed for non-16:9 sources so the frame has no bars.
- `scenes[]` — ordered; `durationInFrames` sums to the composition length via
  `calculateMetadata`. Scene types:
  - `statement` — `eyebrow?`, `headline?`, `subhead?`, `showLogo`.
  - `title` — `index?` (small mono label), `text`.
  - `product` — `media` (slot key), `caption`, `captionIndex?`, `layout: "full" | "split"`,
    `mask?` (per-scene override), `holdOutFrames` (freeze the footage on its last frame
    for N frames as a held still), `speedBadge`.
  - `outro`.
- `mask` — default reveal for product scenes: `kind: "shutter-horizontal" |
  "shutter-vertical" | "iris" | "none"`, `durationInFrames`, `delayInFrames`, `slit`
  (a 1px white line on the moving shutter edge, in the dark area only).
- `lighting` — `edgeGlow` (0–1, rim light behind the media frame), `keyLine` (1px accent
  hairline next to captions), `vignette` (0–1, slight lift of the stage center toward
  `blackRaised`; drawn beneath the media so it never tints UI).
- `layout` — `safeMargin`, `mediaWidth` (full-layout frame width; 1536 = 80% of frame,
  well above the 55% legibility floor), `mediaTop`, `radius`, `captionSize`.

## Swapping in a different launch

1. Edit `defaultProps` in `src/defaults.ts` (copy, media slots, scene order and
   durations), or
2. Render with a props file: `npx remotion render Launch out/x.mp4 --props=./my-launch.json`
   (the JSON must satisfy `launchPropsSchema`; Remotion Studio's props panel edits it
   live).

Add a scene by appending to `scenes[]`; add footage by adding a media slot and pointing
a `product` scene at it. Durations are per-scene, so the total length follows.

## Decisions / notes

- `brief/assets.md` describes `devin-web-10..19` one index off from the actual files
  (e.g. `devin-web-9.png` is the session with the "Add Wisp" PR ready to merge and the
  Simulator recording embedded, `devin-web-12.png` is the Starcup PR, `devin-web-17.png`
  the dark Simulator screenshot grid). Slots were chosen by looking at the files.
- `androidios.mp4` is a testing-recording player showing the iPhone Simulator and an
  Android emulator side by side; the default crop keeps the Simulator window (menu bar,
  device label, phone) and drops the Android window, as the brief allows.
- The rim light and the stage's center lift are the only gradients; both are outside
  the interface and are the direction's "subtle edge lighting". Set `lighting.edgeGlow`
  and `lighting.vignette` to `0` for a pure flat black stage.
- Entrances are ease-out cubic (400–500ms), shutters ease-in-out (1s), scene exits are
  short fades to black (≈270ms). No springs, no overshoot.
