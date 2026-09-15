# 09 — Brutalist Clean

Devin on macOS / native iOS launch video. Direction: Bloomberg Businessweek / raw web.
Massive Inter Medium type on off-white paper, one electric-blue accent, screenshots in
thick black frames, and a Geist Mono feature ticker running along the bottom edge for the
whole 48 seconds.

1920×1080 · 30 fps · 48 s · H.264 · composition id `Main`.

## Render

```bash
npm install
npx remotion render Main out/video.mp4   # or: npm run render
npx remotion studio                       # live preview
npx tsc --noEmit                          # typecheck
```

Assets are read from the shared `launch-videos/assets/` directory via
`Config.setPublicDir("../../assets")` in `remotion.config.ts`; nothing is copied here.
Design tokens come straight from `launch-videos/assets/tokens.json`.

## Retiming

All scene durations live in `src/scenes.ts`. Change a `seconds` value and the sequence
offsets, total duration and ticker inversion point update automatically.

## Scenes

| # | Scene | Length | What happens |
|---|-------|--------|--------------|
| 1 | `Hook` | 3.5 s | "Devin now / runs on Mac." at 208 px, lines stagger in; a full-width electric-blue rule draws left to right. |
| 2 | `Context` | 6 s | Masthead "Before / The problem". Two declarative statements cross-fade: manual QA / 20-minute CI, then "no coding agent could build, run and tap through an iPhone app." |
| 3 | `FeaturePlatform` | 7 s | 01/04 Build & run. Empty Devin prompt → cursor travels to the platform picker, click ring, cross-fade to the open picker with macOS highlighted. Slow push-in throughout. |
| 4 | `FeatureSimulator` | 7.5 s | 02/04 Live simulator. Session view with the iPhone Simulator loading, cross-fades to the running app with the typing overlay; slow push-in and drift toward the phone. |
| 5 | `FeatureBugToPr` | 7.5 s | 03/04 Bug to PR. Pans across the session from the failing UI-test summary to the open PR panel ("Ready to merge"). |
| 6 | `FeatureMatrix` | 7 s | 04/04 Every screen. Dark-mode iPhone screenshot grid, then a zoom-out cross-fade to the iPad landscape acceptance run. |
| 7 | `Outcome` | 6 s | Four numbered outcome lines separated by hairline rules, revealed in sequence. |
| 8 | `EndCard` | 3.5 s | Ink background, white Devin lockup, "Build, run and test iOS apps in the cloud.", devin.ai. Ticker inverts to paper. |

`Ticker` (in `src/components`) is mounted outside the scene sequences so it never resets.

## Structure

```
src/
  index.ts            registerRoot
  Root.tsx            <Composition id="Main" />
  Main.tsx            scene sequences + ticker, font delayRender guard
  scenes.ts           timing table
  theme.ts            tokens → colors, type, easing, layout constants, font loading
  components/         Headline, Masthead, Screenshot (framed, push/pan/cross-fade), Cursor, Underline, Ticker, FeatureLayout
  scenes/             one component per scene
```
