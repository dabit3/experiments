# 10 — Frosted Depth

Devin macOS / native-iOS launch video in a glassmorphism (visionOS) language: frosted-glass cards
with blur-behind, layered at three depth levels on a slow parallax. Animated screenshots play inside
the front layer. Light source is top-left in every scene; the background is a soft, dark, out-of-focus
gradient with a single electric-blue bloom.

Composition `Main` — 1920x1080, 30 fps, 1422 frames (47.4 s), H.264.

## Render

```sh
npm install
npx remotion render Main out/video.mp4   # or: npm run render
npx remotion studio                      # live preview
npx tsc --noEmit                         # typecheck
```

Assets are read from the shared `launch-videos/assets/` directory via `Config.setPublicDir("../../assets")`
in `remotion.config.ts`; nothing is copied into this template. Design tokens come from
`launch-videos/assets/tokens.json` (see `src/tokens.ts`). Fonts (Inter, Geist Mono) load through
`@remotion/google-fonts` at module level in `src/fonts.ts`.

## Scenes

Timings live in `src/scenes.ts`. Each scene is a `<Sequence>`; consecutive scenes overlap by
`TRANSITION` (0.5 s) and cross-dissolve.

| # | Scene | Length | What happens |
|---|-------|--------|--------------|
| 1 | `hook` | 3.6 s | Devin mark in a small glass tile; "Devin now runs on Mac." rises in. |
| 2 | `context` | 6.2 s | "Before, iOS teams QA'd the app by hand — or waited 20+ minutes for CI." with a ticking `CI RUN` timer pill, then "No coding agent could build, run and tap through an iPhone app on its own." |
| 3 | `featureSession` | 7.4 s | Front card: empty prompt → typed request → platform picker (cursor selects macOS) → simulator loading → Afterhours Maze running. Narration: "Start a session on macOS." / "Devin builds and runs the app in the iOS Simulator." |
| 4 | `featureSimulator` | 6.6 s | Live iPhone Simulator: cursor taps the key field, a `typing…` chip appears, then a tap ripple on Send with a slow push-in. Narration: "A live iPhone Simulator, inside the session." / "Devin taps, types and scrolls — you can too." |
| 5 | `featureBugfix` | 7.0 s | Session transcript panning up → PR view. Narration: "Reproduces the bug. Fixes it. Re-runs the UI tests." / "Then opens the PR." |
| 6 | `featureMatrix` | 7.0 s | Dark review panel with six iPhone screenshots → iPad Pro simulator. Narration: "Checks iPhone and iPad sizes, dark mode and orientations." / "Compares every screenshot pixel for pixel." |
| 7 | `outcome` | 5.6 s | Three frosted metric cards (Speed, Platform, Cost & security) stagger in; supporting line about child sessions, Declarative Repo Setup, the API and automations. |
| 8 | `endCard` | 4.0 s | White Devin lockup in a glass tile, "Build, run and test iOS apps in the cloud.", `devin.ai`. |

Between two feature scenes the outgoing card holds at full opacity while the incoming card dissolves
over it, so the screen "recording" appears to cut inside one persistent front pane.

## Structure

```
src/
  Root.tsx / Main.tsx        composition + scene sequencing
  scenes.ts                  timing table (retime here)
  tokens.ts / fonts.ts       shared design tokens, Google Fonts
  lib/motion.ts              enter / exit / move / parallax helpers (token easings)
  components/                Background, Glass, DepthLayers, ScreenCard, Narration, Overlays
  scenes/                    Hook, Context, Feature (+ features.tsx data), Outcome, EndCard
```
