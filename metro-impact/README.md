# Metro Impact

A native landscape iPhone arcade fighter for **two real networked players**.
SwiftUI handles guest entry; SpriteKit renders an original pixel harbor, articulated
fighter frames, impact freeze, waves, super effects and a mirrored arcade HUD.
Reference edition: **Super Street Fighter II Turbo (1994 CPS-II arcade)**.
Research, direct visual observations and approximation boundaries are in
[docs/REFERENCE.md](docs/REFERENCE.md).

## Build and run

Requirements: macOS with Xcode 26 (tested 26.6 / iOS 26.5 Simulator), Node 22+
(tested 24.19.0). No developer account or signing is needed for Simulator.
The committed Xcode project is self-contained; XcodeGen is only needed if editing
`project.yml`. No Swift package dependencies.

From this folder:

```sh
npm --prefix server ci
npm --prefix server run check
npm --prefix server test
npm --prefix server audit
xcrun swift-format lint --strict --recursive App
xcodebuild -project MetroImpact.xcodeproj -scheme MetroImpact \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build CODE_SIGNING_ALLOWED=NO build
```

Start the authoritative game server in its own terminal:

```sh
npm --prefix server start
# ws://127.0.0.1:8743 ; health: http://127.0.0.1:8743/health
# PORT=8744 npm --prefix server start  # optional
```

Open `MetroImpact.xcodeproj` in Xcode and run on an iPhone simulator. On the first
device enter a name, select Kai or Rhea, and **CREATE ROOM**. On the second device,
enter its own name and the host's code, then **JOIN**. Both tap **READY**.

For physical devices use the host Mac's LAN IP in the editable address, e.g.
`ws://192.168.1.5:8743`, allow local-network access, and keep both on the same LAN.
Physical installation requires your own Apple signing; it is not needed locally.
The local server is intentionally not a public deployment.

## Controls and rules

| Control | Action |
|---|---|
| ◀ / ▶ | Hold to move. Holding away also guards grounded attacks. |
| ▲ | Jump; combine with movement or light/heavy for jump-ins. |
| ▼ | Crouch; combine with attacks for low variants. |
| GUARD | Hold to block high attacks and waves. |
| ▼ + GUARD | Block lows; vulnerable to jump attacks. |
| LIGHT | Fast short-range punch, 4-frame startup. |
| HEAVY | Long-range kick, higher damage, 10-frame startup and longer recovery. |
| WAVE | Projectile special. Has startup and travel; jump over or guard. |
| SUPER | At 100 meter, consumes it for a four-wave super with freeze/afterimages. |
| SOUND | Toggle soundtrack and effects. |
| EXIT | Leave the match and return to guest entry. |
| AGAIN | Vote for a rematch; both peers must agree. |

Kai has faster movement; Rhea has 16% extra normal reach and 12% extra damage.
Both have standing, crouching, jumping, guard, attack, hurt, KO and victory poses.
Normal attacks build meter on contact, specials build meter on use, taking hits
builds meter. Meter resets between rounds. Normal guard prevents damage; guarded
waves chip for 2. Blocking cannot interrupt attack recovery. Opposing waves cancel.
First to **two rounds** wins; each round starts at 100 health with a 60-second clock.
A tied timeout awards no win. There is no hidden opponent AI. The optional labeled
driver controls the actual guest player through the same inputs as touch.

## Reproducible two-device test

The testing agent owns simulator/server setup for the recorded verification.
The following commands are for reproducing the test manually afterward:

```sh
xcrun simctl list devices available
# Set A and B to TWO DIFFERENT iPhone UDIDs from the command above.
A="<first iPhone UDID>"
B="<second iPhone UDID>"
xcrun simctl boot "$A"
xcrun simctl boot "$B"
xcrun simctl bootstatus "$A" -b
xcrun simctl bootstatus "$B" -b
APP="$PWD/.build/Build/Products/Debug-iphonesimulator/MetroImpact.app"
xcrun simctl install "$A" "$APP"
xcrun simctl install "$B" "$APP"
open -a Simulator
```

First validate touch: launch without automation and create/join a room via the UI;
ready, move, jump, crouch, guard and attack. Movement buttons support drag between
directions and simultaneous fingers. To record a repeatable full match, use a fresh
room code and two independently launched native apps:

```sh
xcrun simctl launch "$A" com.metroimpact.arcade \
  --auto host --room MTR094 --name Alpha --character kai \
  --driver balanced --delay 12
xcrun simctl launch "$B" com.metroimpact.arcade \
  --auto guest --room MTR094 --name Beta --character rhea \
  --driver defensive --delay 12
```

The explicitly labeled drivers ready both clients, navigate and fight using
`Session.press/release` → ordered WebSocket `input` messages. They never assign
health, score, location or victory. They vote to rematch nine seconds after the
first actual match result. A second match runs without a forced ending.

Capture **both simultaneously** in separate terminals:

```sh
mkdir -p evidence
xcrun simctl io "$A" recordVideo --codec=h264 evidence/alpha.mov
xcrun simctl io "$B" recordVideo --codec=h264 evidence/beta.mov
# Stop each with SIGINT after the shared result, rematch and reconnect.
# Compose the simultaneous full device displays, without cropping.
ffmpeg -i evidence/alpha.mov -i evidence/beta.mov \
  -filter_complex '[0:v]scale=1280:-2,pad=1280:720:0:(oh-ih)/2[a];[1:v]scale=1280:-2,pad=1280:720:0:(oh-ih)/2[b];[a][b]hstack[v]' \
  -map '[v]' -c:v libx264 -crf 20 -pix_fmt yuv420p evidence/two-device.mp4
ffprobe -v error -show_streams -show_format evidence/two-device.mp4
```

Align capture start timestamps if the record processes started at different times;
do not splice different matches. Simulator video streams may not include audio;
the app's actual playback and audio-capture limits must be stated in the report.
Use a screen recording with loopback audio when available.

Automation deep links (for testing only, no score/state overrides):

```sh
xcrun simctl openurl "$A" 'metroimpact://driver?mode=off'
xcrun simctl openurl "$A" 'metroimpact://driver?mode=balanced'
xcrun simctl openurl "$B" 'metroimpact://reconnect'
xcrun simctl openurl "$A" 'metroimpact://input?control=jump'
xcrun simctl openurl "$A" 'metroimpact://input?release=jump'
```

Record the server's JSONL stdout to preserve join/ready IDs, per-round damage and
actions, outcome, rematch votes and authenticated rejoin. Compare both native
displays with these logs. Include revision, expected/actual assertions and gaps.

## Architecture and protocol

`server/combat.js` is the deterministic fixed-step combat engine, nominally 60 Hz.
`server/server.js` owns rooms, input ordering, authenticated reconnect and 30 Hz
snapshots. `App/Session.swift` owns one guest connection; `ArenaScene` renders
the authoritative state with small position smoothing. There is no client damage
authority, rollback or fake local opponent. Render smoothing never changes combat.

Protocol v1 (JSON over WebSocket, maximum 4096-byte incoming message):

1. `hello { name, character: "kai"|"rhea", room, create }`
2. `welcome { playerID, token, room, seq }`; server creates random peer IDs and
   192-bit reconnect tokens. Token is private to that peer and never broadcast.
3. `ready { ready: true }`; two ready, connected peers start countdown.
4. `input { seq, held: {left,right,jump,crouch,guard}, action? }`.
   Monotonic integer sequence; duplicates/stale inputs ignored. Buttons buffer for
   eight ticks; moves have startup, active frames, recovery and one hit per normal.
5. `state { code, tick, phase, phaseTicks, remaining, round, match, players, projectiles,
   effects, freeze, paused, winner, roundWinner }`. Same snapshot goes to both peers.
6. `rematch {}`; both votes required. `leave {}` returns to lobby and forfeits an
   active match. `ping { sent }` / `pong { sent, time }` displays measured RTT.
7. Rejoin: `hello { room, playerID, token }` replaces the old socket, keeps health
   and rounds, and resumes from last accepted sequence. Inputs clear on disconnect.

Two slots per room; maximum 128 rooms; 150 messages/sec per socket; 4KB payload
limit; 10-second ping heartbeat; stale inactive rooms reclaimed after ten minutes.
Disconnect pauses simulation and match clock. Automatic reconnect applies while
the native process is alive. Exiting the app loses its in-memory guest token; use
a new room after process termination. Server restarts discard all rooms.

## Original assets and known gaps

All bundled artwork/music is generated from the authored source in `scripts/`.
Rebuild optional art with Pillow **11.3.0** and `python scripts/make_art.py`;
audio uses only Python's standard library (`python3 scripts/make_audio.py`).
No Capcom art, fonts, characters, sound samples or ROM content are bundled.

The reference has a much larger roster, six normal buttons, proximity normals,
throws, motion/charge command recognition, deep per-character mechanics and much
more animation. Metro Impact implements the requested two-character touch fighter
with dedicated light/heavy/wave/super buttons. Exact sprite, frame-data, balance,
music and pixel parity are not claimed. The scenic harbor and fighter designs are
original approximations of the 1994 arcade language. Online rollback, matchmaking
services, accounts, spectators, persistence and internet-grade anti-cheat are
outside this local guest-room game. iPhone landscape is the primary tested target;
iPad supports the same letterboxed arena, but should not be labeled tested without
device evidence. SpriteKit combat controls are visual multitouch controls; full
VoiceOver gameplay support is not provided.
