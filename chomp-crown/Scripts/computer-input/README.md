# Chomp Crown: executable two-player computer-use test

This is an **external adaptive OS-touch runner**, not an MP4 replay and not the
app's built-in Hunter/Runner driver. Both unchanged native iOS clients compete
against each other with the same independent planning policy.

## Dependencies

- macOS with a logged-in GUI, Xcode command-line tools, iOS simulator runtime,
  Swift compiler, Python 3 (stdlib only for gameplay), Node 22+, and FFmpeg.
- Built Release simulator app at
  `build/Build/Products/Release-iphonesimulator/ChompCrown.app`.
- Existing server dependency: `npm ci --prefix Server`.
- Two **independent** caller-selected simulators. Copy `devices.example.json`
  outside this source directory and replace both placeholder UDIDs using
  `xcrun simctl list devices available -j`. Pass its path with `--devices`.
  There are no embedded VM-specific UDIDs. Exact device names/runtime/type IDs
  are resolved from `simctl`, and duplicate/unavailable UDIDs or ambiguous device
  names are rejected before creating the output or touching either app.
- Geometry support is explicitly limited to portrait **iPhone 17 Pro / Pro Max**.
  The installed device-type `profile.plist` supplies point width as
  `mainScreenWidth / mainScreenScale` (tested 1206/3=402 and 1320/3=440).
  If that metadata is missing, the config must provide the documented
  `pointWidth`; conflicting supplied/profile widths are rejected. This does not
  silently promise geometry support on other models, orientations or UI layouts.
- Accessibility, event-posting and screen-recording permission for the invoking
  terminal/helper. The runner checks `AXIsProcessTrusted`,
  `CGPreflightPostEventAccess`, and `CGPreflightScreenCaptureAccess`.
- Enough desktop space for both complete portrait simulator windows.
  This run uses a 1600×1200-point desktop. Do not resize/move/minimize the windows
  or interact with the mouse during the test.
- For `--record`: BlackHole must already be the working default input/output,
  48 kHz stereo. Verify with `system_profiler SPAudioDataType`; reboot simulators
  if they were started before the audio endpoint existed. Do not restart audio
  services during capture.

The bundle runs locally without credentials, a browser, Python mouse package,
Devin API token or private SDK. It uses macOS **Quartz CGEvent** mouse events,
AppKit/Accessibility window discovery, and Vision text recognition.

## Run

From this directory:

```sh
python3 runner.py \
  --repo /path/to/chomp-crown \
  --devices /path/to/your-devices.json \
  --out "$HOME/chomp-run-1" \
  --record --screen-index 0
```

The output directory must not already exist; its parent must exist. Port 8873
must be free. The script refuses to kill an unrelated existing server.
`--port` changes the local server/listener and both client launch addresses.

Verify the screen capture index before recording:

```sh
ffmpeg -f avfoundation -list_devices true -i ''
```

For a planning/execution boundary, the following performs **the exact same**
setup and play functions without creating a second room or replaying a match:

```sh
python3 runner.py --repo /path/to/chomp-crown --devices /path/to/your-devices.json \
  --out /path/to/NEW-RUN --prepare-only
# Inspect the prepared lobby; do not click Ready yourself.
python3 runner.py --repo /path/to/chomp-crown --out /path/to/NEW-RUN \
  --resume --record --screen-index 0
```

`--resume` requires that prepared room still be in the lobby. It is not a
retry/resume mechanism for a partly played match. Default match deadline: 200s.
Resume uses persisted device metadata; optional `--devices`, `--port`, and
`--repo` must agree with it. Changed device names/runtime/type/width, changed
source hashes, or conflicting overrides are rejected rather than silently mixed.
If a natural match does not finish within it, the test fails. Two natural matches
are played; the audio duration is twice the per-match deadline plus 100 seconds.
The runner waits for normal audio completion/file flush after stopping video.

## What executes

1. Compile `mouse.swift` if needed; check OS permissions.
2. Start the unchanged `Server/server.mjs` factory on loopback through
   `observe-server.mjs`; boot/install/launch the two existing native simulator
   apps with unbuffered native logs, **without `--autoplay` or `--auto-ready`**.
3. Create/join the real room using ordinary startup connection arguments.
   All Ready, D-pad, swipe and Rematch actions are real OS mouse events.
4. Discover named Simulator windows and complete device-screen bounds with AX.
   Place them side-by-side. Take native screenshots and use Vision OCR to find
   visible button text. The native iOS button AX tree is not exposed in the
   macOS Simulator AX tree on this setup.
5. Find visible `STEER`, then derive the D-pad's 46×42-point button layout from
   its inspected SwiftUI geometry. Fail if targeting doesn't advance both
   clients' accepted sequences. This is a **layout dependency**, not hidden
   state mutation. Logs contain the exact calibration and event coordinates.
6. Hold a real maze swipe on each phone and save the desktop **before release**.
7. Replan repeatedly from actual maze/pellets/powers/positions using Dijkstra
   costs/rewards and hazards; interleave real clicks for both live players.
   Plans change with observed game state, not a recorded event sequence.
8. Observe a natural first-to-two result. Verify both native result screens
   by OCR, and save full desktop evidence.
9. Click one Rematch and verify waiting; click the second and verify initial
   round, scores, crowns and winner reset. Continue the same external two-player
   control loop to a second natural first-to-two result on both screens.

## Read-only telemetry boundary

`observe-server.mjs` calls the existing exported `createServer()` and observes
`service.rooms.values()` via `game.snapshot()`. The unchanged server owns its
real sockets, players and tick loop. The observer adds no spectator/player and
never calls `input`, `ready`, `step`, or changes game fields. The Python runner
contains no WebSocket connection or game protocol send. Gameplay input only
occurs inside `mouse.swift` through mouse-down/up/drag events on visible controls.

## Assertions and evidence

`source-manifest.json` records every script/document/config SHA-256 plus harness,
Python, Node, Swift, Xcode, FFmpeg and macOS versions. `tested-source/` preserves
the exact source files. No environment-variable dump, credentials or secret
values are collected. Do not edit source between prepare and resume.

The Swift helper accepts `Decodable Command` records and returns typed
`Encodable Response`, `Frame`, `WindowRecord` and `TextRecord` values. Missing,
mistyped, nonfinite or out-of-viewport coordinates produce JSON error responses.
CFTypeRef bridging remains confined to the native AX API boundary.
The bundled `capture-audio.swift` retains the supplied AVAudioEngine input-tap
capture path with a typed `Encodable AudioBufferRecord` replacing its dictionary
serialization. The exact bundled source is compiled and captured in this run.

`results.json` contains pass/fail assertions and per-peer metrics. Failures raise
and exit nonzero, preserving evidence. Required per-peer progress:
at least 20 D-pad clicks, 20 native touch-log entries, 20 accepted sequence values,
10 different sampled positions and nonzero score. Native log sources must be
exactly `touch`. The setup checks absence of built-in driver labels and persists
all launch commands. Neither opponent is intentionally idle.

Result assertions join spatially adjacent Vision words within the centered
result modal. The heading, expected winner and Rematch must appear in that order;
a matching player name in the HUD is insufficient. The captured split-heading
regression and negative cases run without GUI access:

```sh
python3 -B -m unittest discover -s . -p 'test_*.py' -v
```

Artifacts include `actions.jsonl` (actual host clock/event coordinates/plans),
`observations.jsonl` (read-only snapshots), native `gold.log`/`rose.log`,
`server.log`, `session.json`, calibration, native/OCR screenshots,
full-desktop held/gameplay/winner/waiting/reset screenshots, final outcome and
reset snapshots. `--record` also produces raw screen video, input-tap CAF,
per-buffer host/sample timestamps, capture metadata and FFmpeg timestamp logs.
Keep originals. Video/audio must be aligned from **actual** demuxer/buffer host
timestamps, not process launch times or a generated soundtrack.

## Limitations and cleanup

- This is local simulated touch on two iOS simulators, not physical devices,
  WAN, 3–4 players, long disconnects, subjective listening or exact arcade parity.
- A computer-control planner sees read-only game telemetry, not only pixels.
  It has no ability to force score, health, phase, winner or outcome.
- Mouse events are interleaved on one OS pointer, not literally simultaneous
  fingers. Both clients move continuously over separate real WebSockets.
- D-pad geometry/OCR depends on the current app layout and supported device
  sizes; calibration failure is a test failure, not silently bypassed.
- Prior audio evidence had continuous tap timestamps but unexpected zero-content
  spans. This runner does not claim that timestamp continuity proves uninterrupted
  upstream playback. Every new recording needs its own signal/media validation.
- Leave the two apps/server open for live inspection. Reusable cleanup:
  `python3 runner.py --out /path/to/RUN --cleanup`.
  It verifies that `serverPID` still matches the saved observer script and exact
  output path before sending SIGTERM; stale/reused PIDs are rejected.
  App termination is optional:
  `xcrun simctl terminate UDID games.chompcrown.neon`.
- No source in the application repository is modified by this test.
