# Two captains played by real macOS pointer input

`play_os.py` + `Pointer.swift` are a runnable computer-use test, **not the
in-app CaptainDriver**. Python observes the public room snapshot via HTTP GET;
Swift posts `CGEvent` mouse movement/down/up to the macOS HID event stream.
The app receives its normal visible button/drag gestures and sends its own
ordinary input messages. The harness never writes WebSocket commands, opens
gameplay URLs, changes game state, or selects an outcome.

Run from the repository to record its Git revision in the manifest. An extracted
source bundle also runs; it records `unversioned` and source-file SHA-256 hashes.

## Prerequisites

- macOS, Xcode/Simulator with two bootable iPhones, Swift compiler, Python3
  standard library, Node server dependencies, FFmpeg with AVFoundation.
- Build the native application following `../README.md`. This harness does
  not build/modify the game.
- Grant the launching terminal/agent Accessibility (OS event posting),
  Screen Recording, and Microphone access. `Pointer.swift` checks event access.
- BlackHole2ch must be the default output **before booting simulators**:
  `system_profiler SPAudioDataType`. Installation, if needed:
  `brew install --cask blackhole-2ch`. If no endpoint appears, restarting CoreAudio may
  be needed; restart simulators that booted before the endpoint existed.
- No account, token, or secret is needed for localhost guest multiplayer.

## Start two manual clients

From `hive-sovereign`:

```sh
# Separate terminal; leave running:
(cd server && npm start)
```

After confirming the audio endpoint, replace these example UDIDs with two
available devices from `xcrun simctl list devices available`:

```sh
AZURE=691C57A7-98F5-4C32-A5AF-3074F4F0FBA3
AMBER=607A62B2-D5BF-40A7-B59F-1A5B65CB2DE1
APP=.build/Build/Products/Debug-iphonesimulator/HiveSovereign.app
xcrun simctl boot "$AZURE"      # omit if already booted
xcrun simctl boot "$AMBER"
xcrun simctl bootstatus "$AZURE" -b
xcrun simctl bootstatus "$AMBER" -b
xcrun simctl install "$AZURE" "$APP"
xcrun simctl install "$AMBER" "$APP"
open -a Simulator
xcrun simctl launch "$AZURE" ai.hivesovereign.native \
  --name Azure --create --server ws://127.0.0.1:8789
# Read the actual room code from Azure's visible lobby; replace ROOM below.
xcrun simctl launch "$AMBER" ai.hivesovereign.native \
  --name Amber --room ROOM --server ws://127.0.0.1:8789
```

Terminate existing app instances first if you need fresh launch arguments.
**Never add `--autopilot`.** The script rejects either live app process having
that flag and verifies the two configured simulator UDIDs against process paths.
Both peer names should match the config, with Azure team0 and Amber team1.

## Layout and audio calibration

The example is calibrated for one **1600×1200 desktop**, two full landscape
simulator windows stacked left, and the visible status panel at right:

| Client | Simulator | Window origin, macOS points |
|---|---|---|
| Azure/top | iPhone17 Pro | `(5,28)` |
| Amber/bottom | iPhone17 Pro Max | `(5,590)` |

Use Simulator's Device → Rotate Left if the landscape game is sideways inside
a portrait frame. Hide the Dock and prevent other windows/notifications from
covering either phone. Do not resize, move, or rotate windows during the run.
Coordinates in `layout.example.json` use a **1024×768 reference desktop** and
are scaled by the Swift helper to the actual display. Window scale changes
require recalibration; this is not image-recognition targeting. The complete
screen must stay within the left64% because the right side contains the panel.

Calibrate `focus` on a harmless **in-game header**, NOT the Simulator titlebar.
Titlebar clicks can become window drags on a busy VM. `queen`, `left`, `right`,
`jump`, and `action` must land on the visible controls. Keep the calibrated
reference size1024×768; change coordinates/UDIDs in a copied config as needed.

For the first calibration match, ready both players normally, mute Amber using
the visible speaker icon, and leave Azure unmuted. At the result screen verify
Azure shows speaker waves and Amber shows speaker slash. Do not relaunch or
toggle sound during the final match: mute state is in-memory, not persistent.
This preliminary match is **not** the recorded manual-captain proof.
The final script starts a real rematch and drives both queens.

Verify AVFoundation source indices (they are machine-dependent):

```sh
ffmpeg -hide_banner -f avfoundation -list_devices true -i ''
# The intentional enumeration command exits with an input error after listing.
# Example: video0 Capture screen0; audio0 BlackHole2ch -> config "0:0".
ffmpeg -hide_banner -f avfoundation -i ':0' -t 3 -af volumedetect -f null -
```

Require nonzero real PCM; on this VM Azure-only music measured −49.6dBFS.

## Run

The output parent must exist and `--out` must name a **new** directory.
Keep hands off the shared mouse during execution.

```sh
python3 Tools/play_os.py --room ROOM \
  --config Tools/layout.example.json \
  --out /Users/devin/hive-evidence/NEW-RUN
```

Actual validation invocation for application revision839efbc:

```sh
python3 Tools/play_os.py --room 89FD4 \
  --out /Users/devin/hive-evidence/run-os-input-839efbc/match-1
```

Room codes and output paths are run-specific; use a fresh room/current result
and a new output directory when reproducing. `--server` overrides the read-only
HTTP origin; `--timeout` bounds active gameplay (default180wall seconds).

The script compiles the helper into the evidence directory, starts one
desktop+BlackHole recorder, logs readiness, selects Q on each client, then
alternates move/jump/dive and gate-navigation gestures before rival pursuit.
Unselected units remain visibly labeled AI and execute current team orders
(both ECONOMY in the validated run). **AI may collect/deposit the winning berries or decide the outcome**;
the test does not claim two entirely human-controlled five-unit armies.

## Results and limitations

- `actions.jsonl`: every native gesture's target/control/coordinates/hold and
  actual down/up wall times. These prove dispatch, not application success.
- `telemetry.jsonl`: timestamped unmodified read-only room observations.
- `assertions.json`: separate per-team human Q, |vx|>100, vy>100, diving,
  owned gate within27world pixels of human Q, >30new inputs and real result.
  Exit0 requires these observed checks; exit1 preserves failures.
- `manifest.json`: revision, source hashes, exact live launch args and config.
- `capture-meta.json`, `capture.log`: real recorder timing and diagnostics.
- `live-desktop-audio.mov`: simultaneous full-desktop H.264/PCM recording.
  `status.txt` is the visible live annotation panel; actions/telemetry provide
  matching timestamps. No independent simulator streams are composited.

**One mouse cannot provide simultaneous multitouch.** The script alternates
captains and uses sequential jump→dive, not simultaneous move+jump. It uses
read-only server coordinates to choose subsequent OS actions. There is no
keyboard gameplay mapping or hidden in-app driver fallback.

The automatic assertions do **not** certify rendered UI agreement or audio.
Inspect both complete result screens and check the actual media separately.
Timestamp-aware resampling may insert short silences; quantify these, do not
describe the recording as gapless without measuring it.

To create a shareable MP4 without adding any soundtrack:

```sh
ffmpeg -i NEW-RUN/live-desktop-audio.mov -c:v copy -c:a aac -b:a 128k \
  -movflags +faststart NEW-RUN/two-devices-os-input.mp4
ffprobe -v error -show_streams -show_format -of json NEW-RUN/two-devices-os-input.mp4
ffmpeg -v error -i NEW-RUN/two-devices-os-input.mp4 -f null -
```

Inspect ready, moving gameplay and result frames; require video+audio streams,
full decode, duration agreement within0.3s, and nonzero PCM during gameplay and
result. The supplied evidence bundle reports these independently.
