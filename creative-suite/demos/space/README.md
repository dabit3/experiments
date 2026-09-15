# ORBIT — native Space demo

Creates a six-object copper, porcelain, petrol and ink still-life through the
real macOS editor. Native Accessibility locates controls; Quartz moves the
pointer and types. The AppKit sidecar displays lines from the executing
`scenario.py`, with runtime assertion results. Project JSON is only read after
the app saves it.

## Requirements

- macOS 14+, Swift 6+/Xcode, graphical login and a working Metal GPU.
- Python 3.12 with the pinned packages in `requirements.txt`.
- Accessibility and Screen Recording access for the automation host.
- A 2400×1350 main display; the optional helper uses private macOS
  virtual-display APIs and may not work on every macOS release.
- One screen recorder with cursor capture. FFmpeg is suitable.

The application has no third-party Swift dependencies. Python packages are
isolated demo dependencies.

## Prepare

Run commands from `creative-suite`:

```sh
export VENV="$HOME/.venvs/creative-suite-native"
python3.12 -m venv "$VENV"
"$VENV/bin/python" -m pip install -r demos/space/requirements.txt

swift build
swift test
export DEVIN_DIST="$HOME/Desktop/SpaceDemoApps-$(date +%s)"
bash scripts/build-apps.sh release
open -n "$DEVIN_DIST/Devin Space.app"

export EVIDENCE="$HOME/Desktop/SpaceEvidence-$(date +%s)"
mkdir -p "$EVIDENCE"
```

Use a fresh app destination; never replace a running executable or rebuild
tracked `dist`. Close other Space windows before a take. Do not run the broad
suite verification while recording, because it opens other workspace windows.

If a matching display is unavailable, compile and run the optional monitor
helper in its own terminal, keeping it alive until capture is finished:

```sh
clang -fobjc-arc -framework AppKit -framework CoreGraphics \
  demos/space/wide-display.m -o "$EVIDENCE/wide-display"
"$EVIDENCE/wide-display"
```

It temporarily moves the original monitor to the right. Check the actual
main monitor before recording; do not assume a recorder follows this change.
Keep the virtual monitor alive if the final app should remain visible.

Launch the sidecar in another terminal using the same `VENV` and `EVIDENCE`:

```sh
"$VENV/bin/python" demos/space/sidecar.py "$EVIDENCE/live-state.json"
```

## Record and run

In Devin, use the built-in testing agent with `test_mode`, a focused test plan,
and `recording_start` / `annotate_recording` / `recording_stop`. Keep the native
app on the left and the executing-source sidecar on the right for the entire
capture.

Start one recorder on the main monitor with the pointer visible. In the
scenario terminal, use a fresh take directory:

```sh
SPACE_EVIDENCE="$EVIDENCE/take-$(date +%s)" \
  "$VENV/bin/python" demos/space/scenario.py
```

Run ordinary Python, without `-O`: the saved-property readback uses assertions.
The script arranges the app on the left, creates and edits the scene, orbits
and dollies using Option-scroll, saves the export camera, saves/closes/reopens
the project, then exports PNG and SceneKit. Leave the complete scene visible
for the closing hold, then stop recording. An exception stops the script and
records failure.

Outputs include `ORBIT.devin`, `ORBIT.png`, `ORBIT.scn`, full-desktop screenshots,
and `assertions.json`. The renderer exports 1600×1200 pixels. Video is captured
by the recorder separately; this script does not synthesize application frames.

Inspect the resulting video at several points, including the native color
panel, held orbit, save/reopen and closing view. Ensure source lines are readable
and the run's duration matches the evidence timestamps. The recorded reference
run completed 47 runtime checks. Orbit/dolly and visual composition require
separate pixel review; the numeric count does not imply
those visual assertions ran automatically. Native SceneKit loading was checked
separately; external-editor compatibility was not tested.

With the default SceneKit camera controls, plain scroll pans the view.
Option-modified scroll performs a dolly: three positive line events move the
camera away from the scene. Verify reduced object size and camera movement along
the view direction, with unchanged camera orientation and field of view.

Some AVFoundation recordings report misleading average-frame-rate metadata.
If recorder post-processing produces an implausibly short clip, preserve the
raw segments. Re-encode using their original timestamps and a constant output
frame rate, without speed filters or deleted action intervals.

## Source checks

```sh
"$VENV/bin/python" -m py_compile demos/space/*.py
clang -fobjc-arc -Wall -Wextra -Werror -fsyntax-only demos/space/wide-display.m
```

There is no configured repository formatter gate. No application source or
packaged binaries are modified by this demo.
