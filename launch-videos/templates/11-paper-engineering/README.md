# Template 11 — Precision Paper Engineering

A reusable 16:9 Devin launch video built from layered matte paper surfaces.
UI screenshots and recordings sit perfectly flat on presentation plates; all
physical movement (a title sheet sliding away, lifted dividers, folded margins,
sliding sleeves) happens to the *surrounding* paper, never to the interface.
Captions live on a separate, always-left-aligned strip below the stage.

```
npm install
npm run dev        # Remotion Studio
npm run typecheck
npm run lint
npm run render     # out/launch.mp4 (45 s, 1920x1080, 30 fps, no audio)
npm run still      # out/poster.png (frame 690)
```

Media resolves through `Config.setPublicDir("../../assets")`, so every `src`
in `media` is a path relative to `launch-videos/assets/`.

## Scene table (default "Devin on Mac" launch)

| # | id          | kind  | frames | s     | media                              | reveal | caption / stage             |
|---|-------------|-------|--------|-------|------------------------------------|--------|-----------------------------|
| 1 | `title`     | title | 105    | 3.5   | `hero` (devin-web-1.png)           | slides left | idle strip: NEW · Devin on Mac |
| 2 | `pick`      | demo  | 105    | 3.5   | `hero`                             | cut    | 1 · Request                 |
| 3 | `pick-menu` | demo  | 120    | 4.0   | `pick` (devin-web-4.png)           | lift   | — · Request                 |
| 4 | `work`      | demo  | 240    | 8.0   | `work` (devin-working-4.mp4)       | sleeve | 2 · Build                   |
| 5 | `simulator` | demo  | 240    | 8.0   | `simulator` (androidios.mp4, iPhone crop) | fold | 3 · Run & test        |
| 6 | `live`      | demo  | 210    | 7.0   | `live` (devin-web-11.png)          | lift   | 4 · Verify                  |
| 7 | `result`    | demo  | 210    | 7.0   | `result` (devin-web-12.png)        | sleeve | 7 · PR                      |
| 8 | `outro`     | outro | 120    | 4.0   | `result` (kept on a plate)         | —      | strip dismisses; CTA        |

Total 1350 frames = 45 s. Duration is derived from `scenes[]` via
`calculateMetadata`, so adding/removing/retiming scenes changes the video length.

### How each reveal works

- **title** — an opaque paper sheet carrying eyebrow/headline/subhead sits over
  the hero plate and slides off (`exit: "left" | "right" | "up"`) during the
  last `motion.titleExit` frames.
- **cut** — no divider; the next plate is simply there.
- **lift** — a matte divider rises out of the slot below the stage, covers the
  old plate, then lifts up out of the top slot to uncover the new one.
- **sleeve** — the same sheet slides in from the right and out to the left.
- **fold** — a folded margin: the sheet slides up over the stage, then hinges
  open around its bottom edge (`rotateX` on the *paper* only) and lifts away.
- **outro** — the result plate moves (ease-in-out) to the right column, the
  caption strip slides down out of frame, and the outro line + CTA settle on
  the left.

Every divider carries a small mono label (`01 — REQUEST`) built from the
target scene's `stage`; omit `stage` on a scene to drop the label.

## Editable props (`src/schema.ts`, defaults in `src/defaults.ts`)

| group     | keys                                                                                        |
|-----------|---------------------------------------------------------------------------------------------|
| `brand`   | `paper surface surfaceAlt line ink inkMuted inkSubtle accent black white`, `fontFamily`, `monoFontFamily`, `logoLight`, `logoDark`, optional `customFontFiles { regular, medium }` (woff2 paths under assets/) |
| `content` | `featureName eyebrow headline accentWord subhead captions[] useCases[] stages[] cta{label,url} outroLine speedBadge` |
| `media`   | record of named slots: `{ src, kind: "image" \| "video", startFrom?, playbackRate?, aspect?, crop?{x,y,w,h} }` — `crop` is fractional and applied with `overflow: hidden` + uniform scale only, never a skew |
| `scenes`  | ordered array of `title` / `demo` / `outro` scenes; `demo` has `media`, `reveal`, optional `caption` (1-based index into `content.captions`) and `stage` (1-based index into `content.stages`) |
| `layout`  | `margin headerHeight captionStripHeight gap platePadding plateRadius mediaRadius outroPlateWidth` |
| `motion`  | frame counts: `titleExit reveal caption layoutMove` (all ease-out / ease-in-out, no spring) |
| `surface` | `shadowStrength` (0–2, multiplies the brand plate shadow), `texture` (0–1, grain on the paper background only) |

All of these are exposed in Remotion Studio through the Zod schema, and can be
overridden with `--props` on the CLI.

## Swapping in another launch

1. Replace `content` with the new launch's copy (feature name, headline, the
   `accentWord` to tint, subhead, captions in order, stage labels, CTA, outro).
2. Point `media` slots at the new footage. Screenshots: `kind: "image"` with the
   real pixel `aspect`. Recordings: `kind: "video"`, optional `startFrom`
   (frames to trim from the head) and `playbackRate` (> 1 shows the speed badge).
   Use `crop` to isolate one window of a wide recording — it only masks and
   scales, it never distorts.
3. Rewrite `scenes` — keep a `title` first and an `outro` last; any number of
   `demo` scenes in between. Give recordings the longest durations so the
   footage plays large and stable. The `caption` index chooses which caption
   line is on the strip; leave it out to keep the previous caption.
4. Adjust `brand` only if the launch needs different tokens; `fontFamily`
   defaults to NB International Pro → Inter (loaded via `@remotion/google-fonts`).

## Choices made where the brief was open

- Captions 5 and 6 are not used by default: a 45 s cut with five stage labels
  reads best with one caption per stage. They stay in `content.captions` and can
  be assigned to any scene.
- `androidios.mp4` is cropped to the iPhone Simulator window because the brief
  forbids showing Android; the crop is a rectangular mask, not a redraw.
- Pixel `aspect` is set per screenshot so plates fit exactly before the image
  decodes — no layout jump on the first frame.
- Texture is a very faint SVG grain on the background paper only (default 0.6);
  set `surface.texture` to 0 for perfectly flat paper.
- No "3x" badge appears by default because no recording is sped up; set
  `playbackRate` above 1 on a slot to show `content.speedBadge`.
