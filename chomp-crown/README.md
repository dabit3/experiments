# Chomp Crown

Native iPhone multiplayer maze combat built with **SwiftUI + SpriteKit**, with an
authoritative Node WebSocket server. Two to four human guests compete for two
round crowns. No Apple developer account, browser, cloud service or identity
provider is needed for the simulator.

## Build and run

Verified toolchain: macOS, Xcode 26.6 / iOS 26.5 simulator SDK, Node 24.19.0.
The deployment target is iOS 17. Xcode project and generated Info.plist are
included; XcodeGen 2.46.0 is only needed to regenerate them after changing
`project.yml`. No Swift package dependencies. Server dependency `ws` is pinned
with an npm lockfile.

From this directory:

```sh
npm ci --prefix Server
npm start --prefix Server
# In another terminal:
xcodebuild -project ChompCrown.xcodeproj -scheme ChompCrown \
  -configuration Debug -sdk iphonesimulator -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build
```

The server listens on **8873**, configurable with `PORT`. Health check:
`curl http://127.0.0.1:8873/health`. It binds all interfaces for LAN play; this
development server is intended for a trusted local network, not public hosting.
The native lobby provides an editable address. Both local simulators use
`ws://127.0.0.1:8873`; physical phones use `ws://<Mac-LAN-IP>:8873`. Physical-device
installation requires the user's normal signing setup. Local network permission
is requested by iOS. Cleartext transport is enabled for editable LAN addresses.

## Two-device test

List devices with `xcrun simctl list devices available`. Substitute two distinct
UDIDs in the following commands, keeping the same server running:

```sh
xcrun simctl boot DEVICE_A
xcrun simctl boot DEVICE_B
open -a Simulator
xcrun simctl install DEVICE_A build/Build/Products/Debug-iphonesimulator/ChompCrown.app
xcrun simctl install DEVICE_B build/Build/Products/Debug-iphonesimulator/ChompCrown.app
xcrun simctl launch DEVICE_A games.chompcrown.neon --name Gold --create
# Read the visible four-character room code:
xcrun simctl launch DEVICE_B games.chompcrown.neon --name Rose --room ROOM --join
```

Each installation creates a separate persisted UUID. Tap **Ready to Chomp** on
each phone. Both devices show the same maze and scores with a different `YOU`
marker. Tap or swipe to change direction. Play until a player earns two crowns;
both must tap **Rematch** to start again. Toggle audio, open instructions or leave
using the top toolbar. Leave the server running while playing.

### Repeatable input automation (clearly labeled on screen)

Optional launch arguments `--autoplay hunter` and `--autoplay runner` turn on a
client-side BFS input driver. `--auto-ready` readies once two guests join. Drivers
send only ordinary sequenced direction messages through the **same**
`GameClient.direction` → WebSocket → server path as touch controls. They cannot
write score, health, power, maze, server clock, crowns or outcomes. There is no
fake human or server AI player; only the three ghosts use server AI.

Deep links help reproducible UI tests without relaunching:

```sh
xcrun simctl openurl DEVICE_A 'chomp-crown://driver?value=off'
xcrun simctl openurl DEVICE_A 'chomp-crown://input?value=up'
xcrun simctl openurl DEVICE_A 'chomp-crown://driver?value=hunter'
xcrun simctl openurl DEVICE_A 'chomp-crown://ready'
xcrun simctl openurl DEVICE_A 'chomp-crown://rematch'
xcrun simctl openurl DEVICE_A 'chomp-crown://reconnect'
```

Deep links do **not** replace validating real touch controls. Accessibility IDs
include `move-up`, `move-left`, `move-down`, `move-right`, `last-input`,
`ready-button`, `rematch-button` and `match-status`.

For machine-readable server evidence run `TRACE=1 npm start --prefix Server`.
JSON lines contain room, peer IDs, input sequence acknowledgments, positions,
scores, powers, crowns, phase transitions and outcomes. Recovery tokens are
never logged. App stdout also reports its own peer/room, input and phase.

Record both simulators simultaneously with separate
`xcrun simctl io DEVICE recordVideo --codec=h264 FILE.mov` processes (SIGINT to
finish), or capture the full desktop with both windows visible. If composing
device streams, align simultaneous streams and retain both complete displays
for the entire match. Preserve logs from that same run. Inspect the completed
video and verify with `ffprobe`; screenshots/build success alone do not prove
two-device gameplay.

### Live audio capture on a macOS VM

If the host has no audio endpoint, install BlackHole before booting simulators:

```sh
brew install --cask blackhole-2ch
system_profiler SPAudioDataType
ffmpeg -hide_banner -f avfoundation -list_devices true -i ""
```

On the verified VM, BlackHole 2ch 0.7.1 appeared as the default input, output and
system output at 48 kHz after a CoreAudio reload. **Only if the endpoint is still
missing**, before recording, run `sudo -n killall coreaudiod` and repeat device
enumeration. Do not request a password TTY or restart CoreAudio during capture.
Shut down and reboot any simulator that booted before the endpoint existed.
Grant the macOS microphone/capture prompts when presented. Enumeration commands
may exit nonzero after listing devices because no capture input was selected.

Arrange both full device displays together. A joint AVFoundation screen/audio
input preserves a common timestamp domain. After checking the current device
indices, this command captured screen `0` and BlackHole audio `0` on the VM:

```sh
ffmpeg -y -nostdin -hide_banner \
  -f avfoundation -framerate 30 -capture_cursor 1 -i 0:0 \
  -c:v h264_videotoolbox -b:v 6000k -c:a pcm_s16le \
  live-screen-audio.mkv
```

Keep the capture process and its parent session alive; stop with SIGINT and wait
for finalization. Native logs flush immediately when `simctl launch` is prefixed
with `SIMCTL_CHILD_NSUnbufferedIO=YES`. Mute both phones, verify zero PCM, then
unmute just one to distinguish actual game output from unrelated host audio.
Inspect packet timestamps, sample counts, signal levels and control transitions:

```sh
ffprobe -v error -show_packets -show_streams -show_format -of json live-screen-audio.mkv
ffmpeg -v error -i live-screen-audio.mkv -f null -
```

The recorded audio follow-up verified nonzero native music, source correlation,
mute/unmute causality and control/audio alignment within approximately −12 to
+46 ms. **Capture continuity failed:** the VM omitted 15.614% of audio intervals
(37.220 seconds across 238.4 seconds; maximum gap 96.3 ms). The exported video
preserves original sample timestamps and fills only absent intervals with
silence. Never concatenate incomplete samples as a continuous track, replace
gaps with generated music, or describe this capture path as lossless. Earlier
silent evidence and failed capture attempts were retained in the test artifacts.

## Game rules and controls

* Buffered cardinal movement at 4.1 tiles/s; turns occur at open cell centers.
  Hold no button: movement continues. Swipe the arena or tap the D-pad.
* Dots are worth 10. Four power orbs are worth 50 and respawn 12 seconds after
  collection. An orb grants seven seconds of **giant** form and 4.7 tiles/s.
* A powered human eats normal rivals (500 points) and ghosts (200). Other humans
  become deep blue with their own colored outline. Equal-strength humans bump
  backward. Normal humans die on ghost contact.
* Three ghosts leave the pen at staggered times and chase the nearest human.
  They flee a powered target and return to the pen for five seconds after being
  eaten. The final 15 seconds trigger faster **Ghost Rush**.
* A fruit gem appears when fewer than 40 dots remain. Eating it earns 100 and
  refreshes the pellet field. Empty fields refill too.
* Last human standing earns a crown. A 45-second round limit uses cumulative
  score as a tie-break (equal score is a draw). All humans return next round;
  first to two crowns wins. Both/all peers must vote to rematch.
  A completed winner's identity remains in the result if that guest leaves.
* A dropped connection pauses the simulation for up to 30 seconds. The app
  retries four times and also has a reconnect button. After grace expires a
  connected peer wins by forfeit; a departed lobby guest is removed.

## Protocol

One JSON object per WebSocket frame, maximum 4 KiB inbound. No binary protocol.

| Direction | Message | Meaning |
|---|---|---|
| Client → server | `{type:"join",create:true,playerId,name}` | Create a generated four-character room |
| Client → server | `{type:"join",code,playerId,name,token?}` | Join or recover an existing guest |
| Server → client | `{type:"joined",code,you,token,lastSeq}` | Private recovery token and input acknowledgment |
| Client → server | `{type:"ready"}` | Lobby/rematch vote |
| Client → server | `{type:"input",seq,direction}` | `up/right/down/left`, increasing safe integer |
| Server → client | `{type:"state",you,...}` | Personalized authoritative snapshot, 15 Hz |
| Client → server | `{type:"leave"}` | Explicit departure |
| Server → client | `{type:"error",message}` | Validation/room errors |

The server simulates a deterministic ordered 30 Hz fixed step and owns collision,
AI, timers, pickups, scores, rounds and crowns. Input sequence numbers reject
duplicates/stale messages. State snapshots carry a tick, game clock, complete
player/ghost positions, pellets, power timers and a bounded event history. The
client smooths positions between snapshots and animates mouths locally; it never
predicts outcomes. TCP/WebSocket orders frames. Ping/pong detects dead peers.
Rooms support at most four guests; started rooms refuse new identities. A
random recovery token proves rejoin ownership, is omitted from shared snapshots,
and prevents another socket from taking over a known UUID. At most 100 rooms.
Rooms are memory-only and disappear when empty or the server restarts.

## Checks

```sh
npm run check --prefix Server
npm test --prefix Server
npm audit --prefix Server
swift format lint --strict --recursive App ChompCrownUITests
xcodebuild -project ChompCrown.xcodeproj -scheme ChompCrown \
  -configuration Release -sdk iphonesimulator -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build
# UI smoke test, with an available simulator UDID:
xcodebuild -project ChompCrown.xcodeproj -scheme ChompCrown \
  -destination 'platform=iOS Simulator,id=DEVICE_A' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO test
```

Tests cover maze connectivity, wall collision, buffered turns, power expiry and
eating, ghost combat, knockback, ordered inputs, round/rematch rules, paused clocks,
a complete input-driven multi-round game, real WebSocket rooms, private recovery,
capacity and malformed messages. UI testing requires the simulator separately.
`swift format` from the Xcode toolchain is the supported Swift lint command.

## Art, sound and reference fidelity

See [REFERENCES.md](REFERENCES.md) for URLs, observations, source boundaries and
the acceptance inventory. All shapes in the app are original procedural
SpriteKit/SwiftUI geometry. Original synth music and cues are generated by
`python3 Scripts/generate_audio.py` and bundled in the native app. No reference
sprites, ROM assets or original soundtrack are redistributed.

This is an authored 2011-style elimination game with requested neon-blue walls,
oversized chomping, crown rounds and modern score HUD. It does not implement the
2022 sequel's ten special power-ups, eight-player cabinets or multi-life mode.
The arena is original and fitted to portrait iPhone. Exact reference pixel,
physics and audio parity are unverified; the original arcade software was not
available for comparison. iPad/landscape layouts, physical-device networking
and WAN latency are outside the verified simulator scope. Guest identity and
audio preference are local; room/match history is not persisted by the server.
