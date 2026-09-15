# 18 — Annotated Paper

Devin on macOS / native iOS launch video, styled as a printed design review:
product screenshots sit as white sheets on a neutral desk, and a reviewer marks them
up in electric-blue ink — circles, arrows, highlighter, ticks and sticky notes drawn on
with SVG stroke-dash animation. Screenshots move (push-ins, pans, cross-fades,
cursor/typing overlays) so nothing sits still for more than ~1.5s.

- Composition `Main`, 1920×1080, 30fps, 49s (1470 frames), H.264.
- Assets are read from the shared `../../assets` folder via `staticFile(...)` (nothing is copied).
- Fonts: Inter (sans stand-in for NB International Pro), Geist Mono (labels), Caveat (handwriting) via `@remotion/google-fonts`.
- Tokens from `../../assets/tokens.json` (colours, radii, shadows, tracking, easings).

## Render

```bash
npm install
npm run typecheck          # tsc --noEmit
npm run render             # -> out/video.mp4
npm run studio             # Remotion Studio for retiming
```

Scene durations live in `src/scenes.ts`; every scene is a `<Sequence>` in `src/Main.tsx`.

## Scenes

| # | Scene | Time | What happens |
|---|-------|------|--------------|
| 1 | `Hook` | 0.0–3.5s | Cover sheet: "Devin now runs on Mac." with a hand-drawn underline on *Mac*. |
| 2 | `Context` | 3.5–10s | Before/Now narration. Fig. 01 (new session) with the prompt typing on; the macOS platform chip is circled, sticky note "hosted macOS — same VM, new OS". |
| 3 | `BuildRun` | 10–17s | Feature 01. Fig. 02: cursor picks macOS in the platform picker, cross-fade to the running session (build → run → test log highlighted, "Executing actions" circled). |
| 4 | `LiveSimulator` | 17–25s | Feature 02. Fig. 03: live iPhone Simulator tab, boxed in ink; cursor taps, typing overlay, cross-fade to the next screen. Label "live — watch, or tap along". |
| 5 | `ReproFixPr` | 25–32s | Feature 03. Fig. 04: test counts circled, pan to the PR panel, "Ready to merge" circled with an arrow; stickies "repro'd in the Simulator" / "tests green → PR open". |
| 6 | `EveryScreen` | 32–39s | Feature 04. Fig. 05: dark six-device matrix ticked cell by cell, cross-fade to the iPad Pro acceptance run. |
| 7 | `Outcome` | 39–45s | Review-notes sheet: three outcome lines ticked in sequence. |
| 8 | `EndCard` | 45–49s | Devin lockup on the last sheet, "Build, run and test iOS apps in the cloud.", devin.ai. |

## Structure

- `src/components/Paper.tsx` — printed sheet (shadow, caption row, entrance).
- `src/components/Figure.tsx` — aspect-preserving screenshot with crop + camera move; children get normalised figure coordinates.
- `src/components/Ink.tsx` — `Circle`, `Arrow`, `Underline`, `Highlight`, `Check`, `Box` draw-on primitives.
- `src/components/Sticky.tsx`, `Cursor.tsx`, `Typing.tsx`, `Narration.tsx` — stickies/handwriting, cursor overlay, typing overlay, on-screen narration.
