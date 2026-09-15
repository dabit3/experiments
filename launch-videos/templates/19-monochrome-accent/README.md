# 19 — Monochrome Accent

Devin on macOS launch video. Strict black / white / one accent (electric blue `#2200FF`).
Screenshots are desaturated to grayscale; only the UI element the copy is talking about
keeps its colour, framed by a 1px accent outline. Space Grotesk (medium, tight tracking)
for copy, Geist Mono for labels, hard geometric wipes between scenes.

1920×1080 · 30 fps · 44.9 s · composition id `Main`.

## Render

```bash
npm install
npx remotion render Main out/video.mp4   # H.264
npx remotion studio                      # live preview
npx tsc --noEmit
scripts/frames.sh                        # 12 review frames + out/contact-sheet.png (needs ffmpeg)
```

Assets are read from the shared `launch-videos/assets/` directory
(`Config.setPublicDir("../../assets")` in `remotion.config.ts`) — nothing is copied here.

## Scenes

Timings live in `src/scenes.ts`; each scene is a component in `src/scenes/` rendered in a
`<Sequence>` by `src/Main.tsx`. Consecutive scenes overlap by 16 frames so the incoming
wipe covers the outgoing scene.

| # | Scene | Length | What happens |
|---|-------|--------|--------------|
| 1 | `Hook` | 3.2 s | White. "Devin now runs on **Mac**." — the one accent word. |
| 2 | `Context` | 6.4 s | Black. "iOS teams tested by hand. Or waited 20+ minutes for CI." with a mono timer counting up; then "No coding agent could tap through an iPhone app." |
| 3 | `ChooseMac` | 7.4 s | White. Platform picker (`devin-web-4`): cursor moves and clicks **macOS**, which stays in colour. Cross-fade to the running session (`devin-web-13`) with the macOS chip highlighted. |
| 4 | `Simulator` | 7.2 s | Black. Full-screen iPhone Simulator (`devin-web-10`) with a slow push-in and pan; the active test step, then the "typing…" overlay, are lifted out of grayscale. |
| 5 | `FixAndShip` | 7.2 s | White. Session with test-run thumbnail and PR (`devin-web-9`): thumbnail in colour while "Reproduces the bug. Fixes it.", then the cursor moves to **Ready to merge** for "Opens the PR." |
| 6 | `Matrix` | 7.2 s | Black. Device screenshot review grid (`devin-web-17`) pans down to a dark-mode tile; cross-fade to the iPad Simulator (`devin-web-19`). |
| 7 | `Outcome` | 6.0 s | White. Three lines: minutes not 20+ minute CI round-trips; the only coding agent with a Mac cloud agent; same security, same price as Linux. |
| 8 | `EndCard` | 4.0 s | Black. Devin lockup, accent rule, "Build, run and test iOS apps in the cloud.", `devin.ai`. |

## Structure

- `src/theme.ts` — colours, type sizes, tracking, radius and `Easing.bezier` curves from `tokens.json`.
- `src/fonts.ts` — `@remotion/google-fonts` loaders for Space Grotesk and Geist Mono (400/500).
- `src/components/Screen.tsx` — grayscale screenshot with push/pan, cross-fade and colour accent regions (percent of the image).
- `src/components/Wipe.tsx` — hard directional clip-path wipe with an accent leading edge.
- `src/components/Text.tsx`, `Cursor.tsx`, `FeatureLayout.tsx` — copy reveals, pointer overlay, feature scene layout.
