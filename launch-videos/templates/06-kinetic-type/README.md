# 06 — Kinetic Type

Beat-driven motion graphics for the Devin on macOS / native iOS launch. Narration is the hero:
oversized Inter Medium lines slam in on a 120 BPM grid (1 beat = 15 frames at 30 fps), with
short screenshot inserts (≤ 3 s) cut between text beats. Hard cuts only, black / white / `#2200FF`.

## Render

```sh
npm install
npx remotion render Main out/video.mp4   # 1920x1080, 30 fps, 46 s, H.264
npm run dev                              # Remotion Studio
npm run typecheck
```

Assets are read from the shared `launch-videos/assets/` directory via
`Config.setPublicDir("../../assets")`; nothing is copied into this template.

## Retiming

All durations live in `src/scenes.ts` as beat counts. `src/components/Beat.tsx` addresses
cues inside a scene in beats (`<Beat at={2} len={3}>`), so retiming a scene means changing
one number.

## Scenes

| # | Scene | Beats | Content |
|---|-------|-------|---------|
| 1 | `hook` | 8 | "Devin" → "now runs on Mac." → insert of the Devin home with the macOS chip. |
| 2 | `problem` | 11 | "iOS teams QA'd by hand." / "Or waited 20+ minutes for CI" / "No coding agent could run, or tap through an iPhone app." / "Until now." on accent. |
| 3 | `feature-build` | 13 | "Pick macOS." → platform-picker insert with cursor → "Devin builds the app in Xcode." / "Runs it in the iOS Simulator." → wide session view with the Simulator. |
| 4 | `feature-live` | 14 | "A live iPhone Simulator in your session." → Simulator insert with typing cursor → "Types." "Scrolls." "Like a person." "You can watch. And tap, too." → tap insert. |
| 5 | `feature-fix` | 13 | "Reproduces a bug." "Fixes it." "Re-runs the UI tests." → failing-test insert → "Opens a PR." → merged-PR insert. |
| 6 | `feature-matrix` | 13 | "iPhone." "Dark mode." "Landscape." → six-screenshot review panel → "Screenshots compared pixel for pixel." → iPad insert. |
| 7 | `outcome` | 12 | "Minutes. Not 20+ minute CI round-trips." / "The only coding agent with a Mac cloud agent." / "Same security as Linux and Windows VMs." / "No price increase." / "Child sessions, API, automations. All on Mac." |
| 8 | `end` | 8 | Devin lockup, "Build, run and test iOS apps in the cloud.", `devin.ai`. |

## Structure

- `src/components/Word.tsx` — kinetic headline: ease-out slam (1.12 → 1), accent word highlight, auto-fit to the 120 px frame margin.
- `src/components/Shot.tsx` — aspect-preserving screenshot insert with an ease-in-out crop move and a mono label.
- `src/components/Cursor.tsx` — pointer / tap-ring overlay in source-image coordinates.
- `src/tokens.ts` — reads `../../assets/tokens.json` (colors, type, radii, easings).
