# 05 — Blueprint

Devin on macOS launch video in the style of an engineering drawing: a drafting sheet with
grid and title block, UI screenshots as exploded isometric layers that assemble into a flat
"screen" where the (animated) screenshot plays, dimension lines and leader callouts drawing
on in electric blue.

1920×1080 · 30 fps · 49.4 s · composition id `Main`.

## Render

```sh
npm install
npx remotion render Main out/video.mp4   # H.264, ~80 s on an M-series Mac
npx remotion studio                       # live preview
npx tsc --noEmit
```

Assets are read from the shared `../../assets` directory (`Config.setPublicDir`) — nothing is
copied into this template. Fonts: Inter (stand-in for NB International Pro) and Geist Mono via
`@remotion/google-fonts`. Colours, type, radii and easings come from `../../assets/tokens.json`.

## Scenes (`src/scenes.ts`)

| # | Scene | Length | What happens |
|---|-------|--------|--------------|
| 01 | Hook | 3.4 s | Rules draw on; "Devin now runs on Mac." |
| 02 | Context | 6.0 s | Schematic iPhone outline, hatched "untested" area, a 20+ min CI dimension line. "Before: QA by hand, or a 20+ minute CI wait." |
| 03 | Build & run | 7.6 s | Exploded plate/screen/annotation layers assemble; session screenshot pushes in, cross-fades to the Simulator thumbnail. Callouts: Executing actions → Simulator run → Ready to merge. |
| 04 | Live Simulator | 7.8 s | Simulator loading → full-screen iPhone; cursor taps through the app. "Devin taps, types and scrolls." |
| 05 | Repro · fix · PR | 7.4 s | Bracket on "12 passed · 3 failed", pan to the PR panel, cursor on Merge. "Re-runs the UI tests. Opens the PR." |
| 06 | Device matrix | 7.4 s | Six-screenshot dark-mode review, cross-fade to iPad acceptance run. "Every size. Dark mode. Every orientation." |
| 07 | Specifications | 5.6 s | Spec table draws row by row: cycle time, platform, security, price, works with. |
| 08 | End card | 3.6 s | Devin lockup inside a drawn plate; "Build, run and test iOS apps in the cloud." |

Scene lengths live in the table in `src/scenes.ts`; everything else (title block sheet
numbers, cross-dissolves, the persistent sheet) derives from it.

## Structure

- `src/components/Sheet.tsx` — grid, border ticks, title block (project / sheet / drawing / scale)
- `src/components/Figure.tsx` — exploded → assembled figure with Ken Burns motion and cross-fades
- `src/components/Annotations.tsx` — `Dimension`, `Leader`, `Brackets`
- `src/components/Draw.tsx` — path draw-on primitives (`useDraw`, `DrawPath`, `DrawRect`)
- `src/components/Cursor.tsx` — eased cursor travel with click rings
- `src/scenes/*` — one component per scene, wrapped in `Shell` (a `Sequence` + dissolve)
