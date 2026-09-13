# Reproducible external two-iPhone GUI test

This test drives the **actual Simulator UI**, not the app's `--autoplay` driver.
macOS Accessibility is used only to read target bounds (and position/raise
Simulator windows). `GUIInput.swift` sends actual mouse-down/up CGEvents and
System Events keyboard input. It never calls `AXPress`, `accessibilityActivate`, game methods or
WebSocket tap messages. UIKit `TouchMatrix.touchesBegan` generates the inputs.

The bundled public chart and passively observed authoritative epoch schedule the
external clicks. This is **programmatic computer input**, not visual AI rhythm
perception or human play. A single macOS pointer serializes both players. Only
one cell per authored instant is attempted; extra chord cells are deliberately
skipped. NOVA aims 20 ms early; ECHO aims 75 ms late and skips every fifth target.
Actual scheduling/input error is recorded. This is not precise multitouch.

## Dependencies and permissions

- macOS with Xcode/iOS Simulator, command-line tools (`xcrun`, `swiftc`, `simctl`).
- Python 3.9+ (standard library only), Node 22+ and `server/node_modules/ws`.
- A built `ai.prismsixteen.game` iPhone Simulator app; use the main README build
  instructions or pass `--app /absolute/path/to/PrismSixteen.app`.
- Accessibility permission for the terminal/execution host and compiled helper;
  Screen Recording permission for screenshots. Grant in System Settings >
  Privacy & Security if the test reports denied access.
- Two **different, uniquely named** iPhone simulator devices. The harness boots
  them, installs and launches the apps and starts its own real WebSocket server.
- Open both device windows in Simulator. Resize them if necessary so their
  complete windows fit the main display with 120 points for menu/dock margins.
  The harness lays them out side-by-side and refuses overlapping/off-screen
  layouts. No private paths or fixed panel coordinates are required.
- Port 43116 must be free (or use `--port`). The harness never kills another
  service.

```sh
cd prism-sixteen
(cd server && npm install)
xcrun simctl list devices available
python3 scripts/gui-two-player.py \
  --device-a YOUR_FIRST_UDID \
  --device-b YOUR_SECOND_UDID \
  --output artifacts/my-fresh-gui-run
```

The output directory must not already exist. Run from any working directory;
paths to the app, catalog, observer and helper are resolved relative to this
script. `--rounds 1` runs one full match; default is two complete rounds.

The harness:
1. Launches clean selection screens **without** autoplay/create/join flags.
2. Types NOVA/ECHO using native text fields; clicks BASIC, CREATE and JOIN.
3. Tests the first-player-ready gate, then clicks the second native ready button.
4. Reads each of the 16 native panel bounds and schedules real host mouse events.
5. Captures moving-gameplay/results screenshots and checks shared network state.
6. Clicks both actual REMATCH controls and repeats.
7. Writes pass/fail assertions and exits nonzero on failure.

**Do not use the mouse or move/resize windows while the scheduler is playing.**
If a target moves or cannot be found, abort and rerun in a new evidence directory.
Scores are not deterministic: OS scheduling/focus/Simulator latency are real.
Both players must score at least 15 notes per round. Failures remain visible in
`assertions.json`; they are never rewritten as passes.

## Recording the same run

To start recording after setup but before GUI interaction, pass
`--wait-for-start`. When the console prints `READY`, begin your continuous
desktop recorder with both complete displays and the cursor visible, then:

```sh
touch artifacts/my-fresh-gui-run/START
```

There is a bounded five-minute recording-setup wait. Record the entire lobby,
countdown, two matches and outcomes at real-time speed. For actual native audio,
configure a working BlackHole 2ch input/output **before booting the simulators**
and record its concurrent loopback. A silent desktop recorder is not audio
evidence. Do not add the bundled music as a replacement soundtrack.

Devin's run used a separate ScreenCaptureKit/native PCM recorder; the test
script itself does not depend on a recording service or any prior artifact.
The same-run native capture source, raw PCM/video and mux timing provenance are
delivered with its evidence. Ordinary macOS recording can also be used.

## Evidence and cleanup

- `gui-events.jsonl`: all AX discoveries and actual requested/completed CGEvents.
- `round-N-schedule.json`: reproducible public-chart target times and cells.
- `wire.jsonl`: all non-ping real traffic, tokens redacted; observer sends nothing.
- `server.jsonl`: real authoritative server events.
- `player-N.log`: unbuffered native logs; absolute simctl output paths.
- `assertions.json`: fail-fast runtime results.
- `provenance.json`: exact launch commands, devices, window bounds and outcomes.
- PNGs: full desktop selection/lobby/countdown/gameplay/results.
- `round-N-player-N-results-ui.json`: actual native accessibility result text.

Both apps and the **test-owned server remain alive** after completion for
inspection. Stop only that server when finished:

```sh
kill "$(cat artifacts/my-fresh-gui-run/server.pid)"
```

The observer handles SIGTERM and flushes the logs. Because a live server can
append evidence, finalize log hashes only after stopping it; `sha256.json`
intentionally excludes live JSONL/log files. The script does not shut down
simulators or leave the result screens.

Secrets needed: **none**. This is a local guest WebSocket flow.
