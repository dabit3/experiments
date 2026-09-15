# 13 · Cinematic Macro

Commercial product-film treatment of the "Devin now runs on Mac" launch: a 2.39:1 letterbox inside the 16:9 frame,
extreme close-ups of the real product UI with shallow depth of field (blur masks), slow dolly moves only,
anamorphic-style horizontal light streaks, subtle film grain and quiet lower-thirds.

- Composition: `Main` · 1920×1080 · 30 fps · 1365 frames (45.5 s)
- Assets are read from `../../assets` via `staticFile()`; nothing is copied into this folder.
- Fonts: Inter (stand-in for NB International Pro, weights 400/500) and Geist Mono via `@remotion/google-fonts`.

## Render

```sh
npm install
npx remotion render Main out/video.mp4   # H.264, CRF 16 (see remotion.config.ts)
npx remotion studio                       # live preview
npx tsc --noEmit                          # typecheck
```

Contact sheet of 10 evenly spaced frames (requires ffmpeg):

```sh
ffmpeg -y -i out/video.mp4 -vf "select='not(mod(n\,150))',scale=640:-1,tile=2x5" -frames:v 1 out/contact-sheet.png
```

## Structure

`src/scenes.ts` holds the timing table (`SCENE_DURATIONS`, `XFADE`); scenes overlap by `XFADE` and dissolve into each
other inside `<Sequence>`s in `src/Main.tsx`. Every scene is its own component in `src/scenes/` and receives its
`duration` so copy timing follows retimes automatically.

| # | Scene (`scenes.ts`) | Length | What happens |
|---|---|---|---|
| 1 | `hook` | 3.5 s | Macro push-in on the macOS platform chip of the new-session screen (`devin-web-1`). "Devin now runs on Mac." |
| 2 | `context` | 5 s | Lateral dolly along the empty prompt field with a blinking caret. "Before, iOS apps were QA'd by hand." → "Or waited 20 minutes for CI." |
| 3 | `choosePlatform` | 6 s | Platform picker (`devin-web-4`); a cursor glides to **macOS** and clicks while the camera pushes in. "Pick macOS. Devin runs in a Mac VM." |
| 4 | `buildRun` | 6 s | Vertical dolly down the iPhone Simulator running the built game (`devin-desktop-9`). "Builds the app. Runs it in the Simulator." |
| 5 | `liveSimulator` | 6.5 s | Push-in on the live Simulator player until the `typing...` indicator fills the frame (`devin-web-10`). "A live iPhone Simulator, inside the session." → "Devin taps, types and scrolls. So can you." |
| 6 | `fixAndPr` | 6.5 s | Test tally (12 passed / 3 failed) dissolves to the opened PR, ready to merge (`devin-web-9`). "Reproduces the bug. Fixes it. Re-runs the tests." → "Then opens the PR." |
| 7 | `deviceMatrix` | 6 s | iPad Simulator (`devin-web-19`) dissolves to the dark screenshot grid (`devin-web-17`). "iPhone and iPad. Light and dark." → "Screens compared pixel for pixel." |
| 8 | `outcome` | 6.5 s | Dark card, three lines in sequence: minutes not 20-minute CI round-trips · only coding agent with a Mac cloud agent · same security, same price as Linux. |
| 9 | `endCard` | 3.5 s | White Devin lockup on `#121111`. "Build, run and test iOS apps in the cloud." |

## Components

- `MacroShot` — the camera. Takes image-space `from`/`to` poses (`x`, `y`, `scale`), eases with the token
  ease-in-out curve, and renders the screenshot twice: a blurred plate and a sharp plate revealed through a soft
  elliptical mask around the focus point. Children receive a `project()` function to place overlays in image space.
- `Cursor` / `Caret` — animated macOS pointer (with click pulse) and blinking text caret, positioned in image space.
- `LowerThird` — mono label + one line of copy, ease-out in / ease-in out, bottom-left inside the picture area.
- `FilmLayer` — `Grain` (per-frame SVG turbulence), `Streak` (anamorphic light streaks), `Grade` (vignette + scrim).

All colours, tracking, radii and easing curves come from `../../assets/tokens.json` through `src/tokens.ts`.
