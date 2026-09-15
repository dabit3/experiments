# 01 · Swiss Grid in Motion

A reusable 16:9 launch-video template for Devin built with Remotion 4. The
composition sits on a rigid 12-column grid: large flush-left typography,
asymmetric media/caption splits, generous negative space, and one accent color
used only for the active workflow stage, the eyebrow tick, and the accent word
in the headline. Scenes change by expanding grid regions, sliding panels along
shared column lines, and revealing type through rectangular masks. No
gradients, no floating objects, no elastic motion, no depth.

Default props ship the **Devin on Mac** launch (copy verbatim from
`launch-videos/brief/launch-mac-vm.md`). Every UI asset is rendered flat,
front-facing, unskewed, and only cropped with a rectangle — never redrawn.

## Run

```sh
npm install
npm run dev        # Remotion Studio
npm run typecheck
npm run lint
npm run render     # out/launch.mp4  (1920x1080, 30fps, 45s)
npm run still      # out/poster.png  (frame 700)
```

Requires Node 20+. If the headless browser download fails during install run
`npx remotion browser ensure`.

`remotion.config.ts` sets `Config.setPublicDir("../../assets")`, so every
`media[*].src` and logo path is resolved against the shared
`launch-videos/assets/` directory via `staticFile()`.

## Scenes (default 45 s / 1350 frames)

| # | id          | kind      | frames | media slot  | source                            | caption                                                                  | stage      |
|---|-------------|-----------|--------|-------------|-----------------------------------|--------------------------------------------------------------------------|------------|
| 1 | `open`      | statement | 120    | —           | —                                 | Headline "Devin now runs in a **Mac VM**" + subhead                      | —          |
| 2 | `pick`      | feature   | 180    | `pick`      | `screenshots/devin-web-4.png` (crop on OS selector) | Pick macOS when you start a session — same price as Linux.     | Request    |
| 3 | `work`      | feature   | 240    | `work`      | `recordings/devin-working-4.mp4`  | Devin builds the app in Xcode and runs the full test suite.              | Build      |
| 4 | `simulator` | feature   | 240    | `simulator` | `recordings/androidios.mp4` (crop on iPhone) | It taps, types, and scrolls through the app like a person.    | Run & test |
| 5 | `verify`    | feature   | 240    | `verify`    | `recordings/devin-testing-2.mp4` (from 35 s) | Reproduce a bug, fix it, and prove the fix on screen.         | Verify     |
| 6 | `result`    | feature   | 180    | `result`    | `screenshots/devin-web-12.png`    | Ship with a PR that shows the app working — not a 20-minute CI wait.     | PR         |
| 7 | `outro`     | cta       | 150    | —           | —                                 | Product name, outro line, CTA button, URL on `brand.black`               | —          |

Scene kinds:

- **statement** — eyebrow, large headline (accent substring), narrow subhead.
  Each line enters through a rectangular mask and exits the same way.
- **feature** — media panel beside a narrow caption column. `enter: "expand"`
  grows the panel out of its grid region along the shared top rail;
  `enter: "slide"` slides the panel in along the column line it will occupy.
  Captions are masked in a few frames after the panel settles. Optional
  use-case label (`useCase`) and workflow stage (`stage`) that highlights the
  matching label in the bottom rail.
- **cta** — a dark region expands left-to-right across the frame, then the
  dark lockup, product name, outro line, and CTA are masked in and held.

The total duration is derived from `scenes[*].durationInFrames` in
`calculateMetadata`, so adding, removing, or re-timing scenes needs no other
change.

## Editable props (`src/schema.ts`, defaults in `src/defaults.ts`)

| group     | keys                                                                                                                 |
|-----------|----------------------------------------------------------------------------------------------------------------------|
| `brand`   | `paper surface surfaceAlt line ink inkMuted inkSubtle accent black blackRaised white`, `fontFamily`, `monoFontFamily`, `brandFontFiles`, `logoLight`, `logoDark` |
| `grid`    | `columns`, `margin`, `gutter`, `railHeight`, `showGuides`                                                            |
| `content` | `featureName eyebrow headline headlineAccent subhead captions[] useCases[] stages[] cta{label,url} outroLine speedBadge` |
| `media`   | record of slots: `src kind(image\|video) sourceWidth sourceHeight startFrom? crop?{x,y,w,h} playbackRate?`           |
| `scenes`  | ordered array; every scene has `id`, `durationInFrames`; feature scenes reference `media` by key and `captions`/`useCases`/`stages` by index and carry `mediaCols`, `textCols`, `enter`, `mediaAlign` |
| `posterFrame` | frame used by the `Poster` composition                                                                          |

Grid positions are `{ start, span }` in 1-based columns. Crops are fractions of
the source (`x,y,w,h` in 0–1) and are applied as a rectangular window with a
uniform scale — never a skew or non-uniform stretch. `sourceWidth/Height` are
needed so panels can be sized before the asset loads.

Fonts: `brand.fontFamily` defaults to `"NB International Pro", "Inter", …`.
Inter is loaded through `@remotion/google-fonts/Inter` as the fallback and
Geist Mono through `@remotion/google-fonts/GeistMono`. If you have the licensed
NB International Pro files, drop them into `launch-videos/assets/fonts/` and set

```json
"brandFontFiles": { "regular": "fonts/NBInternationalPro-Regular.woff2", "medium": "fonts/NBInternationalPro-Medium.woff2" }
```

Leaving it `null` (default) skips the `@font-face` rules entirely.

## Swapping in another launch

1. Replace `content` with the new copy (headline, `headlineAccent`, subhead,
   `captions`, `useCases`, `stages`, `cta`, `outroLine`).
2. Point `media` slots at the new recordings/screenshots in
   `launch-videos/assets/`, filling in `sourceWidth/Height`, and optionally
   `startFrom` (trim, in frames) and `crop`.
3. Re-order or re-time `scenes`; each feature scene picks its `media`,
   `caption`, `useCase`, and `stage`. Pick `enter: "expand"` for composed
   screenshot introductions and `enter: "slide"` when moving between
   recordings.
4. Either edit `src/defaults.ts` or pass a JSON props file:
   `npx remotion render Launch out/launch.mp4 --props=./my-launch.json`.

## Decisions made where the brief was open

- Captions run in a 3–4 column text block next to the media rather than under
  it, so the media panel can use the full content height.
- The top rail shows the lockup, feature name, and scene counter; the bottom
  rail shows the workflow stages with the active one in `accent`. Both are
  hidden on the CTA scene, which re-draws them in the dark palette.
- Speed badge (`content.speedBadge`) only appears on a panel whose slot has
  `playbackRate !== 1`; no default slot is sped up, so the badge is off in the
  default render.
- The `result` scene shows the full session screenshot (chat with the recorded
  demo plus the PR pane) instead of a tight crop, so the "PR that shows the
  app working" claim is visible on screen.
- Column hairlines (`grid.showGuides`) are on by default as part of the
  Swiss-grid look; set to `false` for a cleaner frame.
