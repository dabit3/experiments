# 02 — Midnight Glow

Devin launch video template (macOS / native iOS launch). Near-black background,
a single electric-blue radial glow behind the UI, 1px hairline frames around
screenshots, faint text bloom, and pill callouts connected by a hairline to the
UI element they describe. 1920×1080 · 30 fps · H.264 · 49 s.

## Render

```bash
cd launch-videos/templates/02-midnight-glow
npm install
npx remotion render Main out/video.mp4   # or: npm run render
npx remotion studio                      # live preview
npx tsc --noEmit                         # typecheck
```

Assets are read from `../../assets` (set in `remotion.config.ts` via
`Config.setPublicDir`) and referenced with `staticFile("screens/…")` and
`staticFile("brand/…")`. Nothing is copied into this directory.

## Structure

```
src/
  index.ts           registerRoot
  Root.tsx           <Composition id="Main"> + the <Sequence> stack
  scenes.ts          timing table — retime here
  SceneComponents.tsx one component per scene
  components.tsx     Backdrop, Headline, Label, ScreenFrame, Pill, Cursor
  tokens.ts          design tokens (imported from ../../assets/tokens.json), easings
  fonts.ts           Inter + Geist Mono via @remotion/google-fonts
```

Every scene is a separate component inside its own `<Sequence>`; durations live
in `scenes.ts`. Entrances ease out, moves ease in-out, exits ease in (bezier
values from `tokens.json`). Scenes dip through the dark background between each
other (0.35 s), so headlines never overlap. Screenshots are never still: each
carries a slow push-in / pan and dissolves into the next screenshot mid-scene.

## Scenes

| # | Scene | Dur | What happens |
|---|-------|-----|--------------|
| 1 | Hook | 3.6 s | Glow blooms up behind “Devin now runs on Mac.” |
| 2 | Context | 6.2 s | “Before” rule draws in. “iOS teams QA'd by hand, or waited 20+ minutes on CI.” → “No coding agent could build, run and tap through an iPhone app.” → “Until now”. |
| 3 | Feature 01 — Build & run | 7.2 s | `devin-web-4` (platform picker): cursor moves to **macOS**, clicks, pill “macOS · hosted VM”. Dissolve to `devin-web-13` (Devin rebuilding and re-running tests), pill “Rebuild · rerun all tests”. |
| 4 | Feature 02 — Live Simulator | 7.6 s | `devin-web-11` (iPhone Simulator in the session), pill “You can watch — and tap too”. Dissolve to `devin-web-10` (Devin typing in the app); cursor taps send with a click ripple, pill “12 passed”. |
| 5 | Feature 03 — Fix & ship | 7.0 s | `devin-web-9` (session + PR #161 side by side): slow push-in, pills “Simulator run · 12 passed” and “Ready to merge”. |
| 6 | Feature 04 — Every screen | 7.4 s | `devin-web-17` (dark six-screenshot matrix) pans up, pill “Dark mode · 6 screens”. Dissolve to `devin-web-19` (iPad Pro acceptance run), pill “iPad Pro 13″”. |
| 7 | Outcome | 6.0 s | “Build, run and test iOS apps in the cloud.” + three metric columns: Speed / Only / Same. |
| 8 | End card | 4.0 s | White Devin lockup, “The only coding agent with a Mac cloud agent.”, `devin.ai`. |

## Notes

- Inter stands in for NB International Pro (per `BRIEF.md`); weights 400/500 only.
- A very fine SVG grain (4.5 % overlay) sits on the backdrop to break up 8-bit
  banding in the dark radial gradient.
- Callout pills are children of `ScreenFrame`, so they share the screenshot's
  Ken Burns transform and stay pinned to the UI element.
