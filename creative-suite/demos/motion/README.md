# SIGNAL / native Motion lab

A disclosed **static seed** supplies the artwork. `demo.py` edits real native
controls using public AX discovery and Quartz mouse/keyboard events. It does
not import or mutate Motion's model. Saved JSON and exported video are read
back only for assertions.

`ScriptViewer.swift` is a passive AppKit sidecar: actual executing Python
source, current line, process ID, elapsed time and observed results. A failed
assertion stops the harness and displays FAIL. The app remains visible.

This is a local native automation harness and recording workflow. The sidecar
is not Devin's built-in native test replay, and this harness does not register
a replay with Devin.

## Requirements

- macOS 14+, Xcode/Swift 6, an unlocked graphical session.
- Python 3, `ffprobe`, and `ffmpeg` for independent artifact inspection.
- Accessibility and Screen Recording permission for the automation host.
- A 1600×1200 display at 1× scale. This demonstration's panel and timeline
  geometry intentionally targets that layout; do not run it at another size.
- No credentials, server, browser, or third-party Swift packages.

## Build and prepare

Run from `creative-suite/`. Choose a new persistent artifact directory for
each run. **Do not overwrite a running app or viewer binary.** Save unrelated
documents and close unrelated Motion windows before setup.

```sh
export MOTION_ARTIFACTS="$HOME/MotionDemoArtifacts"
mkdir -p "$MOTION_ARTIFACTS"
DEVIN_DIST="$MOTION_ARTIFACTS/apps-release" bash scripts/build-apps.sh
swiftc demos/motion/NativeInput.swift -o "$MOTION_ARTIFACTS/native-input"
swiftc demos/motion/ScriptViewer.swift -o "$MOTION_ARTIFACTS/script-viewer"
python3 demos/motion/make_seed.py "$MOTION_ARTIFACTS/SIGNAL-seed.devin"
"$MOTION_ARTIFACTS/native-input" info
open -a "$MOTION_ARTIFACTS/apps-release/Devin Motion.app" \
  "$MOTION_ARTIFACTS/SIGNAL-seed.devin"
```

Wait until the project window is visible. `native-input dump` should show the
SIGNAL seed as the first AX window. If a second, unused default sample window
was created at launch, close **only that known sample** with
`native-input close-window 1`. Never use that command on unrelated documents.

```sh
"$MOTION_ARTIFACTS/native-input" arrange 0 30 1140 1140
"$MOTION_ARTIFACTS/native-input" sweep 340 350 211 350 held
"$MOTION_ARTIFACTS/native-input" sweep 840 350 917 350 held
"$MOTION_ARTIFACTS/native-input" key 29 cmd
"$MOTION_ARTIFACTS/script-viewer" "$MOTION_ARTIFACTS/live-state.json"
```

The last command is a long-running viewer; launch it in a separate shell.
The `key 29 cmd` shortcut fits the composition. Hide the Dock for a clean
presentation if desired; the original setting should be restored afterwards.

Reopening a project resets the splitters and panel disclosure state. Always
start the harness from a freshly opened seed, with Info, Preview and Effects
initially expanded. Ensure `SIGNAL.devin` and `SIGNAL-render.mp4` do not already
exist in this run's directory; the harness intentionally does not silently
approve replacement dialogs.

## Rehearse, record, inspect

```sh
python3 demos/motion/demo.py
```

Read `TEST_PLAN.md`. Rehearse first, then reset to the seed and record one
continuous run with Motion on the left and the sidecar on the right. Use
structured recording annotations at meaningful observed transitions. Keep the
pointer visible. Runtime is approximately four minutes at deliberate pacing.

Numeric edits are committed by moving focus to Project Search before seeking.
The duration endpoint uses a held ruler drag rather than the window resize
border. Save As waits for named AX fields and enters folder and filename
separately, avoiding native-panel readiness races.

Outputs: `SIGNAL.devin`, `SIGNAL-render.mp4`, `live-state.json`, per-step
screenshots, three graph screenshots, `held-scrub.png`, `final-desktop.png`.
The exported animation is **not** the desktop recording.

Inspect the recording at full resolution. Some recording tooling creates a
short automatic cut; check its duration rather than assuming it is continuous.
Retain the raw segments and, if needed, concatenate them without editorial
cuts or speed changes, normalizing duplicate segment-boundary timestamps:

```sh
ffmpeg -f concat -safe 0 -i continuous-recording.txt -vf fps=15 \
  -c:v libx264 -preset fast -crf 16 -pix_fmt yuv420p -movflags +faststart \
  SIGNAL-screen-recording.mp4
```

The concat list must contain the actual raw segment paths in chronological
order. Use the capture's actual frame rate, not an assumed 15 fps on other
machines. Preserve the annotation JSON and raw files.

## Harness and artifact checks

```sh
python3 -m py_compile demos/motion/demo.py demos/motion/make_seed.py
swiftc -typecheck demos/motion/NativeInput.swift
swiftc -typecheck demos/motion/ScriptViewer.swift
ffmpeg -v error -i "$MOTION_ARTIFACTS/SIGNAL-render.mp4" -f null -
ffprobe -v error -count_frames -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_read_frames:format=duration \
  -of json "$MOTION_ARTIFACTS/SIGNAL-render.mp4"
```

Expected animation: 1280×720, H.264, 24 fps, 96 decoded frames, four seconds.
The scope does not include expressions, parenting, footage, cameras, audio,
other export formats, or Adobe parity.
