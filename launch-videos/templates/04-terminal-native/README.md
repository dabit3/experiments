# 04 — Terminal Native

Devin on macOS / native iOS launch video in a dark CLI aesthetic. Everything happens
inside one monospace terminal window: a typed command with a blinking cursor triggers
each reveal, output lines scroll in as narration, and product screenshots appear as
embedded panes that expand to (near) full frame.

- Composition `Main`, 1920×1080, 30 fps, 47 s (1410 frames).
- Dark tokens only (`launch-videos/assets/tokens.json`): bg `#121111`, surface `#141414`,
  accent `#2200FF`, Inter 400/500 + Geist Mono 400/500 via `@remotion/google-fonts`.
- Assets are read from `../../assets` via `Config.setPublicDir` — nothing is copied here.

## Render

```sh
npm install
npm run dev        # Remotion Studio
npm run render     # -> out/video.mp4 (H.264)
npm run typecheck  # tsc --noEmit
```

## Scenes

Durations live in `src/scenes.ts`; change a number there to retime the whole piece.

| # | Scene | Length | What happens |
|---|-------|--------|--------------|
| 1 | Hook | 4.0 s | The real Devin CLI splash (cropped from `devin-cli-3.png`). `devin --platform macos` is typed, `✓ macOS session started`, headline **Devin now runs in a Mac VM.** |
| 2 | Context | 5.5 s | `cat BEFORE.md` prints the problem: hand QA / 20+ min CI, and no agent could build, run and tap through an iPhone app. |
| 3 | Build & run | 7.0 s | `devin new "Build and test Reel Horizon on iOS"` → macOS VM ready, `xcodebuild`, app running. Pane: macOS platform picker (`devin-web-4`) cross-fading to the live session (`devin-web-13`), expands to frame with caption. |
| 4 | Live simulator | 7.0 s | `devin simulator --attach`. Pane: live iPhone Simulator (`devin-web-10` → `devin-web-11`) with accent tap rings on the phone. Caption: *Devin taps, types and scrolls like a person. You can watch, and tap, too.* |
| 5 | Fix & ship | 7.0 s | `devin test --ui` → `1 failed`, reproduced in the Simulator, fixed, `7 passed`, PR opened. Pane: session with simulator recording + PR (`devin-web-9`). |
| 6 | Every screen | 7.0 s | `devin screens --devices iphone,ipad --dark` → iPhone 17 Pro · iPad Pro 13, light/dark/orientations, `0 px differ`. Pane: six-phone review grid (`devin-web-17`) → iPad Simulator (`devin-web-19`). |
| 7 | Outcome | 6.0 s | `devin status` prints the metrics table: speed, platform, security, price — plus child sessions / Declarative Repo Setup / API on Mac. |
| 8 | End card | 3.5 s | Terminal fades out; white Devin lockup, *Build, run and test iOS apps in the cloud.*, `devin.ai`. |

## Motion rules used

- Entrances ease-out, moves ease-in-out, exits ease-in — all bezier values from `tokens.json`.
- Max two motion types per scene: typed text + fade-in lines in terminal scenes; pane expand + slow push-in (anchored top-left so no UI text is cropped) in feature scenes.
- Screenshots never sit still: every pane has a continuous 6 % push-in and cross-fades between sequential shots.
- Expanded panes stop at the 80 px safe-area inset (screenshot aspect, 10 px radius) instead of true edge-to-edge so screenshot chrome text is never clipped.

## Structure

```
remotion.config.ts       publicDir ../../assets, H.264
src/scenes.ts            timing table (FPS, per-scene seconds, typing speed)
src/tokens.ts            tokens.json + font loading + terminal geometry
src/Main.tsx             <Sequence> per scene
src/scenes/              Hook, Context, Feature (generic), Outcome, EndCard
src/features.tsx         the four feature specs (command, output lines, shots, caption)
src/components/          TerminalWindow, Prompt (typed command / cursor / output lines),
                         Pane (docked → expanded screenshot), Caption, CursorOverlay (tap rings)
```
