# Two-player native computer-use evidence helpers

These helpers emit **Devin `functions.computer` payloads**. They do not call Devin,
dispatch GUI events, or autonomously play the game. A Devin session with the real
native computer tool must dispatch every batch, inspect its returned screenshot,
and then commit it. There is **no standalone GUI-input runner** in this package.
The game is cooperative PvE, not PvP.

`action-plan.json` contains normalized gesture recipes from a real two-player
flow; `regression-action-plan.json` contains room-transition/reconnect recipes.
They are not state-aware macros: inspect after every batch, adapt timings and
positions, and skip recovery batches unless needed. The files contain no result
claims. The run-specific trace/screenshots are separate evidence.

## Prerequisites

- macOS, Xcode with a working iOS Simulator runtime; build/install the current
  Release app using the workspace README. Use two distinct landscape simulators
  with uniquely named windows. Do not reuse device UUIDs from past reports.
- Node dependencies: `npm --prefix Server install`. Start the ordinary server
  with a fresh existing directory: `LOG_PATH="$OUT/server.jsonl" node Server/server.mjs`.
  Check port 8791 for a stale identified test listener before starting another.
- Python 3, FFmpeg/FFprobe; NumPy for audio analysis. The host uses Python 3.9.6.
  Create a local virtualenv and install the pinned analysis dependency:
  `python3 -m venv Scripts/computer-use/.venv`, then
  `Scripts/computer-use/.venv/bin/pip install -r Scripts/computer-use/requirements.txt`.
- Accessibility/Automation permission for reading Simulator window geometry;
  screen-recording permission for FFmpeg; microphone permission for native PCM.
- BlackHole 2ch must appear in `system_profiler SPAudioDataType` as default
  input/output/system output at 48 kHz stereo **before simulator boot**. See
  the workspace README for installation and safe endpoint-recovery guidance.
  Silence unrelated audio sources. Do not restart CoreAudio during capture.
- An actual Devin native computer runtime. Emitting JSON is not input dispatch.

Commands below run from the Voxel Vanguard workspace. Choose a fresh `$OUT`
inside `Scripts/computer-use/.runs/` and create it before using these commands.
`$PY` denotes the NumPy virtualenv's Python.

```sh
swiftc Scripts/computer-use/audio-capture.swift -o Scripts/computer-use/audio-capture
swiftc Scripts/computer-use/clock.swift -o Scripts/computer-use/clock
python3 Scripts/computer-use/gui.py --out "$OUT" inspect
```

Discover booted devices/windows with `inspect` and `xcrun simctl list devices`.
Install using their freshly discovered IDs. Launch with `-name Aster` / `Bramble`,
`-room "$ROOM" -automation -autoRematch`, omitting `-host`/`-join` for entry UI.
If testing a cursor regression, install once first, then keep **both app PIDs
unchanged** across Leave/new-room transitions.

Turn both visible drivers OFF before primary lobby assertions. The flag merely
makes the toggle available; it does not count as Devin input. At a result overlay,
an imprecise footer click can miss: inspect the label and `driver_disabled` log.
Allow landscape rotation to finish before calibration.

## Calibrate and dispatch

Arrange both **complete device displays** without overlap. Measure the physical
desktop size and each display rectangle in the tool's 1024×768 coordinate space
(excluding simulator chrome). Geometry is discovered afresh; no UUID is embedded.

```sh
python3 Scripts/computer-use/gui.py --out "$OUT" configure \
  --aster "$ASTER_DEVICE_NAME" --bramble "$BRAMBLE_DEVICE_NAME" \
  --desktop "$DESKTOP_WIDTH" "$DESKTOP_HEIGHT" \
  --aster-screen "$AX" "$AY" "$AW" "$AH" \
  --bramble-screen "$BX" "$BY" "$BW" "$BH"
python3 Scripts/computer-use/replay-plan.py --out "$OUT" list
python3 Scripts/computer-use/replay-plan.py --out "$OUT" \
  --set ROOM="$ROOM" emit P04-create-join
```

**Now dispatch the returned JSON as an actual `functions.computer` call.**
After viewing its returned screenshot:

```sh
python3 Scripts/computer-use/gui.py --out "$OUT" commit P04-create-join \
  --screenshot "$ACTUAL_RETURNED_SCREENSHOT"
```

Only commit a genuinely dispatched batch. A commit is an operator attestation,
not independent proof; retain screenshots, live recording and server/client logs.
Window movement is rediscovered, but resize/rotation requires fresh calibration.
Use `gui.py emit --help` for new batches; player-normalized gestures support tap,
hold, drag, text and keys. A drag payload takes a screenshot while held.
Coordinates are recipes for the tested landscape UI, not universal selectors.

Replay the regression with `--plan Scripts/computer-use/regression-action-plan.json`
and `--set OLD_ROOM=... --set FRESH_ROOM=...`. Choose unique fresh room names.
Do not blindly run all batches: readiness, natural damage, proximity, cooldowns,
and result state are checkpoints. In particular P13/P14 are conditional recovery
recipes, not proof of automatic rematch.

## Capture, observe, assert

Start the external clock panel outside both displays, set phase text, then capture:

```sh
printf 'GUI / DRIVERS OFF\nCreate / Join / Ready\n' > "$OUT/phase.txt"
Scripts/computer-use/clock "$OUT"
# In another shell:
python3 Scripts/computer-use/capture.py --out "$OUT" --screen-device "$DISPLAY_INDEX"
```

Discover the AVFoundation display index with FFmpeg's device listing. Add
`--native` only if separate native framebuffer streams are also desired; the
cursor-visible desktop is always captured. The clock panel must remain visible.
Do not rely on capture process start times as first-frame timestamps.

Before any driver enable, save the conservative GUI boundary:

```sh
python3 Scripts/computer-use/observe.py --out "$OUT" --room "$ROOM" \
  --snapshot gui-end-state.json
```

Update `phase.txt` before driver assistance; verify BOTH actual toggle labels and
client events. Observe movement/combat, equipment, victories and identity through
rematch. Preserve missed actions and recovery; don't relabel them as clean passes.
After results, stop capture without closing the apps and collect logs:

```sh
touch "$OUT/STOP"
# Wait for capture.py's audio/reference exit codes and file finalization.
python3 Scripts/computer-use/observe.py --out "$OUT" --room "$ROOM" \
  --collect --server-log "$LOG_PATH"
python3 Scripts/computer-use/assert-runtime.py --out "$OUT" --room "$ROOM"
node Scripts/assert-evidence.mjs "$OUT/server-room.jsonl"
```

If the server log already is `$OUT/server.jsonl`, omit `--server-log`. All HTTP
requests in these helpers are read-only GETs. Assertions require the primary
two-round flow and an actual pre-driver boundary. Missing prerequisites should
fail rather than invent a pass. They do not prove rendered visibility, automatic
rematch provenance, or superseded-packet rejection.

## Audio and final media

`audit-audio.py` analyzes original PCM, never generates an output soundtrack.
Supply JSON requests `{label, wall, pitch, expectCue, before?, duration?, threshold?}`.
Default correlation threshold is 0.7. Soundscape pitches: slash 130, bow 430,
hit 85, heal/equip/gem 780, artifact/slam 55, clear/victory 587, hurt/down 95 Hz.
An absence check is valid only with an independently verified quiet context.
Overlapping cues or a below-threshold match are inconclusive, not proof of silence.

```sh
"$PY" Scripts/computer-use/audit-audio.py --out "$OUT" --requests "$CUE_REQUESTS"
"$PY" Scripts/computer-use/validate-media.py --out "$OUT" \
  --reference-host "$MEASURED_HOST_AT_VIDEO_ZERO" \
  --start "$TRIM_START" --duration "$DURATION" --gain 4 --compose
```

Measure the visible HOST clock at several known desktop-video PTS values; record
the inferred zero point and spread. Choose a duration covered by both recordings.
Validation requires exact decoded/buffer frame equality, continuous sample
offsets, nonzero PCM, no clipping, and complete final audio/video decode.
Default gain 4 is +12.04 dB; no music is synthesized or substituted. Preserve raw
PCM/timestamps. AAC encoding and mixed simulator outputs are not separate stems.
30-fps desktop encoding does not establish game rendering FPS. Digital signal
checks do not establish subjective human listening or physical-device latency.

## Source checks

```sh
Scripts/computer-use/.venv/bin/pip install ruff==0.12.12
Scripts/computer-use/.venv/bin/ruff check Scripts/computer-use
Scripts/computer-use/.venv/bin/ruff format --check Scripts/computer-use
python3 -m compileall -q Scripts/computer-use
xcrun swift-format lint --strict Scripts/computer-use/*.swift
```
