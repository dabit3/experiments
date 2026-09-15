# 15 — Wireframe to Real (idea → built)

Devin on macOS / native iOS launch video. Every feature opens as a hand-drawn
wireframe of the real UI, resolves into the actual screenshot over 600ms, then
comes alive with cursor, typing and cross-fade motion. 1920×1080, 30fps, 46.6s.

## Render

```bash
npm install
npm run render        # -> out/video.mp4 (H.264)
npm run dev           # Remotion Studio
npm run typecheck     # tsc --noEmit
```

Assets are read from `../../assets` (`remotion.config.ts` → `Config.setPublicDir`)
via `staticFile("screens/…")` / `staticFile("brand/…")`; nothing is copied here.
Design tokens come from `../../assets/tokens.json` (`src/tokens.ts`).

## Scenes (`src/scenes.ts`)

| # | Scene | Length | What happens |
|---|-------|--------|--------------|
| 1 | Hook | 3.2s | "Devin now runs on Mac." is drawn as a rough outline, then resolves into type. |
| 2 | Context | 5.6s | Two problem lines: manual QA / 20+ minute CI, and no agent could drive an iPhone app. |
| 3 | Feature 1 · New session | 7.6s | Wireframe of the empty session → `devin-web-1` → prompt types in → cursor picks **macOS** (`devin-web-4`). |
| 4 | Feature 2 · Simulator | 7.0s | Wireframe of the player → `devin-web-11` (loading) → `devin-web-10` (live iPhone Simulator). |
| 5 | Feature 3 · Fix and ship | 7.0s | Wireframe of session + PR panel → `devin-web-9`; slow push toward the PR. |
| 6 | Feature 4 · Every screen | 7.0s | Wireframe of the review grid → `devin-web-17` (iPhone screenshots) → `devin-web-19` (iPad). |
| 7 | Outcome | 5.6s | Three lines appear as placeholder bars, then resolve: minutes not CI round-trips; only Mac cloud agent; same security/price. |
| 8 | End card | 3.6s | Devin lockup, "Build, run and test iOS apps in the cloud.", devin.ai. |

## Structure

- `src/scenes.ts` — timing table; retime scenes here.
- `src/components/rough.ts` / `Wireframe.tsx` — deterministic hand-drawn SVG primitives, drawn on with stroke-dash.
- `src/components/SketchText.tsx` — text that starts as a sketch (outline or bar) and resolves into type.
- `src/scenes/Feature.tsx` — wireframe → screenshot → animated screenshot (push-in, cross-fade, `Cursor`, `Typing`).
- Fonts: Inter + Geist Mono via `@remotion/google-fonts`, loaded at module level in `src/fonts.ts`.
