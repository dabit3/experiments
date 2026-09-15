# 16 — Split Timeline (human vs. agent)

Devin launch video template. A persistent vertical split: **You** on the left
(typed prompts and spoken instructions rendered as text), **Devin** on the
right (the agent working in the real product UI, animated from the shared
screenshots). A thin timeline across the top tracks elapsed session time,
`00:00 → 04:12`. Emphasizes speed and autonomy.

- Composition: `Main`, 1920×1080, 30 fps, 47 s (1410 frames)
- Assets are read from `../../assets` (`Config.setPublicDir`) via `staticFile()`;
  nothing is copied into this directory.
- Design tokens come straight from `../../assets/tokens.json` (`src/theme.ts`).
  Fonts: Inter + Geist Mono via `@remotion/google-fonts`.

## Render

```sh
npm install
npx remotion render Main out/video.mp4   # or: npm run render
npx remotion studio                      # preview / scrub
npx tsc --noEmit                         # typecheck
```

## Retiming

All scene starts/durations live in `src/scenes.ts`. Each scene is its own
component in `src/scenes/` mounted in a `<Sequence>` from `src/Main.tsx`, so a
scene can be lengthened or removed without touching the others. The timeline's
wall-clock readout is driven by the `elapsed` seconds in that table.

## Scenes

| # | Time | Scene | Left (You) | Right (Devin) |
|---|------|-------|------------|---------------|
| 1 | 0:00–0:03 | Hook | — | "Devin now runs on Mac." full-frame headline; split chrome fades in as it exits. |
| 2 | 0:03–0:09 | Context | "iOS teams QA'd apps by hand. Or waited 20+ minutes for CI." | Empty session home (`devin-web-1`) → cursor opens the platform picker and selects macOS (`devin-web-4`). |
| 3 | 0:09–0:16 | Build · `00:00→00:58` | Typed prompt: "Add 30 locations and 80 fish species, then rebuild and rerun the tests." | Devin's reply in the session (`devin-web-13`) → push-in on "verified on a real iOS Simulator … BUILD SUCCEEDED, TEST SUCCEEDED" (`devin-desktop-7`). |
| 4 | 0:16–0:23 | Testing · `00:58→01:52` | Spoken: "Sign in with the key, send a message, then stop the reply mid-stream." + "Devin taps, types and scrolls like a person." | Simulator loading (`devin-web-11`) → live chat with cursor taps and a typing overlay (`devin-web-10`). |
| 5 | 0:23–0:30 | Fixing · `01:52→03:10` | Typed: "The API key is lost after relaunch. Fix it and open a PR." + "Re-runs the UI tests. Opens the PR." | Test list panning through the failed checks (`devin-web-10`) → PR "Ready to merge" (`devin-web-9`). |
| 6 | 0:30–0:37 | QA · `03:10→04:12` | Spoken: "Check every screen before we ship." + "iPhone and iPad. Dark mode. Every orientation." | Dark device matrix (`devin-web-17`) → iPad Simulator acceptance run (`devin-web-19`). |
| 7 | 0:37–0:43 | Outcome | Full width: "Minutes, not 20+ minute CI round-trips." with a 04:12 vs 20:00+ bar comparison, then the launch facts (Mac cloud agent, same security, no price increase). | |
| 8 | 0:43–0:47 | End card | Devin lockup, "Build, run and test iOS apps in the cloud.", `devin.ai`. | |

Motion rules: ease-out entrances, ease-in-out camera moves, ease-in exits
(bezier values from `tokens.json`); no springs. Screenshots always move —
slow push-ins/pans, cross-fades between sequential shots, animated cursor and
typing overlays — and keep their aspect ratio (`object-fit: cover` inside a
fixed 16:9-ish figure).
