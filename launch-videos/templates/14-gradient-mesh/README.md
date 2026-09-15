# 14 — Gradient Mesh

Devin launch video template (Devin on macOS / native iOS) in the "Gradient Mesh" direction:
a slowly drifting, low-saturation mesh gradient (electric-blue tints, soft green, cream) fills the
frame; product UI sits in a clean white card with a hairline border. The mesh's dominant hue
shifts at every scene boundary.

Standalone Remotion 4 project. 1920×1080, 30 fps, 48.2 s (1446 frames), H.264.

## Render

```sh
cd launch-videos/templates/14-gradient-mesh
npm install
npx remotion render Main out/video.mp4   # or: npm run render
npm run dev                              # Remotion Studio
npm run typecheck                        # tsc --noEmit
```

Assets (screenshots, brand lockups, `tokens.json`) are shared from `launch-videos/assets/` via
`Config.setPublicDir("../../assets")` and referenced with `staticFile("screens/…")` /
`staticFile("brand/…")`. Nothing is copied into this directory.

## Structure

| File | Purpose |
| --- | --- |
| `src/scenes.ts` | Timing table (durations, mesh mood per scene). Edit here to retime. |
| `src/tokens.ts` | Typed access to `assets/tokens.json` + `Easing.bezier` curves. |
| `src/fonts.ts` | Inter + Geist Mono via `@remotion/google-fonts`, loaded at module level. |
| `src/Mesh.tsx` | Animated background: five drifting radial blobs, palette cross-fades per scene. |
| `src/ui.tsx` | `SceneFade`, `Headline`, `Label`, `Card`, `ShotStack` (push-in + cross-fade), `Cursor`. |
| `src/scenes/*.tsx` | One component per scene, each mounted in a `<Sequence>` in `src/Main.tsx`. |

## Scenes

| # | Scene | Length | Mesh | What happens |
| --- | --- | --- | --- | --- |
| 1 | Hook | 3.6 s | blue | Mono kicker "Devin on macOS · Native iOS", hero line "Devin now runs on Mac." |
| 2 | Context | 6.2 s | neutral | Three staggered lines: manual QA / 20+ min CI / no agent could tap through an iPhone app. |
| 3 | 01 Build and run | 7.2 s | blue | New-session home → platform picker (cursor clicks macOS) → wide session with the app running in the Simulator. |
| 4 | 02 Live Simulator | 7.2 s | indigo | Full-screen Simulator player, loading → running; "Devin taps, types and scrolls. You can too." |
| 5 | 03 Fix and ship | 7.2 s | green | Simulator reproducing a bug → session with test summary and the opened PR. |
| 6 | 04 Every screen | 7.2 s | cream | iPad Simulator acceptance → dark review panel with the six-iPhone screenshot grid. |
| 7 | Outcome | 5.6 s | indigo | Three metric lines separated by hairlines. |
| 8 | End card | 4.0 s | blue | Devin lockup, "Build, run and test iOS apps in the cloud.", devin.ai |

Motion vocabulary: fade + 24 px rise for text (ease-out), slow scale push-in and 300 ms
cross-fades for screenshots, ease-in fades between scenes. Screenshots are `object-fit: cover`
inside the card with a per-shot transform origin so the interesting region stays in frame.
