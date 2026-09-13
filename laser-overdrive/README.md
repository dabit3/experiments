# Laser Overdrive

An original native **iPhone** neon laser rhythm duel, inspired by Sound Voltex.
Four BT lanes, two FX lanes, sustained notes, independently tracked cyan/magenta
lasers and rapid laser slams share a 44-second, 144 BPM original electronic track.
Both human guests see the same song clock and each other's server-judged score.

## Build

Tested toolchain: Xcode 26.6, Swift 6.3.3, iOS 26.5 Simulator, Node 24.
The app targets iOS 17+. The checked-in Xcode project needs no package downloads
or Apple developer account for Simulator.

```sh
cd laser-overdrive
xcodebuild -project LaserOverdrive.xcodeproj -scheme LaserOverdrive \
  -sdk iphonesimulator -configuration Release -derivedDataPath .build \
  build CODE_SIGNING_ALLOWED=NO
xcrun swift-format lint --strict --recursive App

cd Server
npm ci --ignore-scripts
npm run check
npm test
npm audit
```

`project.yml` is the project source. If changing project membership, regenerate
using XcodeGen 2.46.0 (`brew install xcodegen`, then `xcodegen generate`).
The Swift compiler plus Xcode's bundled `swift-format lint --strict` are the
supported native typecheck/lint tools. No SwiftLint installation is required.

## Start the room host

```sh
cd laser-overdrive/Server
EVENT_LOG="$HOME/laser-server.jsonl" npm start
# Health: curl http://127.0.0.1:8769/health
```

Default port **8769**, bound to all interfaces for LAN play. It is a local server;
no public deployment is configured. Use `PORT=...` to choose another port.
Simulator instances on the host use `ws://127.0.0.1:8769`. Physical devices use
`ws://<Mac-LAN-IP>:8769`; edit the address in each app's lobby. The server has
guest tokens and bounded payload/rate limits, but is intended for trusted local
networks, not an internet service.

## Two-device play

List devices with `xcrun simctl list devices available`. Choose **two different**
iPhone UDIDs, then:

```sh
xcrun simctl boot "$PHONE_A"
xcrun simctl boot "$PHONE_B"
open -a Simulator
APP=".build/Build/Products/Release-iphonesimulator/LaserOverdrive.app"
xcrun simctl install "$PHONE_A" "$APP"
xcrun simctl install "$PHONE_B" "$APP"
xcrun simctl launch "$PHONE_A" ai.devin.arcade.laseroverdrive
xcrun simctl launch "$PHONE_B" ai.devin.arcade.laseroverdrive
```

Choose a guest callsign and **Create Room** on one phone. Enter that room's code
and choose **Join Room** on the other. Both guests press **Ready / Arm System**.
A common four-second countdown precedes audio scheduled against the synchronized
server clock. The song and chart include two seconds of musical lead-in.

### Controls

- **A–D / BT:** tap white plates at the gold critical line. Keep held for trails.
- **FX-L / FX-R:** orange notes span two lanes. Tap/hold the corresponding FX
  button. FX-L applies distortion; FX-R applies a low-pass filter.
- **VOL-L / VOL-R:** independently drag either knob pad left/right. The cursor
  moves relatively (a 115-point sweep covers the track). Keep touching to sustain
  tracking on flat paths. Move smoothly along slopes and quickly at right angles.
  Each laser also moves the soundtrack's low-pass frequency.
- Multi-touch supports concurrent buttons and gestures. Controls light on contact,
  and tap feedback is synthesized locally with haptics on supported devices.
- CRITICAL ≤50 ms, NEAR ≤120 ms. Sustains and lasers score repeated ticks.
  Misses break combo and drain the effective-rate gauge. Reach 70% to clear.
  The higher score wins the duel; both press Rematch for a new round.
- Exit opens a confirmation. Reconnecting preserves guest identity and the current
  match for the disconnected seat; song playback resumes at the shared position.

## Repeatable automation and evidence

Automation is explicitly labeled in the HUD. It calls the **same `button` and
`laser` methods and WebSocket input protocol** as touch controls; it cannot set
score, gauge, health, song time, or results.

```sh
xcrun simctl launch "$PHONE_A" ai.devin.arcade.laseroverdrive \
  --connect --create --room BEAM01 --name PHOTON \
  --server ws://127.0.0.1:8769 --autoplay --variant 0
xcrun simctl launch "$PHONE_B" ai.devin.arcade.laseroverdrive \
  --connect --room BEAM01 --name PRISM \
  --server ws://127.0.0.1:8769 --autoplay --variant 1
```

Press Ready on both normally, or add `--auto-ready` to both launch commands.
Variant 1 intentionally misses some notes and hits others late; neither peer is
a server-side opponent. `--driver-delay 5` leaves the first five song seconds for
touch testing. The visible **AUTO ON/OFF** switch allows manual control testing.
Without `--autoplay`, no automated input driver or switch is installed.

The testing workflow must show both full devices simultaneously, record a complete
match through results, exercise real touch presses and swipes, and test rematch or
rejoin. Record both streams simultaneously using `simctl io <UDID> recordVideo`
or a full-screen native capture. When composing streams, align their actual capture
start times, keep both displays uncut, and disclose audio capture limitations.
Never splice different matches into one claimed duel.

The app writes `Documents/evidence.jsonl` with identity, phase changes, shared
start time, audio position, touch input, and periodic peer snapshots. Export after
the test:

```sh
A_DATA="$(xcrun simctl get_app_container "$PHONE_A" ai.devin.arcade.laseroverdrive data)"
B_DATA="$(xcrun simctl get_app_container "$PHONE_B" ai.devin.arcade.laseroverdrive data)"
python3 Tools/verify_evidence.py "$A_DATA/Documents/evidence.jsonl" \
  "$B_DATA/Documents/evidence.jsonl" "$HOME/laser-server.jsonl"
ffprobe -v error -show_streams -show_format <final-video.mp4>
```

The verifier checks distinct identities, common room/start, audible-player timing,
both peers' scored BT/FX/hold/laser/slam actions, shared authoritative results and
actual touch packets in server logs. Preserve its JSON output alongside the video,
full screenshot and test report.

## Architecture

- SwiftUI provides native lobby, editable connection fields, help and results.
- `HighwayCanvas` is a native UIKit/Core Graphics 60 Hz renderer with a perspective
  highway, additive-looking laser glow, plate trails, track grid, animated geometric
  tunnel, hit rings, critical line, opponent HUD, combo and vertical gauge.
- `GameModel` owns per-install UUID/token, ordered WebSocket inputs, clock sync,
  local controls, the opt-in input driver and evidence logging.
- `SoundEngine` uses AVAudioEngine, scheduled AVAudioPlayerNode playback, EQ,
  distortion and generated hit feedback. Both clients schedule the same bundled
  original music against the common start clock.
- `Server/engine.mjs` is the authoritative scoring engine. `server.mjs` handles
  two-seat rooms, readiness, identity resumption, broadcasts, rate limits and
  result transitions. See [protocol](Docs/PROTOCOL.md).
- `Tools/generate_track.py` authors deterministic notes/lasers and synthesizes the
  original score. To regenerate: run it, then
  `ffmpeg -y -i Resources/afterburn.wav -c:a aac -b:a 160k Resources/afterburn.m4a`.
  The WAV is an ignored intermediate. The bundled M4A and JSON are used by the app.

## Reference and limitations

[Research notes and official screenshot URLs](Docs/REFERENCE.md) distinguish
observed details from adaptation. No extracted ROMs, original chart/music or
licensed character art are used. Exact cabinet timing and pixel parity are not
claimed. Knob gestures adapt physical rotary controls to touch; expert two-knob
sections are demanding on an iPhone and work best with the device on a surface.

One authored song and one difficulty are included. Room state is in memory;
restarting the host discards matches. Brief reconnects resume; disconnected seats
expire after a minute outside gameplay. WSS termination, internet matchmaking,
account progression, calibration UI, background play and VoiceOver navigation of
the fast multitouch gameplay surface are not implemented. Audio timing is measured
on Simulator; Bluetooth/device latency calibration and physical-device testing
remain separate checks.
