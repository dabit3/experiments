# Two native players controlled by one external cursor

macOS-only runtime harness for Skyline Pulse. Tested against application revision
`c37197f`. No app source changes, autoplay, injected WebSocket input, or app-side
`Session.touch` automation. `gestures.swift` posts genuine CGEvent down/drag/up
events to Simulator; the app's `UITouch` callbacks produce normal `touch-` inputs.
The proxy only forwards and logs messages (rejoin tokens are redacted).

## Requirements and permissions

- Xcode with an installed iPad Simulator runtime, Swift compiler, Python 3,
  Node, and FFmpeg/ffprobe; install game server dependencies with
  `npm ci --prefix "$REPO/Server"`.
- Build the native app using the game README. Install the **same** app on two
  independent booted iPads. This harness does not build or select a revision.
- Grant the invoking automation host Accessibility, Screen Recording and
  Microphone access in macOS Privacy & Security. Resolve any SimulatorTrampoline
  microphone prompt before recording. No service credentials are needed.
- Actual loopback audio: BlackHole 2ch must be the default input/output, stereo
  48 kHz. Verify with `system_profiler SPAudioDataType` **before booting** iPads.
  If needed, install with `HOMEBREW_NO_AUTO_UPDATE=1 brew install --cask blackhole-2ch`;
  registering it required `sudo -n killall coreaudiod` on the test host. If that
  requires credentials, perform setup manually rather than retrying blindly.
  Reboot simulators previously booted without the device. Select Simulator
  **I/O → Audio Output → BlackHole 2ch**. No synthetic music is added.
- Ports 8769/8770 must be free. Keep unrelated apps/audio players closed.

## Device and window calibration — required, not portable defaults

Set explicit local paths and device IDs; **there are no baked-in UDIDs**:

```sh
export REPO="/absolute/path/to/skyline-pulse"
export TOOLS="/absolute/path/to/this/source/directory"
export ARIA_UDID="YOUR-FIRST-IPAD-UDID"
export NOVA_UDID="YOUR-SECOND-IPAD-UDID"
export CONFIG="/absolute/path/to/local-geometry.json"
export OUT="/absolute/path/to/existing-evidence-parent/new-run"
xcrun simctl list devices available
# Boot only devices not already booted:
xcrun simctl boot "$ARIA_UDID"
xcrun simctl boot "$NOVA_UDID"
xcrun simctl bootstatus "$ARIA_UDID" -b
xcrun simctl bootstatus "$NOVA_UDID" -b
export APP="$REPO/.build/Build/Products/Debug-iphonesimulator/SkylinePulse.app"
xcrun simctl install "$ARIA_UDID" "$APP"
xcrun simctl install "$NOVA_UDID" "$APP"
open -a Simulator
cp "$TOOLS/geometry.example.json" "$CONFIG"
osascript -e 'tell application "System Events" to tell process "Simulator" to get name of every window'
```

Edit the copied config, never assume the example matches your desktop:

- Put both iPads in landscape; disable device bezels (Simulator View menu).
  Both complete app displays must be visible side-by-side and unobscured.
- `windows.PLAYER.titleContains`: a unique substring of that device's **actual
  accessibility window name**. The example names are illustrative only.
- `windows.PLAYER.bounds`: `[left,top,width,height]` of the entire macOS window
  in desktop **points**, including its title/tool bar. `prepare.py` applies these.
- `displays.PLAYER`: `[left,top,width,height]` of the app's illuminated display
  only, excluding toolbar/bezel. CGEvent uses desktop points, not Retina pixels.
- `controls`: fractional positions within that display for CREATE, ROOM CODE,
  JOIN, READY, REMATCH and RECONNECT. Recalibrate if the app layout changes.
- Gameplay coordinates assume the tested landscape layout: highway x begins
  at 27.5% and spans 70% of display width; judgment y=90%; air moves to y=70%.
  Changing device aspect ratio/UI layout may require a different calibration.
  The example was measured on a 1600×1200-point desktop with two 763×501-point
  display rectangles. It is **not** an automatic layout detector.
- Start both clients on the default **NEON** chart, calibration 0 ms. A stale
  room-code field or keyboard overlay must be cleared before the run.
- Do not touch the shared host cursor/keyboard during execution.

## Compile and schedule preflight

```sh
swiftc "$TOOLS/gestures.swift" -o "$TOOLS/gestures"
swiftc "$TOOLS/capture-audio.swift" -o "$TOOLS/capture-audio"
swiftc -parse-as-library "$TOOLS/capture-video.swift" -o "$TOOLS/capture-video"
python3 -m py_compile "$TOOLS/"*.py
node --check "$TOOLS/proxy.mjs"
python3 "$TOOLS/drive.py" --repo "$REPO" --out "$OUT" \
  --config "$CONFIG" --phase preflight
```

Preflight does **not** click anything or create `OUT`; expect:
`Native schedule preflight: 70 non-overlapping gestures`.
It checks balanced down/up and required four-kind coverage for both players.
Do not run Python with `-O`; the harness deliberately uses runtime assertions.

## Capture preflight, then one bounded run

The supplied audio source is unchanged: `AVAudioEngine.inputNode.installTap`
writes CAF plus per-buffer host/sample timestamps. The SCK helper records video
only and logs original source PTS plus host-clock anchors. Never align audio
using process-launch times. Run **one capture pair at a time**; do not start
a competing screen-recording service. The guard rejects existing helper PIDs,
but cannot detect every third-party screen recorder.

```sh
# Use a NEW directory. Wait for this synchronous command to FINISH before run.py.
export PREFLIGHT="/absolute/path/to/existing-evidence-parent/capture-preflight"
mkdir "$PREFLIGHT"
python3 "$TOOLS/capture-pair.py" --out "$PREFLIGHT" --duration 8
cat "$PREFLIGHT/capture-finish.json" # both exit codes must be 0
ffprobe -v error "$PREFLIGHT/screen-raw.mov"
ffmpeg -v error -i "$PREFLIGHT/screen-raw.mov" -f null -
pgrep -x capture-video # must print nothing (exit 1 means absent)
pgrep -x capture-audio # must print nothing

python3 "$TOOLS/prepare.py" --repo "$REPO" --out "$OUT" \
  --aria "$ARIA_UDID" --nova "$NOVA_UDID" --config "$CONFIG"
# Visually confirm both offline lobbies, correct geometry, no keyboard overlays.
python3 "$TOOLS/run.py" --repo "$REPO" --out "$OUT" --config "$CONFIG"
python3 "$TOOLS/assertions.py" --out "$OUT"
python3 "$TOOLS/validate-media.py" --out "$OUT"
cat "$OUT/capture-finish.json"
ffprobe -v error "$OUT/screen-raw.mov"
ffmpeg -v error -i "$OUT/screen-raw.mov" -f null -
```

`OUT` must not exist before prepare. `run.py` waits for accepted SCK frames and
audio buffers **before any GUI action**, drives both players, then waits for the
155-second bounded capture. Exit 0 requires both the UI procedure and both capture
helpers to exit 0. The read-only validator additionally writes `assertions.json`
and exits nonzero for any failed gameplay assertion. Capture exit 0 alone does
not prove media integrity; inspect/full-decode and validate timestamps/samples.

Treat the full procedure as passing only when **both** validation commands exit0.
`run.py` checks its native lifecycle assertions and capture exits; the separate
strict validator can still fail individual selected-note judgment probes.
Do not discard that nonzero exit or weaken the expected tick counts.

The sequence clicks CREATE and types the observed room code into the other
Simulator; clicks READY on each; completes round 1; clicks ARIA REMATCH and
checks the two-second wait; clicks NOVA REMATCH; completes round 2; then clicks
both RECONNECT buttons. The driver saves held-gesture screenshots and raw logs.

## One pointer is intentional

The unchanged tested schedule selects **70 gestures per round**, 35 per player,
with at least 50 ms separation between gestures. A host pointer cannot hold two
windows simultaneously; overlapping notes are intentionally skipped. Expect
misses and unequal scores, not perfect play. Required probes:

| Player | Tap | Upward air | Hold (5 ticks) | Slide (7 ticks) |
|---|---|---|---|---|
| ARIA | note 0 | note 3 | note 4 | note 9 |
| NOVA | note 1 | note 11 | note 12 | note 20 |

`round*-selection.json` records all selected notes. Raw `native-cgevents.jsonl`,
`ARIA-app.log`, `NOVA-app.log`, `server.jsonl`, and passive `wire.jsonl` permit
independent verification. Every player must exceed 50,000 points each round;
both app logs must show 70 real `touchesBegan` callbacks across both rounds.
The validator requires normal `touch-` pointers and no autoplay launch flags.

## Audio/video evidence

Keep original CAF, buffer JSONL, MOV, source-frame JSONL and capture logs.
`validate-media.py --out "$OUT"` automates the checks and conservative mux,
writing `media-assertions.json`, `alignment.json`, `verified-primary.mp4` and
`verified-aligned-audio.caf`. An optional `--crop width:height:left:top` uses
**video pixels**, not desktop points; measure the source first. It preserves
included frame PTS, encodes without B-frames and explicitly shortens the last
packet to the selected endpoint. No generated frames or soundtrack are used.
Validate consecutive sampleTime/hostTime intervals and the **stored decoded CAF
frame count**, not just the logged count (a short tail may be unflushed). Align
using `round((firstVideoPTS-firstAudioHostSeconds)*sampleRate)`, reporting <=1
sample quantization after checking both clocks' anchors. Trim only to the
intersection of actual accepted video PTS and stored audio samples. Preserve
lossless aligned samples and fully decode the final mux. Do not use another
run's soundtrack or infer timing from process launch/waveform matching.

If SCK fails or alignment is unrecoverable, keep the raw failure and independent
native-input assertions; do not label a guessed mux as synchronized. An earlier
attempt had overlapping capture helpers, a stopped SCK stream, and an unplayable
MOV; the packaged guard prevents the same known helper overlap. Any final
recording/report belongs outside this source-only bundle.

## Cleanup

```sh
# Review the dry-run first; it refuses PIDs whose current command no longer matches.
python3 "$TOOLS/cleanup.py" --out "$OUT"
python3 "$TOOLS/cleanup.py" --out "$OUT" --execute
xcrun simctl terminate "$ARIA_UDID" games.skylinepulse.arcade
xcrun simctl terminate "$NOVA_UDID" games.skylinepulse.arcade
# Optional if these devices are dedicated to this test:
xcrun simctl shutdown "$ARIA_UDID"
xcrun simctl shutdown "$NOVA_UDID"
# Helpers are bounded; wait for completion rather than stopping an active capture.
# Inspect exact PIDs with ps before terminating any orphan from a failed attempt.
```

This archive contains source/config only. Compiled binaries, Python caches,
device identifiers, screenshots, raw media and runtime logs are not bundled.
