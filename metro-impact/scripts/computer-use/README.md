# Metro Impact: actual native computer-use test

This runnable harness operates both native clients through desktop mouse events.
It records SHA-256 hashes of `computer_match.py` and `native_events.swift` in each
run's metadata so evidence can be checked against the exact input sources.
Keep those sources with your archived run. No app/gameplay instrumentation is needed.

## What executes

- `computer_match.py`: launches two installed native clients with lobby-prefill
  arguments only; clicks CREATE/JOIN, READY, held movement, LIGHT/HEAVY/WAVE,
  SOUND and AGAIN; reads server stdout to wait for actual outcomes.
- `native_events.swift`: standalone Cocoa/CoreGraphics mouse-event helper.
  Posts mouse move/down/drag/up to the real desktop, with a visible step panel.
  It does not link to the game and has no game/network input API.
- `verify_run.py`: read-only audit, input-log, source-hash, screenshot-OCR and
  media assertions. Never sends game requests.
- `inspect_result.swift`: Vision OCR of an actual full-desktop result screenshot.
- `compose_capture.py`: aligns the contemporaneous screen and live loopback using
  AVFoundation source timestamps. The final version decodes before trimming,
  avoiding concat-demuxer seeking.
- `screen-config.json`: physical desktop/window/control geometry used in this run.

There are **no `--auto`/`--driver` launch flags, combat deep links, injected
WebSocket actions, score writes or state forcing**. Both peers remain connected
concurrently. A single macOS pointer serializes their native control presses;
this is not simultaneous two-person multitouch.

## Prerequisites

- macOS, Xcode/iOS Simulator, Swift compiler, Node/npm, ffmpeg/ffprobe.
- Python **3.9–3.12** for the verifier's standard-library `audioop`; actual run:
  Python 3.9.6. The match script itself uses ordinary Python 3 stdlib only.
- Two installed native Metro Impact simulator apps, bundle ID
  `com.metroimpact.arcade`, built `.app` at
  `.build/Build/Products/Debug-iphonesimulator/MetroImpact.app`.
- Accessibility/event-posting permission for the launching process, Screen
  Recording permission for the screen recorder, Microphone permission for ffmpeg.
- BlackHole 2ch default output **before simulator boot**. Existing installation
  worked in this run; no new audio installation/restart was necessary.
- No credentials, signing account or cloud backend required.

From the repository's `metro-impact/` directory:

```sh
system_profiler SPAudioDataType
ffmpeg -hide_banner -f avfoundation -list_devices true -i ""
```

The device-list command normally exits nonzero after listing devices. This run
listed video 0 `Capture screen 0` and audio 0 `BlackHole 2ch`, 48 kHz stereo.
If missing, install `brew install --cask blackhole-2ch`. Only if still missing,
the previously verified bounded repair is `sudo -n killall coreaudiod`;
do not retry if it needs a password. Reboot simulators that started without the
endpoint. Never restart CoreAudio during a capture.

## Simulator preparation and calibration

Choose two available simulator UDIDs with `xcrun simctl list devices available`.
These were the devices used on the testing VM; replace them for another Mac:

```sh
ALPHA=113E2F1A-A37A-4546-A7AE-8A9CA23C7F89
BETA=344F44DD-0DA8-430F-BB5C-082ED148C77A
APP="$PWD/.build/Build/Products/Debug-iphonesimulator/MetroImpact.app"
# Boot only devices not already booted:
xcrun simctl boot "$ALPHA"
xcrun simctl boot "$BETA"
xcrun simctl bootstatus "$ALPHA" -b
xcrun simctl bootstatus "$BETA" -b
xcrun simctl install "$ALPHA" "$APP"
xcrun simctl install "$BETA" "$APP"
open -a Simulator
```

Pass the two selected UDIDs through `--alpha` and `--beta`; the script rejects
identical values. Do not edit archived run sources.
Use Simulator **Device → Rotate Left** as needed and arrange both landscape
windows without overlap. This run used a **1600×1200 physical desktop**:

| Window | x, y, width, height | Scene rectangle |
|---|---|---|
| Beta, top | 25, 45, 910, 518 | 124, 132, 714, 402 |
| Alpha, bottom | 25, 610, 910, 518 | 124, 697, 714, 402 |

`screen-config.json` contains window-focus and lobby button points. Recalibrate
all points if display scaling/window sizes differ. Coordinates are native desktop
pixels, **not** the computer tool's scaled 1024×768 coordinates. Keep the helper's
right-side status panel outside both complete displays. Close dialogs/other
media playback and do not move the pointer during the test.

## Build helper and start the real server

```sh
E="$PWD/scripts/computer-use"
RUN="$PWD/evidence/computer-use-run-01"
AUDIT="$PWD/evidence/computer-use-server.jsonl"
mkdir -p evidence
swiftc "$E/native_events.swift" -o "$E/native_events"
"$E/native_events" --preflight
```

Expected: `accessibility:true`, `postEvents:true`, `width:1600`, `height:1200`.
Resolve permission failures before executing. In another terminal, start one
server and retain stdout (do not start a second if port 8743 is already serving):

```sh
npm --prefix server start > "$AUDIT" 2>&1
```

Use the same variable values in each terminal. The script checks desktop size
against the calibration file before posting any clicks.

## Execute the native test

Start **one continuous desktop recorder first**. The actual run used Devin's
`recording_start(recording_id="metro-computer-use-match", hide_cursor=false)`,
which retained `*-raw-000.mkv` plus `ffmpeg.log`. Use the raw recording directory
reported by your recorder when composing; do not use an annotated/slowed preview.

From `metro-impact/`:

```sh
python3 "$E/computer_match.py" \
  --alpha "$ALPHA" --beta "$BETA" \
  --output "$RUN" --audit "$AUDIT" \
  --room MTRCG01 --app-revision "$(git rev-parse HEAD)"
```

For a rerun, change **both** output directory and room (e.g. `run-02`, `MTRCG02`).
Build/install the checked-out app before supplying that revision. Use `--server`
for a different WebSocket host, `--helper` for a separately compiled binary, and
`--config` for your calibrated geometry. The script refuses to overwrite an output
directory. It starts/stops independent
live PCM capture itself (`--audio-index 0`, configurable). Wait for `completed`,
then stop the desktop recorder. Expected elapsed time is about two minutes,
with a bounded 300-second combat timeout.

A standalone alternative to Devin's recorder is an ffmpeg desktop-only capture.
This recipe is provided for portability; the archived run used Devin's recorder:

```sh
SCREEN="$PWD/evidence/computer-use-screen"
mkdir -p "$SCREEN"
ffmpeg -hide_banner -f avfoundation -capture_cursor 1 -framerate 15 \
  -i "0:none" -an -c:v libx264 -preset ultrafast -crf 18 -pix_fmt yuv420p \
  "$SCREEN/screen-raw-000.mkv" 2>"$SCREEN/ffmpeg.log"
```

Run that in its own terminal before the match and stop with Ctrl+C afterward.
Use only one screen recorder and the match script's audio-only recorder. Confirm
the recorder log has an AVFoundation `start:` timestamp before proceeding.

## Evidence and read-only verification

Capture a real full-desktop `shared-outcome.png` while both result panels are
visible. Do not block the combat script with screenshot subprocesses. In this
run the screenshot was collected separately; alternatively extract the matching
result frame from the final video after checking its timestamp.

```sh
python3 "$E/compose_capture.py" --run "$RUN" \
  --screen-dir "$SCREEN"
# Set SCREEN to the actual raw directory when using Devin's recorder.
swift "$E/inspect_result.swift" "$RUN/shared-outcome.png" "$E/screen-config.json" \
  > "$RUN/result-ocr.json"
python3 "$E/verify_run.py" --run "$RUN" > "$RUN/verification-output.json"
open -a "QuickTime Player" "$RUN/two-player-computer-use.mp4"
```

The verifier checks source hashes against its own directory by default; use
`--sources` for a separately archived source directory. OCR uses window bounds
from the calibration file. Its score parser
normalizes O→0 **only inside numeric score fields**, retaining raw OCR text.
Visually verify both scores/winner; OCR is not a substitute for inspection.

Expected: two UUIDs, both actions/damage positive, one READY cannot start,
no automatic rematch, one AGAIN cannot reset, second AGAIN resets both HP to
100 and wins/actions/damage to zero, live audio >−50 dBFS during gameplay,
both-muted peak exactly zero, Alpha restored >−50 dBFS, full MP4 decode passes.

The raw audio ffmpeg exits `255` on the intentional SIGINT stop; this run's log
states `Exiting normally, received signal 2`, and its complete WAV/MP4 decode.
Inspect logs and assertions rather than treating that exit code alone as failure.

## Script checks

```sh
# Ruff 0.12.8 was used for the Python lint checks.
ruff check scripts/computer-use
python3 -m py_compile scripts/computer-use/*.py
xcrun swift-format lint --strict scripts/computer-use/*.swift
swiftc scripts/computer-use/native_events.swift -o scripts/computer-use/native_events
```
