# 03 — Swiss Grid

Devin launch video (macOS / native iOS) in the International Typographic Style: a strict
12-column grid shown as faint guides during transitions, flush-left Inter in three sizes
(hero / heading / text, Medium 500 only), Geist Mono for section numbers and labels, one
accent (electric blue `#2200FF`), and section numbers anchoring every scene.

1920×1080 · 30 fps · 44.2 s · composition id `Main`.

## Render

```bash
npm install
npx remotion render Main out/video.mp4   # or: npm run render
npx remotion studio                       # preview / scrub
npx tsc --noEmit                          # typecheck
```

Assets are read from the shared `launch-videos/assets/` directory
(`Config.setPublicDir("../../assets")` in `remotion.config.ts`) via
`staticFile("screens/…")` and `staticFile("brand/…")`. Nothing is copied into this folder.

## Retiming

All scene durations live in `src/scenes.ts` (`SCENES`, in seconds). `src/Main.tsx` lays the
scenes out as consecutive `<Sequence>`s; grid guides fade in for `GUIDE_FRAMES` around every
scene boundary.

## Scenes

| # | Scene | Length | What happens |
|---|-------|--------|--------------|
| 01 | Hook | 3.6 s | "Devin now runs on Mac." / "It writes and tests code for Mac and iOS apps." Type rises in on the grid. |
| 02 | Before | 5.4 s | The old loop: manual QA or 20+ minute CI round-trips, with a mono CI timer ticking up. "No coding agent could build, run and tap through an iPhone app on its own." |
| 03 | Product in action | 6.4 s | Home screen (`devin-web-1`) enlarged around the prompt; an animated cursor opens the platform picker (`devin-web-4`) and picks **macOS**; cut to the live session where Devin builds and runs the app in Xcode / the Simulator (`devin-web-13`). |
| 04 | Product in action | 6.4 s | Full-screen iPhone Simulator player: slow push-in from the loading state (`devin-web-11`) cross-fading to the running app (`devin-web-10`). "Watch Devin tap, type and scroll…" → "You can tap too." |
| 05 | Product in action | 6.8 s | Push-in on a Simulator run (`devin-web-14`), then pull back to reveal the session with the iOS PR opened (`devin-web-9`). "Devin reproduces the bug… and fixes it." → "Re-runs the UI tests. Opens a PR." |
| 06 | Product in action | 6.4 s | Vertical pan over the dark device-matrix review (`devin-web-17`), cross-fade to the iPad Simulator (`devin-web-19`). "Checks every screen on iPhone and iPad…" → "Compares screenshots pixel for pixel." |
| 07 | Outcome | 5.6 s | "Minutes, not 20+ minute CI round-trips." plus four grid cells: Platform, Security, Price, Works on Mac. |
| 08 | End card | 3.6 s | Devin lockup, "Build, run and test iOS apps in the cloud.", `devin.ai`. |

## Structure

```
src/
  index.ts / Root.tsx / Main.tsx   registration, composition, sequence layout
  scenes.ts                        timing table
  theme.ts                         tokens.json → colors, type, grid geometry, easings
  components/                      GridGuides, SectionAnchor, Figure, Cursor, Text, Scene
  scenes/                          Hook, Context, Feature*, Outcome, EndCard
```

Motion rules: ease-out (`[0.16, 1, 0.3, 1]`) for entrances, ease-in-out (`[0.65, 0, 0.35, 1]`)
for moves, no springs, at most two motion types per scene.
