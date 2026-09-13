# Starcap: real computer-use multiplayer test

Tested against app revision **6ba1912** on macOS, Xcode 26.6 / iOS 26.5.
This external Python test executed 268 visible mouse actions and passed 13
runtime assertions. The committed runner has only formatting/import layout
changes from that tested script.

## How it works

The dependency-free Python runner posts real CoreGraphics mouse move/down/drag/up
events to the two visible Simulator windows. A one-pixel held drag triggers
SwiftUI's normal HoldControl. GAS and steering are time-sliced between devices;
BRAKE is exercised on both; acquired ITEM buttons are tapped. The game's normal
clients send their own inputs. The runner does **not** open a WebSocket, send
gameplay messages, or mutate game state.

`GET http://127.0.0.1:8791/rooms/CODE` is polled read-only for position, heading,
speed, track, items, and outcomes. A simple waypoint policy uses this telemetry
to select mouse controls. This is feedback-guided UI automation, not vision-only
gameplay. There is only one global mouse: do not move it or change windows while
the runner is active.

## Dependencies and permissions

- macOS with Xcode, iOS simulator runtime, Node, Python 3 (tested 3.9.6).
- No pip packages, idb, or cliclick needed.
- Grant the launching terminal/automation host **Accessibility** and **Screen
  Recording** under System Settings > Privacy & Security.
- CoreGraphics must report `AXIsProcessTrusted() == true`; otherwise the runner
  exits. Screen Recording is needed for screenshot evidence.
- No credentials/secrets needed for this localhost test.
- Build the app using the [workspace README](../../README.md). Run the commands
  below from the `starcap-circuit/` directory.

## Start the server and two manual-only apps

In a dedicated terminal, run:

```sh
node server/server.mjs
```

Use a fresh room code for each run (for example `TOUCH2`). Boot two devices
listed by `xcrun simctl list devices available`, install, and launch:

```sh
A=691C57A7-98F5-4C32-A5AF-3074F4F0FBA3
B=607A62B2-D5BF-40A7-B59F-1A5B65CB2DE1
APP="$PWD/build/Build/Products/Debug-iphonesimulator/StarcapCircuit.app"
ROOM=TOUCH2
open -a Simulator
for ID in "$A" "$B"; do
  # Skip boot if already Booted.
  xcrun simctl boot "$ID"
  xcrun simctl bootstatus "$ID" -b
  xcrun simctl install "$ID" "$APP"
  # It is harmless if terminate says the app was not running.
  xcrun simctl terminate "$ID" com.dabit.starcapcircuit
done
xcrun simctl launch "$A" com.dabit.starcapcircuit -room "$ROOM" -name PipTouch -racer 0 -track 0 -server ws://127.0.0.1:8791
xcrun simctl launch "$B" com.dabit.starcapcircuit -room "$ROOM" -name MochiTouch -racer 1 -track 0 -server ws://127.0.0.1:8791
```

**Never add `-autodrive`, `-autojoin`, or `-autoready`.** Start unjoined in the
garage. The runner clicks JOIN and READY itself. Ensure no other client occupies
the room. Do not reuse the finished run's lobby without relaunching/resetting.

## Calibrate geometry before running

Both complete displays must remain visible. Rotate each simulator to landscape
using Device > Rotate Left/Right, then resize/position them. The recorded setup
used a 1600x1200 desktop, Simulator A above B at left, and Safari status at right.
See the [recorded layout](https://app.devin.ai/attachments/3095fc64-f787-4ad0-9857-edf32e6e525d/ss_7e53d378.png)
for the reference geometry. The supplied UDIDs are examples from the tested host;
replace them with two available devices.

`geometry.json` contains control coordinates in a 1024x768 reference image,
multiplied by `coordinate_scale: 1.5625` for actual Quartz desktop coordinates.
On another desktop, set scale to 1 and enter actual screen coordinates instead,
or use the appropriate scale. Configure each player's `name`, `udid`, and
JOIN/READY/LEFT/RIGHT/BRAKE/GAS/ITEM/REMATCH centers. `window` and `udid` are
descriptive; the runner does not automatically find or arrange windows.
Controls must not be covered by dialogs. Names must match launch arguments.
The UI must visibly show **AUTO DRIVER: OFF** once joined.

Optional live step panel (separate terminal):

```sh
cd scripts/computer-use
python3 -m http.server 8793 --bind 127.0.0.1
open -a Safari 'http://127.0.0.1:8793/status.html?run=run-02'
```

Place Safari at the right without covering the simulators. Chrome was unavailable
on the recorded host; Safari worked.

## Run

Start Devin's `recording_start` before the command, then use
`annotate_recording` to mark the join/controls, race outcome, and rematch.
Those Devin tools are session tools, not a CLI dependency of the Python runner.

```sh
python3 scripts/computer-use/runner.py \
  --room TOUCH2 \
  --config scripts/computer-use/geometry.json \
  --output scripts/computer-use/run-02 \
  --start-delay 8 --timeout 170
```

Allow about 2–3 minutes. The output directory must be new. Stop with Ctrl+C if
something obstructs either simulator. The runner releases the mouse in `finally`.

### Expected results / exit status

Exit **0** requires all of:
1. Distinct guest UUIDs and racers 0/1.
2. One ready player cannot start; both ready produce countdown.
3. Both GAS probes increase speed >5 units/s.
4. Both BRAKE probes reduce speed >5 units/s.
5. Both real steering holds change heading >0.04 radians.
6. Both finish with `finish > 0`, `gate == 17`, `lap == 2`, ranks `{1,2}`.
7. Both acquire and use at least one item.
8. Native REMATCH switches track and clears both readiness flags.

A missing response, timeout, DNF, failed assertion or exception produces a
nonzero exit, `failure.png`, and failure details. The controller is intentionally
simple: window geometry, OS scheduling and available resources can affect racing.
It is not guaranteed to win or finish every course. Never enable AUTO to recover.

### Evidence and limitations

- `actions.jsonl`: timestamp, control/hold/coordinates, authoritative before/after.
- `snapshots.jsonl`: timestamped read-only room state.
- `assertions.json`: machine assertions with actual values.
- `results.json`, step screenshots, `status.json`.
- `run-01.log`: original command output from the verified run.
- AUTO state is **visually checked**, not machine-enforced: room telemetry does
  not expose it. The runner never targets the toggle. Stop if AUTO is seen ON.
- DRIFT/multitouch is not tested: one mouse cannot simultaneously hold drift
  and steer. A second full course and reconnect/audio checks are outside this
  fresh follow-up; the test ends after rematch to Neon.
- Native Devin recording on this host had no audio stream. Prior music evidence
  is separate; no soundtrack was added.
- Validate tool exports, not just file existence. This run's `recording_stop`
  edit was heavily time-compressed to 14.79 seconds. Frame inspection confirms
  garage, racing, results and rematch remain in sequence. An initial sparse
  extraction sampled its middle and incorrectly suggested a missing beginning;
  1-second sampling corrected that diagnosis. Original native MKVs retain the
  full 154.8 seconds. They are preserved;
  `full-native-recording.mp4` is a normal-speed, lossless remux of those two
  consecutive segments, not a composition of separate runs. The actual short
  tool artifact and genuine source-time annotations are delivered separately.
  Annotation overlays were not apparent in decoded pixels of the short MP4;
  the tool's annotation JSON is authoritative for those events.

The original script, logs, screenshots and recording metadata are available in
the [verified evidence bundle](https://app.devin.ai/attachments/888b4d7a-f494-4ba9-9293-0482de4b16b6/starcap-computer-use-test.zip).

## Script checks

The runner uses only the Python standard library. For development linting:

```sh
python3 -m pip install ruff==0.12.12
ruff check scripts/computer-use/runner.py
ruff format --check scripts/computer-use/runner.py
python3 -m py_compile scripts/computer-use/runner.py
```
