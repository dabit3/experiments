# 07 · Bento Reveal

Devin on macOS / native iOS launch video in the Apple bento-grid idiom. Five rounded tiles build in from the center; each feature tile expands to full frame for an animated screenshot moment, collapses back, and the finished grid flips into outcome statements before the end card.

- Composition `Main`, 1920×1080, 30 fps, 1449 frames (48.3 s), H.264.
- Assets are read from `../../assets` via `Config.setPublicDir` — nothing is copied here.
- Fonts: Inter (sans) and Geist Mono (mono), weights 400/500 only, via `@remotion/google-fonts`.

## Render

```sh
npm install
npx remotion render Main out/video.mp4   # or: npm run render
npx remotion studio                      # or: npm run dev
npx tsc --noEmit                         # or: npm run typecheck
```

## Scenes (`src/scenes.ts`)

| # | Scene | Time | What happens |
|---|-------|------|--------------|
| 1 | Hook | 0.0–3.5 s | `NEW · MACOS AND IOS` eyebrow + “Devin now runs on Mac.” fade up on paper. |
| 2 | Context | 3.5–9.0 s | Two problem lines, one at a time: QA by hand / 20+ min CI; no agent could tap through an iPhone app. |
| 3 | Bento build | 9.0–11.5 s | Five tiles (Build & run, Live Simulator, Bug → PR, Every device, Devin mark) scale/fade in, staggered from the center. |
| 4 | Feature 01 · Build & run | 11.5–18.7 s | Tile expands to full frame: session chat (web‑13) → macOS desktop with Xcode/Simulator (desktop‑9), slow push-in, cross-fade. Collapses back. |
| 5 | Feature 02 · Live Simulator | 18.7–25.9 s | Simulator tab (web‑10 → web‑11) with an animated cursor that clicks Send; “You can watch — and tap too.” |
| 6 | Feature 03 · Bug → PR | 25.9–33.1 s | Simulator test results (web‑9) → PR view (web‑8). |
| 7 | Feature 04 · Every device | 33.1–40.3 s | Device screenshot matrix (web‑17) panning down → iPad PR review (web‑19). |
| 8 | Summary → Outcomes | 40.3–45.3 s | Full grid holds, then each tile cross-fades to an outcome: Speed, Platform, Security, Price. |
| 9 | End card | 44.8–48.3 s | Devin tile expands to full frame (dark), mark cross-fades into the horizontal lockup + “Build, run and test iOS apps in the cloud.” |

Retime by editing `timing` in `src/scenes.ts`; all offsets derive from it.

## Structure

- `src/Main.tsx` — `<Sequence>` per scene.
- `src/scenes/Bento.tsx` — tile state machine (build-in, expand/collapse, outcome flip, brand expand).
- `src/layout.ts` — grid geometry; `src/content.ts` — copy, screenshot choices, zoom/focus/cursor keyframes.
- `src/components/Screenshot.tsx` — aspect-preserving cover crop with animated zoom/focus; `Expanded.tsx`, `TileContent.tsx`, `Cursor.tsx`.
- `src/tokens.ts` — reads `../../assets/tokens.json` (colors, radii, shadows, type, easings).
