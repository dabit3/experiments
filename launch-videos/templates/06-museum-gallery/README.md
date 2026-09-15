# 06 — Contemporary Museum Gallery

A reusable 16:9 Remotion launch template that presents the product as a small
collection of works hung on a quiet gallery wall. Three large, front-facing
display surfaces each show a stage or capability: a composed screenshot first,
a slow dolly toward it, then a crossfade into the matching screen recording as
the display expands to fill most of the frame. A concise exhibition-style label
sits beside each display. The camera moves laterally along the wall between
exhibits; the closing display shows the delivered result before a deliberate
cut to a minimal dark CTA.

- 1920×1080, 30 fps, 45 s by default (duration is derived from `scenes`)
- Composition id: `Launch`
- No audio, single accent color, real UI only (`staticFile()` from `../../assets`)

## Commands

```sh
npm install            # Node 20+
npm run dev            # Remotion Studio
npm run typecheck
npm run lint
npm run render         # out/launch.mp4
npm run still          # out/poster.png (frame 670, mid-demo on exhibit II)
```

If the headless browser download fails during install, run `npx remotion browser ensure`.

## Scene table (default props)

| # | Scene id    | Kind    | Frames | Time          | What's on the wall                                                                                     |
|---|-------------|---------|--------|---------------|--------------------------------------------------------------------------------------------------------|
| 1 | `title`     | title   | 120    | 0:00 – 0:04   | Devin lockup, eyebrow, headline (`Mac` in accent), subhead, stage route                                |
| 2 | `exhibit-1` | exhibit | 300    | 0:04 – 0:14   | **I · Pick a Mac** — `devin-web-4.png` → `agent-selector-cloud.mp4`. Label: "Start a native project" + caption 1 |
| 3 | `exhibit-2` | exhibit | 315    | 0:14 – 0:24.5 | **II · Run & test** — `devin-web-9.png` → `androidios.mp4` (cropped to the player window). Label: "QA before shipping" + caption 3 |
| 4 | `exhibit-3` | exhibit | 315    | 0:24.5 – 0:35 | **III · Verify** — `devin-web-11.png` → `devin-testing-2.mp4`. Label: "Reproduce & fix a bug" + caption 5 |
| 5 | `result`    | exhibit | 180    | 0:35 – 0:41   | **IV · PR** — `devin-web-12.png` (Starcup PR, "Ready to merge") held as the delivered result, no recording |
| 6 | `cta`       | cta     | 120    | 0:41 – 0:45   | Dark card: Devin lockup, outro line, CTA button, URL                                                   |

Inside each exhibit (local frames, default `gallery` values):

| Local frame          | Beat                                                                   |
|----------------------|------------------------------------------------------------------------|
| 0 – `panFrames`      | Camera arrives laterally from the previous exhibit; label fades in     |
| 0 – `revealAt`       | Screenshot as the subject; slow dolly from `displayWidthStill` → `displayWidthDolly` |
| `revealAt` – `+crossfadeFrames` | Recording crossfades over the screenshot                    |
| `revealAt` – `+expandFrames`    | Display expands to `displayWidthMotion`                     |
| rest                 | Recording plays, front-facing, product occupies most of the frame      |

The result display holds for 180 frames (≥ 2.5 s requirement) and the CTA is a
deliberate cut (`cutFrames` fade) rather than a lateral move.

## Editable props (`src/schema.ts`)

All props are validated with Zod and editable in Remotion Studio.

| Group     | Keys                                                                                                                     |
|-----------|--------------------------------------------------------------------------------------------------------------------------|
| `brand`   | `paper`, `surface`, `surfaceAlt`, `line`, `ink`, `inkMuted`, `inkSubtle`, `accent`, `black`, `blackRaised`, `white`, `fontFamily`, `monoFontFamily`, `logoLight`, `logoDark` |
| `content` | `featureName`, `eyebrow`, `headline`, `headlineAccentWord`, `subhead`, `captions[]`, `useCases[]`, `stages[]`, `cta.{label,url}`, `outroLine`, `speedBadge` |
| `media`   | Named slots → `{ src, kind: image\|video, width, height, startFrom?, crop?, playbackRate? }`. `crop` is fractional (0–1) and pixel-preserving. |
| `gallery` | `safeMargin`, `floorHeight`, `displayWidthStill`, `displayWidthDolly`, `displayWidthMotion`, `displayCenterY`, `displayRadius`, `displayShadow`, `labelWidth`, `labelGap`, `panFrames`, `expandFrames`, `crossfadeFrames`, `cutFrames` |
| `scenes`  | Ordered list of `title` / `exhibit` / `cta` scenes. Exhibits reference `media` slots by name (`still`, optional `motion`) and `content` arrays by index (`stageIndex`, `useCaseIndex`, `captionIndex`); `revealAt` is the local frame of the screenshot→recording reveal; `isResult` marks the delivered-result display. |

Font families are plain strings so they can be swapped without touching code.
`src/fonts.ts` loads Inter (via `@remotion/google-fonts/Inter`) as the
NB International Pro fallback and Geist Mono for mono. If licensed
`NBInternationalPro-{Regular,Medium}.woff2` files are dropped into
`launch-videos/assets/fonts/`, they are picked up automatically; otherwise the
404s for those files are harmless and Inter is used.

## Swapping launches

1. Copy `src/defaults.ts` (or pass `--props=launch.json` to `remotion render`).
2. Replace `content` with the new brief's copy verbatim (headline, subhead,
   captions, use cases, stages, CTA, outro). Keep claims to the approved list.
3. Point `media` slots at the new brief's footage map. Use the real source pixel
   size for `width`/`height`; add a fractional `crop` only to trim a recording to
   its player window (never to reframe or distort the UI).
4. Adjust `scenes`: any number of exhibits, in any order. Reference slots by
   name and copy by index; change `durationInFrames` freely — the composition
   length follows automatically. Keep at least one `isResult` exhibit before the
   CTA.
5. Re-run `npm run typecheck && npm run lint && npm run render`, then inspect
   ~10 frames from `out/launch.mp4` for readability.

## Choices made where the brief was open

- **Lateral moves vs. cuts.** Exhibits are laid out on one long virtual wall and
  the camera pans 24 frames between them; the CTA is a deliberate cut so the dark
  card doesn't slide in from a paper wall.
- **Result exhibit.** The asset index lists `devin-web-13.png` as the Starcup PR,
  but the file actually shows the Reel Horizon session chat; `devin-web-12.png`
  is the one with the "Ready to merge" PR, so it is used as the delivered result.
- **Simulator recording.** `androidios.mp4` is a screen capture of a Mac desktop
  with the recording player in a window; it is cropped to that window so the
  wallpaper doesn't compete with the UI. The crop is a prop and can be removed.
- **Label copy.** Labels combine a stage (`content.stages`), a use case
  (`content.useCases`) and a caption (`content.captions`) plus a mono metadata
  line. No claims beyond the brief are added.
- **Floor band.** The only "architecture" is a paper wall, a slightly darker
  floor band and a hairline where they meet — no furniture, visitors or scenery.
