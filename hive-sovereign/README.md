# Hive Sovereign

A native landscape iPhone team platform strategy game inspired by **Killer Queen
(2013)**. Two human captains command rival blue and gold hives, with four visibly
labeled AI teammates each. A shared authoritative arena supports all three wins
at once: **12 berries**, **three enemy queen defeats**, or **snail delivery**.

SwiftUI handles the lobby and controls; SpriteKit renders an original pixel-art
sky arena, adjacent hive towers, insect sprites, winged gates, berries, eggs,
hit particles and animated snail. Original synthesized chiptone music and effects
play locally. This is an iOS application, not a website or embedded web view.

## Build

Tested with macOS / Xcode 26.6, iOS 26.5 simulator SDK, Swift 5 language mode,
Node 24.19.0, XcodeGen 2.46.0, and pinned `ws` 8.21.3.

```sh
cd hive-sovereign
make check
make build
```

The generated Xcode project is included. No Apple developer account is needed
for simulator builds. If editing `project.yml`, `brew install xcodegen` and
`make project` regenerates the project and plist. Swift's bundled formatter
provides the supported lint command; SwiftLint is not required.

For real devices, enable normal signing in your local Xcode configuration and
use your own development team. Physical-device signing has not been tested.

## Host and play

```sh
cd hive-sovereign
make server
# listens on 0.0.0.0:8789
```

Launch the app on two separate simulators. In the first, enter a guest name and
**Create Room**. In the second, enter a different name and the displayed room
code, then **Join**. Both choose **Ready to Fly**. Each is a distinct WebSocket
peer and controls a different team.

The default server address `ws://127.0.0.1:8789` works from iOS simulators on the
same Mac. For two physical devices, edit the address on both to
`ws://<Mac-LAN-IP>:8789`. Allow the local-network permission, and put both devices
on the host's network. This local guest protocol is intentionally not a public
internet service. No deployment or complex identity provider is required.

## Controls and strategy

- **Left / Right**: run. The arena wraps horizontally.
- **Jump**: worker jump; repeated or held input flaps for queens and warriors.
- **USE**: stand at a neutral or friendly gate with a berry for one second.
  Wing gates turn workers into warriors. Speed gates grant a 33% movement boost.
  Warriors cannot collect berries or ride the snail. Upgrades are lost on death.
- **USE by the snail**: a worker mounts and rides toward its team's basket.
  Keep USE held. Move, jump or release to dismount. An enemy sword can kill the
  rider and interrupt progress; the other team can take over.
- **DIVE**: the queen's USE button becomes a downward attack.
- **PILOT Q / 1–4**: take direct control of a specific teammate. Every unselected
  unit has an AI label. Queens claim gates by contact. Armed collisions are
  decided by height (or a queen dive); equal-height armed insects bounce apart.
- **Economy / Snail / Military**: issue strategic orders to your AI. Economy
  forages and deposits. Snail assigns a rider and supporting foragers. Military
  sends workers through wing gates and attacks the enemy queen.
- **Sound** toggles original loop/effects. **Field Manual** explains the rules.
- The result screen supports mutual-ready **Rematch** and **Leave**.

Workers carry one berry automatically on contact, then deposit by entering
their team's upper central hive. Queens have three eggs total; drones respawn
indefinitely at their hive. Respawn protection blinks briefly.

## Reproducible two-device run

The testing agent owns simulator/server setup for the recorded acceptance run.
For a manual reproduction after `make build` and `make server`:

```sh
xcrun simctl list devices available
BLUE=<first-iPhone-UDID>
GOLD=<second-iPhone-UDID>
xcrun simctl boot "$BLUE"
xcrun simctl boot "$GOLD"
xcrun simctl bootstatus "$BLUE" -b
xcrun simctl bootstatus "$GOLD" -b
xcrun simctl install "$BLUE" .build/Build/Products/Debug-iphonesimulator/HiveSovereign.app
xcrun simctl install "$GOLD" .build/Build/Products/Debug-iphonesimulator/HiveSovereign.app
xcrun simctl launch "$BLUE" ai.hivesovereign.native --name Azure --create \
  --server ws://127.0.0.1:8789 --autopilot --strategy economy
# Read the room from Azure's lobby or the server's join log:
ROOM=<displayed-room-code>
xcrun simctl launch "$GOLD" ai.hivesovereign.native --name Amber --room "$ROOM" \
  --server ws://127.0.0.1:8789 --autopilot --strategy snail
```

The **AUTOMATED CAPTAIN** badge is always shown for automated input. The in-app
driver reads received snapshots, navigates platforms, and sends exactly the
same `input` messages as touch controls. It cannot set scores, units, timers,
health, victory, or server state. Any touch movement or role selection disables
the driver for that device. Both captains affect the same running match.

Useful explicit test hooks:

```sh
xcrun simctl openurl "$BLUE" 'hivesovereign://driver?enabled=0'
xcrun simctl openurl "$BLUE" 'hivesovereign://driver?enabled=1&strategy=economy'
xcrun simctl openurl "$BLUE" 'hivesovereign://select?slot=0'
xcrun simctl openurl "$BLUE" 'hivesovereign://reconnect'
xcrun simctl openurl "$BLUE" 'hivesovereign://ready'
curl "http://127.0.0.1:8789/rooms/$ROOM"
```

`/rooms/CODE` is **read-only** telemetry without reconnect tokens: tick, selected
units, per-peer input counts/sequences, scores, queen lives, snail position,
deposits, kills and winner. Keep this output as assertions alongside recordings.
Close/reconnect one socket to observe the other client's paused state and resume
with the same guest identity. The reconnect token remains in app memory; quitting
the process intentionally requires a fresh room (no account persistence).

For authentic simultaneous device captures, start `xcrun simctl io "$BLUE"
recordVideo` and its GOLD equivalent together, retain their original streams,
then compose them side-by-side with ffmpeg. Do not join unrelated runs. Show
both full displays, the same room, changing shared objectives and the outcome.

## Checks

`make check` runs strict Swift formatting lint, Node syntax checks, meaningful
physics/rules tests, actual WebSocket room/input/reconnect tests and dependency
audit. `make build` typechecks and builds the native simulator app. The
`HiveSovereignUITests` target covers the lobby/manual error flow; UI acceptance
also requires an actual two-simulator match, outcome, rematch and manual controls.

## Architecture and limitations

See [protocol](docs/PROTOCOL.md) and [reference evidence](docs/REFERENCE.md).
The server ticks at 30 Hz, snapshots at 15 Hz; native sprites interpolate between
snapshots. Rooms require exactly two human captains. The simulation pauses on
disconnect and resumes on token-authenticated reconnect. Empty rooms expire
after two minutes. Server restart discards in-memory rooms.

The original arcade software, exact physics, original sprites, audio and
ten-cabinet-player experience are not reproduced literally. Art, map layout,
music, navigation AI and mobile control adaptation are authored. Bots are
deterministic tactical helpers, not expert arcade players. Rendering is fixed
landscape with letterboxing. The arena itself is not a VoiceOver-navigable game;
menus and touch controls have accessibility labels. There is no internet
matchmaking, persistence, rollback prediction, spectator mode, or public hosting.
Literal pixel parity and untested hardware behavior are not claimed.
