# 15 — Terminal-First Cinema

A reusable 16:9 Devin launch video that borrows the rhythm of a well-designed command line:
restrained typography, a single precise caret, and deliberate line-by-line progression. Every
statement is typed on Devin paper (`#F7F6F5`) in the brand sans; once a line is complete it
settles into a small mono section label, a Devin-blue baseline extends underneath it, and that
baseline expands into the actual product footage. The video finishes on the delivered PR, then a
minimal lockup + CTA.

Nothing terminal-like is ever drawn *inside* the product. The supplied recordings contain no
terminal activity, so all terminal-inspired text (typed statements, `Request 01/05` counters,
mono labels) lives outside the footage as editorial captions. No hacker imagery, no cascading
code, no green-on-black, no fake logs, no simulated test output — the footage is shown
pixel-preserved (crop + scale only).

## Scenes (default: 1350 frames / 45 s @ 30 fps)

| # | id | frames | shows |
|---|----|--------|-------|
| 1 | `open` | 150 | Typed eyebrow → headline (`Mac` set in Devin blue) → subhead, blinking caret. |
| 2 | `pick` | 195 | Caption 0 types, settles into `Request 01/05`; baseline expands into `screenshots/devin-web-4.png` cropped to the macOS machine picker. |
| 3 | `work` | 240 | Caption 1 → `Build 02/05`; `recordings/devin-working-4.mp4` (Devin session working, live desktop pane). |
| 4 | `simulator` | 240 | Caption 2 → `Run & test 03/05`; `recordings/androidios.mp4` cropped to the iPhone Simulator. |
| 5 | `verify` | 195 | Caption 4 → `Verify 04/05`; `recordings/devin-testing-2.mp4` from frame 1140 (Devin testing a flow). |
| 6 | `result` | 210 | Caption 6 → `PR 05/05`; `screenshots/devin-web-12.png` — the delivered PR with embedded demo videos, "Ready to merge". |
| 7 | `outro` | 120 | Devin lockup, typed outro line, CTA button + URL, resting caret. |

Duration is the sum of `scenes[].durationInFrames` (computed in `calculateMetadata`), so adding,
removing or retiming scenes changes the composition length automatically.

## Editable props (`src/schema.ts`, defaults in `src/defaults.ts`)

- `brand` — `paper`, `surface`, `line`, `ink`, `inkMuted`, `inkSubtle`, `accent`, `black`, `white`,
  `fontFamily`, `monoFontFamily`, `logoLight`, `logoDark`. Inter and Geist Mono are loaded via
  `@remotion/google-fonts` as deterministic fallbacks for NB International Pro / Geist Mono; the
  actual families used are whatever you put in `brand.fontFamily` / `brand.monoFontFamily`.
- `content` — `featureName`, `eyebrow`, `headline`, `headlineAccentWord`, `subhead`, `captions[]`,
  `useCases[]`, `stages[]`, `cta {label,url}`, `outroLine`, `speedBadge`. Defaults are verbatim
  from `brief/launch-mac-vm.md`.
- `media` — named slots `{ src, kind, startFrom?, crop?, playbackRate?, sourceAspect? }`. `src` is
  a path under `launch-videos/assets/` (served via `Config.setPublicDir("../../assets")`).
  `crop` is in fractions of the source frame. `sourceAspect` is resolved automatically from the
  file in `calculateMetadata`; set it only to override.
- `scenes[]` — ordered. `open` / `outro` take only `durationInFrames`; `demo` scenes take
  `captionIndex` (into `content.captions`), `label` (what the finished line settles into),
  `media` (slot key) and `captionPlacement` (`top` | `bottom`).
- `cursor` — `glyph` (`block` | `bar` | `underscore`), `blinkFrames`, `charsPerFrame`, `color`
  (`accent` | `ink`).
- `layout` — `safeMargin`, `statementSize`, `labelSize`, `frameRadius`.
- `timing` — `holdAfterType`, `settle`, `rule`, `expand`, `exitFade` (all frames). These drive the
  type → settle → baseline → expand → hold → fade beat in every demo scene.

## Swapping in a different launch

1. Edit `src/defaults.ts` (or pass `--props=props.json` to `remotion render` / `remotion still`)
   with the new `content` copy, and point `media` slots at new files in `launch-videos/assets/`.
2. Adjust `scenes[]`: pick which caption each demo uses, what label it settles into, and its
   length. Keep result holds ≥ 2.5 s (the last ~75 frames of a demo scene are the hold).
3. `npm run dev` to preview in Remotion Studio, `npm run render` → `out/launch.mp4`,
   `npm run still` → `out/poster.png` (frame 720 by default).

## Scripts

```
npm install
npm run typecheck
npm run lint
npm run render   # out/launch.mp4
npm run still    # out/poster.png
```

If Remotion's headless browser is missing: `npx remotion browser ensure`.

## Decisions

- The brief's captions 3 and 5 (simulator tab / sizes & dark mode) are not used by default
  because no supplied footage shows them specifically; they remain in `content.captions` for
  reuse.
- `speedBadge` and `useCases` are exposed but not rendered — the direction calls for
  restraint, and the speed claim is already carried by caption 6.
- The pick screenshot is cropped to the picker region so the machine dropdown stays legible at
  frame scale; the result PR screenshot is shown almost whole so the embedded demo videos and
  "Ready to merge" state read together.
