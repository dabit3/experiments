# 01 — Keynote Minimal

Devin launch video (macOS / native iOS) in the Apple-product-page register: near-white paper
background, the product UI floating on a soft shadow, slow 3–5% push-ins, one Medium-weight
headline at a time. Transitions are crossfades and scale only. Every feature has a beat where
only the UI is on screen.

1920×1080 · 30 fps · ~46.6 s · H.264

## Render

```bash
npm install
npx remotion render Main out/video.mp4   # or: npm run render
npx tsc --noEmit                         # or: npm run typecheck
npx remotion studio                      # or: npm run dev
```

Shared assets (screenshots, brand lockups, `tokens.json`) are served from `../../assets` via
`Config.setPublicDir("../../assets")` in `remotion.config.ts` and referenced with
`staticFile("screens/…")` / `staticFile("brand/…")`. Nothing is copied into this directory.

## Scenes

Timing lives in `src/scenes.ts`; scenes overlap by a 0.6 s crossfade.

| # | Scene | Length | What happens |
|---|-------|--------|--------------|
| 1 | `Hook` | 3.4 s | "Devin now runs on Mac." on paper. |
| 2 | `Context` | 6.2 s | Two problem lines, one at a time: manual QA / 20+ min CI, then "no coding agent could build, run and tap through an iPhone app." |
| 3 | `FeatureMac` | 8.6 s | New-session home → cursor moves to the macOS platform picker (web-1 → web-4) → the card crossfades to a live session with the iPhone Simulator running (desktop-9). Headlines: "Choose macOS. Start a session." / "Devin builds and runs the app in the iOS Simulator." |
| 4 | `FeatureSimulator` | 7.4 s | Full-screen Simulator player, loading → typing state (web-11 → web-10), slow push-in. "Watch it tap, type and scroll — like a person." then silence. |
| 5 | `FeaturePr` | 7.2 s | Session with Simulator thumbnail and open PR (web-9), slow pan toward the PR. "It reproduces the bug, fixes it, re-runs the tests and opens a PR." then silence. |
| 6 | `FeatureMatrix` | 7.0 s | Dark review panel with six iPhone screenshots (web-17). "Every size. Dark mode. Every orientation. Compared pixel for pixel." then silence. |
| 7 | `Metrics` | 7.0 s | Three outcome lines in sequence: "Minutes, not 20+ minute CI round-trips." / "The only coding agent with a Mac cloud agent." / "Same security. No price increase." |
| 8 | `EndCard` | 4.0 s | Devin lockup, "Build, run and test iOS apps in the cloud.", `DEVIN.AI`. |

## Structure

- `src/tokens.ts` — reads `../../assets/tokens.json`; exposes colors, type, radii, shadows and `Easing.bezier` curves.
- `src/fonts.ts` — Inter (sans) and Geist Mono via `@remotion/google-fonts`, loaded at module level.
- `src/components/` — `Headline` (one line at a time, rise + fade), `Screen` (floating screenshot with push-in / pan / layer crossfade), `Cursor` (pointer + click ring), `Fade` (scene crossfade).
- `src/scenes/` — one component per scene, mounted in `<Sequence>`s in `src/Main.tsx`.
