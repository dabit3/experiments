# 12 — Metrics Story

Devin on macOS launch video, told through numbers. Every scene is anchored by a
tabular numeral that counts up or a bar that grows; the product UI sits beneath
each stat as proof.

1920×1080 · 30 fps · 45.5 s (1365 frames) · H.264

## Render

```sh
npm install
npx remotion render Main out/video.mp4   # or: npm run render
npm run dev                              # Remotion Studio
npm run typecheck
```

Assets are read from the shared `launch-videos/assets/` directory
(`Config.setPublicDir("../../assets")`); nothing is copied into this template.
Fonts (Inter, Geist Mono) load via `@remotion/google-fonts`.

## Scenes

Durations live in `src/scenes.ts`.

| # | Scene | Frames | What happens |
|---|-------|--------|--------------|
| 1 | Hook | 105 (3.5 s) | Counter ticks 1 → 3 platforms; Ubuntu · Windows · **macOS** lights up in electric blue. "Devin now runs on Mac." |
| 2 | Problem | 180 (6 s) | CI timer runs to `20:23+` minutes per round-trip; then `0` coding agents that could run an iPhone app. |
| 3 | Build | 195 (6.5 s) | `1` prompt. Cursor picks macOS in the platform picker (`devin-web-4`), cross-fade into the session running Xcode + Simulator (`devin-web-13`). |
| 4 | Live | 195 (6.5 s) | Live Simulator timecode `0:00 / 2:40` runs; typing overlay and cursor over the iPhone Simulator (`devin-web-11` → `devin-web-10`). |
| 5 | Tests | 210 (7 s) | `12` passed / `3` failed / `2` untested count in with a segmented bar; the session + PR #161 view underneath (`devin-web-9`). |
| 6 | Screens | 195 (6.5 s) | Dark scene. `6` screenshots checked across iPhone/iPad, light/dark (`devin-web-17` → iPad acceptance `devin-web-19`). |
| 7 | Outcome | 180 (6 s) | Comparison bars — 20+ min CI vs. minutes on Devin — then three cards: `0%` price increase, `1` only coding agent with a Mac cloud agent, `3` platforms. |
| 8 | End card | 105 (3.5 s) | Devin lockup, "Build, run and test iOS apps in the cloud.", devin.ai |

## Structure

- `src/scenes.ts` — timing table (`scenes`, `sceneStarts`, `totalFrames`)
- `src/scenes/*` — one component per scene, mounted in `<Sequence>`s in `src/Main.tsx`
- `src/components/` — `Numeral` / `MonoLabel` / `Narration` type, `Figure`/`Shot` screenshot
  motion (push-in, pan, cross-fade), `Cursor`, `Bar`/`SegmentBar`, `FeatureLayout`
- `src/anim.ts` — `tween`, `count`, `clock` helpers on the token easings
- `src/tokens.ts` — reads `launch-videos/assets/tokens.json`
