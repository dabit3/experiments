# 17 · Agent Graph

Devin launch video (macOS / native iOS) told as an animated node graph. The
agent's seven-step plan lights up node by node; each active node grows into an
animated product screenshot of that step. 1920×1080 · 30 fps · 47 s.

## Render

```bash
npm install
npx remotion render Main out/video.mp4   # H.264, ~47 s
npx remotion studio                      # live preview
npx tsc --noEmit                         # typecheck
```

Shared assets are read from `../../assets` (`remotion.config.ts` →
`Config.setPublicDir`) via `staticFile("screens/…")` / `staticFile("brand/…")`;
nothing is copied into this directory.

## Scenes

Timings live in `src/scenes.ts` (`ORDER` table, seconds). Everything else is
derived from it, including when each graph node activates (`STEP_ACTIVATION`).

| # | Scene | Length | What happens |
|---|-------|--------|--------------|
| 1 | `hook` | 3.5 s | "Devin now runs on Mac." centered on the dark stage. |
| 2 | `context` | 5.5 s | Two "Before" lines: hand-QA'd iOS apps / 20+ min CI; no agent could build, run and tap through an iPhone app. |
| 3 | `plan` | 4.0 s | The seven-node graph draws in (chain edges + two dependency arcs), monospace labels, all idle. |
| 4 | `build` | 6.5 s | Graph flattens into a rail along the bottom. **Clone repo** lights, a screenshot card grows out of the node (session view), then **Build in Xcode** (editor). |
| 5 | `simulator` | 7.0 s | **Boot Simulator** (loading iPhone 17 Pro) → **Reproduce bug** (feature-check player, failing test). |
| 6 | `fix` | 6.0 s | **Fix** (session with `@MainActor` fix, BUILD SUCCEEDED) → **Run UI tests** (wide Simulator view). |
| 7 | `pr` | 5.5 s | **Open PR** — Devin session with the PR panel and Simulator recording. |
| 8 | `outcome` | 5.5 s | Rail expands back into the full graph, every node checked. "Minutes, not 20+ minute CI round-trips." → "The only coding agent with a Mac cloud agent." |
| 9 | `end` | 3.5 s | Devin lockup, "Build, run and test iOS apps in the cloud.", devin.ai |

Per scene: one entrance (ease-out) and one move (ease-in-out), curves from
`tokens.json`. Screenshots never sit still — each shot has a slow push-in and
sequential shots dissolve; a typed command line narrates each step.

## Files

- `src/scenes.ts` — timing table, step list, activation frames
- `src/Graph.tsx` — node/edge graph; hero ⇄ rail layout morph, pulses, checks
- `src/FeatureScene.tsx` — step label / headline / typed log + screenshot card
- `src/Main.tsx` — hook, context, plan, outcome, end scenes and the composition
- `src/components.tsx` — `Heading`, `Label`, `Typed`, `ScreenCard`, `Seq`
- `src/theme.ts` — tokens → colors, type, radii, shadows, easing; fonts (Inter, Geist Mono)
