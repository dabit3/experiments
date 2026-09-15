# 04 — Terminal Native

A 42-second, silent launch film. A neutral charcoal terminal becomes the
container for native iPhone imagery; commands open each beat, output scrolls
into place, and an actual recording grows from an embedded pane to full frame.

## Edit and render

From `launch-video-templates`:

```sh
npm ci
npm run lint
npm run typecheck
npm run validate
npm run render -- 04-terminal-native
# For a deliverable without a silent AAC track:
npm run render -- 04-terminal-native --muted
node templates/04-terminal-native/qa.mjs
```

`config.ts` owns all headline copy, output lines, commands, scene starts and
durations, typing/reveal cadence, and the recording's source offset/expansion.
Times are seconds, except explicitly named `Frame`/`Frames` properties.
Keep the scenes contiguous and update `template.json` if total duration changes.
Update `qa.mjs`'s baseline assertions and sampled frames when changing timing.
`index.tsx` contains the terminal layout, crop rectangles, palette and
frame-based animation components. Composition ID: `Launch`, 1920×1080, 30fps.

The output is `out/04-terminal-native.mp4`. `qa.mjs` requires system ffmpeg and
ffprobe; it verifies dimensions, codec, frame rate/count and duration, then
extracts the full-frame poster and a 24-frame contact sheet into ignored `out/`.
Do not commit media. Inspect the contact sheet and original-size extracted
frames after running the helper. Its printed frame/time index corresponds
to contact-sheet order, left to right and top to bottom.

## Scene plan and motion budget

Each command types during local frames 5–27. The content reveal begins at frame
30 and settles at frame 52. Narration output enters at frames 50, 70, and 90.
Typing and cursor blinking form one terminal-text family; staged pane/headline
reveals, output translation, gesture movement and pane expansion form one
spatial UI family. Entrances use cubic ease-out, moves use cubic ease-in-out.
No random state, CSS animation, network media or wall-clock timing is used.
The only independent captured motion is in the real video. Its cursor stops
blinking before the media appears; expansion starts at local frame 105, after
all output has settled. Its live video plus one spatial UI family are the only
concurrent motion families.
Each scene deliberately returns to the command prompt before revealing its
content. These command-only transitions are intentional terminal pacing.
Evidence copy fades before the expanding recording overlaps its text.

| Time | Primary copy | Media | Concurrent motion families |
| --- | --- | --- | --- |
| 00:00–00:04.5 | Devin goes native. | Supplied Afterhours Maze iPhone crop | Terminal text; pane/headline/output reveal |
| 00:04.5–00:08 | QA meant waiting. | Typographic 20+ minutes CI context | Terminal text; text/output reveal |
| 00:08–00:14 | Build it. Run it. | Same native app inside a managed-Mac-VM terminal pane | Terminal text; pane/headline/output reveal |
| 00:14–00:20 | Tap. Type. Scroll. | Supplied Wisp iPhone with illustrative gesture indicators | Terminal text; pane/output/gesture movement |
| 00:20–00:26 | Reproduce. Fix. Retest. | Wisp crop plus faithfully transcribed mixed check results | Terminal text; pane/headline/output reveal |
| 00:26–00:33.5 | Review the recording. | Actual web QA clip, source 14–21.5 seconds, expanding to full frame | Captured video + spatial reveal initially; captured video + pane expansion later |
| 00:33.5–00:38.5 | A working app. In your session. | Supplied Rescue charts iPhone crop; Linux VM pricing | Terminal text; pane/headline/output reveal |
| 00:38.5–00:42 | Build. Run. See it. | Original supplied white Devin logo | Terminal text; logo/title reveal |

Feature beats are separate scenes; the footer highlights the active step.
Scene numbers describe story order, not measured execution time.

## Truthfulness and source provenance

All source files remain in shared `public/assets` and load via `staticFile`.
Native phone regions are proportionately cropped from the original screenshots
using Remotion `Img`; nothing is stretched. Phone crops are in `crops` in
`index.tsx`. Grayscale is applied to screenshots and the recording to keep this
direction neutral; source contents remain intact. The supplied logo is not
filtered, redrawn or stretched.

- `devin-web-14.png`: Afterhours Maze iPhone Simulator image. Only the phone
  region is shown. Its game UI is a static source capture, not newly recorded
  native video and not a demonstration of a new test pass.
- `devin-web-10.png`: Wisp iPhone Simulator image. The interaction scene uses a
  fixed screenshot with illustrative tap/type/scroll indicators; the phone's
  pixels do not represent three newly executed interactions. The reproduce
  scene transcribes the supplied summary: **12 passed, 3 failed, 2 untested**,
  including failed key persistence/model metadata checks. No fixed/passed
  state is fabricated. The copy describes the workflow Devin can perform,
  not a claim that these particular failures were repaired.
- `devin-web-18.png`: Rescue charts native iPhone screenshot in the outcome.
  Its use illustrates the inspectable app in the session, not live footage.
- `devin-testing-2.mp4`: muted `OffthreadVideo`, original source 14–21.5s,
  normal playback rate. This is **actual web-app QA**, clearly labeled in both
  embedded and expanded states. It illustrates reviewing generic recorded
  evidence, never iOS testing or Mac VM selection. Both the browser action
  and existing evidence rail are retained at their original aspect ratio.
- `logo-white.png`: faithful supplied Devin lockup on charcoal.
- `model-selector-local.mp4` is not used.

Terminal commands and log output are **illustrative command sequences**,
not a Devin CLI API. `printf`, `cat`, `xcodebuild`, `open`, and `git diff` are
ordinary shell tools. `workflow.before`, `MyApp`, and `evidence/` are example
local names. No claim is made that these exact commands were run in a real
Devin session. The footer labels staged scenes “Illustrative workflow.”
The interaction indicators are presentation graphics, not a simulated
accessibility API. The 20+ minutes claim is the supplied prior CI context,
not a benchmark or measured improvement. Same pricing as Linux VMs comes
from the launch brief.

## Design and limitations

Dark-neutral adaptation of the coordinator's inspected Figma context and
`shared/brand.ts`: `#191919`, thin rules, restrained radii, generous whitespace.
Monospace typography uses **SFMono-Regular / Menlo / Consolas / monospace**;
Menlo is available on the production Mac. NB International Pro and Inter font
binaries were not supplied, so neither is claimed as bundled. Render elsewhere
with the same system font installed for identical typography.

This film is intentionally silent. Incidental source-recording audio is muted.
No new iOS capture, newly verified test pass, real device, distribution/signing,
benchmark, or guaranteed speedup is implied. One iPhone is presented at a time.
The final logo holds to the last frame.
