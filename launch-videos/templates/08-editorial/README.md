# 08 · Editorial

Devin on macOS / native iOS launch video in the style of a print magazine
(Monocle, Kinfolk): Fraunces serif headlines, Geist Mono small-caps metadata,
120px margins, page numbers, figures with captions, and page-turn wipes.

- Composition `Main` · 1920×1080 · 30fps · 1345 frames (≈44.8s) · H.264
- Shared assets are read from `../../assets` via `Config.setPublicDir`
  (`staticFile("screens/…")`, `staticFile("brand/…")`); nothing is copied here.

## Render

```sh
npm install
npm run render          # → out/video.mp4
npm run typecheck       # tsc --noEmit
npm run dev             # Remotion Studio
node scripts/stills.mjs # 8 evenly spaced PNGs → out/frames/ (or pass frame numbers)
```

## Structure

| File | Purpose |
| --- | --- |
| `src/scenes.ts` | Timing table: per-scene durations, page numbers, `TURN` overlap. Retime here. |
| `src/Main.tsx` | `TransitionSeries` mapping scenes → components with the page-turn wipe. |
| `src/transitions/pageTurn.tsx` | Horizontal clip-path wipe with a soft paper shadow on the leading edge. |
| `src/components/Page.tsx` | Paper/dark page chrome: hairlines, issue label, section, page number. |
| `src/components/Type.tsx` | `Reveal`, `Kicker`, `Headline`, `Caption`. |
| `src/components/Figure.tsx` | Screenshot as photograph: crop, cross-fade plates, slow push, pan. |
| `src/components/Cursor.tsx` | Pointer overlay in screenshot coordinates (tracks the figure's crop/push). |
| `src/tokens.ts` / `src/fonts.ts` | Values from `assets/tokens.json`; Fraunces, Inter, Geist Mono via `@remotion/google-fonts`. |

## Scenes

| P. | Scene | Dur. | What happens |
| --- | --- | --- | --- |
| 01 | `Hook` | 4.0s | Devin mark, issue kicker, "Devin now runs on Mac." |
| 02 | `Context` | 6.5s | "iOS teams QA'd the app by hand, or waited 20+ minutes for CI." cross-fades to "No coding agent could build, run and tap through an iPhone app." |
| 03 | `Choose` | 7.5s | Feature 01. Platform picker (`devin-web-4`), cursor selects macOS, cross-fade to the session planning view (`devin-web-1` → `devin-web-13`). |
| 04 | `Live` | 7.0s | Feature 02. Wide session with the iPhone Simulator (`devin-desktop-9`), slow push-in, cursor taps the Simulator. |
| 05 | `Fix` | 7.0s | Feature 03. Simulator checks (`devin-web-10`) cross-fade to the PR view (`devin-web-9`). |
| 06 | `Matrix` | 7.0s | Feature 04. Dark six-iPhone review grid (`devin-web-17`) beside the iPad acceptance flow (`devin-web-19`). |
| 07 | `Outcome` | 6.5s | Ledger of the four outcome lines from the brief. |
| 08 | `End` | 4.0s | Devin lockup, "Build, run and test iOS apps in the cloud." |

Each transition overlaps 0.65s (`TURN`), so total = Σ durations − 7 × TURN.

## Motion rules

- Entrances: ease-out `[0.16, 1, 0.3, 1]`; moves and cross-fades: ease-in-out
  `[0.65, 0, 0.35, 1]`. No springs.
- At most two motion types per scene (e.g. push-in + cursor, or cross-fade + reveal).
- No screenshot sits still: every figure has a slow push-in or pan for its whole life.
