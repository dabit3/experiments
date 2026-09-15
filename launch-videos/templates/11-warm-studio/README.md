# 11 · Warm Studio

Devin launch video template — *Devin on macOS / native iOS*.
Direction: Notion / Claude / Scandinavian product design. Paper background,
soft rounded product frames, medium-weight Inter, a single electric-blue
accent, and slow, calm motion (800 ms fades, gentle drifts). On-screen copy
narrates in second person, one idea at a time.

1920×1080 · 30 fps · ~46.6 s · H.264

## Render

```sh
npm install
npx remotion render Main out/video.mp4   # or: npm run render
npx remotion studio                       # live preview
npx tsc --noEmit                          # typecheck
```

Assets are **not** copied here. `remotion.config.ts` sets
`Config.setPublicDir("../../assets")`, so screenshots and brand marks are
referenced from the shared `launch-videos/assets/` folder via
`staticFile("screens/…")` / `staticFile("brand/…")`, and design tokens are
imported from `launch-videos/assets/tokens.json`.

## Scenes

Timings live in `src/scenes.ts`; retime the film from that one table.
Scenes are butted together and each fades through paper (out 500 ms, in 800 ms).

| # | Scene | Length | What happens |
|---|-------|--------|--------------|
| 1 | `hook` | 3.6 s | Mono label, then "Devin now runs on Mac." rises in. |
| 2 | `context` | 6.0 s | Two problem lines: testing by hand / 20-minute CI, and "no coding agent could build, run and tap through an iPhone app on its own." |
| 3 | `feature-build` | 7.6 s | Devin home screen; the prompt is typed live with a caret, then cross-fades to the macOS platform picker with a cursor. Copy: "You describe the feature." → "Pick macOS. Devin builds it in Xcode and runs it in the iOS Simulator." |
| 4 | `feature-simulator` | 6.4 s | Live iPhone Simulator session with a slow push-in; cross-fades from the loading state to the full-screen player. Copy: "Watch Devin tap, type and scroll…" → "You can jump in and tap too." |
| 5 | `feature-fix` | 6.8 s | Desktop session summary (compile error fixed, BUILD/TEST SUCCEEDED) drifting up, then cross-fade to the PR with Simulator video + "Ready to merge". |
| 6 | `feature-matrix` | 6.4 s | iPad acceptance flow easing out of a push-in, cross-fade to the dark six-iPhone screenshot matrix. Copy: "It checks iPhone and iPad sizes, dark mode and orientations." → "Every screenshot compared pixel for pixel." |
| 7 | `outcome` | 5.8 s | "Minutes, not 20-minute CI round-trips." plus three staggered facts (Mac cloud agent · Security · Price). |
| 8 | `end` | 4.0 s | Devin lockup, tagline, `DEVIN.AI`. |

## Structure

```
src/
  index.ts          registerRoot
  Root.tsx          <Composition id="Main">
  Main.tsx          maps scenes.ts → <Sequence>s
  scenes.ts         timing table
  tokens.ts         tokens.json → colours, radii, easings, ms()→frames
  fonts.ts          Inter + Geist Mono via @remotion/google-fonts (module level)
  components/       Scene, FeatureLayout, Figure, Narration, Text, Cursor, motion.ts
  scenes/           one component per scene
```

Motion rules: entrances use the token ease-out, moves use ease-in-out,
no springs, at most two motion types per scene.
