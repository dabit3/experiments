# Brickfolk

Brickfolk is an original cross-platform social sandbox: blocky avatars meet in
a hub, form parties, and jump into shared "experiences" (mini-games) that run
on a single authoritative multiplayer server. One Dart/Flutter codebase
produces four real clients — **web**, **iOS**, **Android** and **macOS** — and
players on any of them play together in the same room.

It was built with the `clone-this` skill using the publicly documented design
of Roblox as the *conceptual* reference (hub + experiences, avatar/inventory
economy, parties, obby/tycoon/tag genres). See "Reference boundary" below.
Everything here — name, art, characters, UI, audio-free feedback, copy — is
original.

| | |
|---|---|
| Hub | place browser with procedural thumbnails, friends & parties (4-letter join codes), filtered global/party/room chat, profiles with badges, daily reward streak, Pips currency + shop, avatar editor (body colours, faces, hats, accessories) |
| Experiences | **Skyline Obby** (checkpoints, deaths, leaderboard by finish time), **Brick Tycoon** (place droppers/conveyors/vaults on a persistent plot, buy income upgrades), **Freeze Tag Arena** (3 rounds, rotating tagger, thaw mechanic) |
| Multiplayer | server-authoritative rooms up to 8 players, party launch across platforms, lobby → countdown → gameplay → results, reconnection with seat grace, deterministic server-side bots to fill matches |
| Persistence | SQLite on the server: players, tokens, Pips, inventory, avatars, badges, streaks, friendships, plots, stats |
| Determinism | fixed seed, fixed clock, deterministic bots and autopilots in test mode; results carry a cross-platform checksum |

## Layout

```
brickfolk/
├── app/        Flutter client (web, ios, android, macos targets)
├── server/     Dart shelf + web_socket_channel authoritative server, SQLite
├── shared/     Dart package shared by app and server: protocol, models,
│               simulations (obby/tycoon/tag), avatar catalogue, chat filter
├── test/       cross-platform multiplayer e2e harness (Node + Playwright)
├── PROTOCOL.md JSON-over-WebSocket protocol spec
└── .devin/clone-this/brickfolk/   clone-this run manifest and evidence
```

## Requirements

- Flutter 3.47+ (`brew install --cask flutter`), Dart SDK bundled
- Xcode 26 with an iOS simulator (for `ios`), CocoaPods
- Android SDK command-line tools with `platform-tools`, `emulator` and an
  AVD named `brickfolk` (for `android`); `ANDROID_HOME` defaults to
  `/opt/homebrew/share/android-commandlinetools`
- Node 20+ and `ffmpeg` (for the e2e harness and recordings)

## Run it

### 1. Server

```sh
cd brickfolk/server
dart pub get
dart run bin/server.dart --port 8080 --db brickfolk.sqlite
# deterministic test server (fixed clock, /test endpoints, seed 1234):
dart run bin/server.dart --port 8080 --test-mode --seed 1234 --db /tmp/brickfolk-dev.db
# standalone binary (sqlite3 ships a build hook, so use `dart build`, not
# `dart compile exe`): -> build/cli/bundle/bin/server + lib/libsqlite3.dylib
dart build cli -o build/cli
```

`GET http://localhost:8080/health` returns `{"ok":true,"protocolVersion":1}`.
Pass `--web-root ../app/build/web` to also serve the web client from `/`.
The server listens on `0.0.0.0` (LAN play) and speaks plain `ws://`; use
`--host 127.0.0.1` to keep it local, and terminate TLS in a reverse proxy for
anything public. `--match-length-scale 2.5` stretches match timers (the
harness does this for software-emulated Android).

### 2. Clients

All clients default to `ws://localhost:8080/ws` (Android uses
`ws://10.0.2.2:8080/ws` to reach the host). Override with
`--dart-define=BRICKFOLK_SERVER=ws://host:port/ws`, or `?server=` on web.

```sh
cd brickfolk/app
flutter pub get

# web
flutter run -d chrome
flutter build web --release          # -> build/web

# iOS simulator
open -a Simulator
flutter run -d "iPhone 17"           # or any booted simulator id
flutter build ios --simulator --debug

# Android emulator
emulator -avd brickfolk &
flutter run -d emulator-5554
flutter build apk --release          # -> build/app/outputs/flutter-apk/app-release.apk

# macOS (native AppKit window, not a WebView)
flutter run -d macos
flutter build macos --debug          # -> build/macos/Build/Products/Debug/Brickfolk.app
```

Sign in with any name (3-16 chars), open **Places**, pick an experience, or
create a **Party** and share its 4-letter code with a friend on another
platform — the leader's *Launch* pulls everyone into the same room. Solo
players can add bots from the launch sheet.

Controls: obby — arrow keys / A·D + space or the on-screen pad; tag — WASD /
arrows / drag joystick; tycoon — tap or click a plot cell, pick a part.

## Cross-platform multiplayer test

```sh
cd brickfolk
./test/multiplayer-e2e.sh                 # builds all four targets, then plays a match
./test/multiplayer-e2e.sh --no-build      # reuse existing builds
./test/multiplayer-e2e.sh --platforms web,ios,macos --bots 1
./test/multiplayer-e2e.sh --experience tag --seed 42 --timeout 600
```

The harness (`test/e2e/run.mjs`):

1. starts the server in test mode with a fixed seed and clock,
2. builds and launches the web client (Playwright/Chromium), the iOS
   Simulator build (`xcrun simctl`), the Android emulator build (`adb`,
   booting the AVD if needed) and the native macOS app,
3. has all four sign in with fixed names, join party `BRIK`, and lets the
   host launch the obby once every member is online,
4. drives each client with the in-app deterministic autopilot
   (`app/lib/src/test_driver.dart`) through lobby → countdown → gameplay →
   results,
5. asserts that all clients report the **same room, leaderboard and
   checksum**, that the server's checksum matches, that every platform is in
   the party and room, and that all evidence exists,
6. saves per-platform `lobby`/`gameplay`/`results` screenshots, a recording
   per client and a composed four-way recording, `report.json`,
   `server-state.json`, `summary.md` and all logs to
   `.devin/clone-this/brickfolk/evidence/tests/multiplayer-<timestamp>/`.

Exit code is non-zero on any mismatch or missing artefact.

Emulator notes: on hosts without Hypervisor.framework (virtualised CI
machines) the wrapper script automatically falls back to a legacy emulator
build under `~/android-legacy` that still supports `-accel off` (pure
software emulation of an arm64 API 25 image); it is slow but functional. On
that emulator in-guest `screenrecord` has no encoder and `screencap` stalls
the device, so the harness records and screenshots the display from the host
through the emulator console (`screenrecord` on the console port, 180 s
segments concatenated with ffmpeg), caps the Android client at
four frames per second (`BRICKFOLK_FRAME_INTERVAL_MS`, applied via
`ThrottledFrameBinding`), and scales match timers (`--match-length-scale`) so
the slow client can finish. Even so, that display finishes a frame only every
15–25 s and can trail the game by minutes, so a throttled Android client is
run with `BRICKFOLK_PHASE_MARKER=true`: the app paints a small phase-coloured
strip on its left edge (`PhaseMarker`), the harness decodes the newest frame
of the in-progress display recording every few seconds and keeps the first
frame whose marker shows each phase (`BRICKFOLK_ANDROID_CAPTURE=marker`, the
default for a throttled client). Because the display can still be showing
the previous app instance when a run starts, a frame counts only once the
server has seen the Android client reach that phase and the phases arrive in
order. The Android client is started with
`BRICKFOLK_AUTO_READY=false` and the harness readies it only after the lobby
frame has reached the display, and the server keeps results on screen for
long enough (`--results-ms`) for that phase to arrive as well.
`BRICKFOLK_ANDROID_CAPTURE=display` grabs the display right after each phase
report instead; clients report `lobby`/`playing`/`results` only once a frame
showing that state has been rasterised (`RasterGate` in the test driver) so
such a grab shows the reported state. The recording is always the display. The starved system process of
that image raises its own "Process system isn't responding" dialog; the
harness taps its "Wait" item (located through `uiautomator dump`), and a
display screenshot is only accepted when the window list shows no such dialog
right after the frame was grabbed, otherwise it is retaken and the run fails
if that keeps happening. Before launching the app the harness also checks that the guest
can route to the host (a long framework stall can drop the emulated Wi-Fi
for good, and `adb reboot` leaves that emulator with a dead adbd, so it
restarts the emulator process instead) and waits for the guest load average
to settle so System UI restarts do not compete with the match. Override with
`BRICKFOLK_EMULATOR`, `BRICKFOLK_AVD`, `BRICKFOLK_EMULATOR_ARGS`,
`BRICKFOLK_ANDROID_FRAME_MS`, `BRICKFOLK_ANDROID_CAPTURE`.

The same run also performs a **visual tour**: web (reference) and native
macOS (actual) sign in as the same player, open the hub, avatar, social,
chat, profile and daily-reward screens, and `test/e2e/visual_compare.py`
normalises and diffs every pair (`visual/<screen>/hub-<screen>-{reference,
actual,diff}.png` + metrics). Skip it with `--no-visual`.

Simulator note: `simctl io recordVideo` keeps its recording state inside
Simulator.app, so a recorder that died without `SIGINT` leaves "Host
recording is already in progress" behind for every later run. The harness
detects that refusal, restarts Simulator.app (the device and the app under
test stay booted) and starts the recorder again.

## Quality gates

```sh
cd brickfolk/shared && dart pub get && dart format --set-exit-if-changed . && dart analyze && dart test
cd brickfolk/server && dart pub get && dart format --set-exit-if-changed . && dart analyze && dart test
cd brickfolk/app    && flutter pub get && dart format --set-exit-if-changed . && flutter analyze && flutter test
cd brickfolk/app    && flutter build web --release && flutter build ios --simulator --debug \
                    && flutter build apk --release && flutter build macos --debug
```

`test/manifest/collect_quality.sh` runs all of the above and stores the logs
under the clone-this run directory; `test/manifest/clean_checkout_build.sh`
copies exactly the files git would commit into a fresh directory and builds
the server, all four clients and the test suites there;
`test/manifest/sweep.py` and
`test/manifest/build_manifest.py` produce the discovery sweeps and the
`state.json` inventory from that evidence. `tool/make_icons.py` regenerates
the app icons for every platform from the original Brickfolk brick mark.

## Evidence

Screenshots and recordings from the automated four-platform match live under
`.devin/clone-this/brickfolk/evidence/tests/multiplayer-<timestamp>/`
(`web|ios|android|macos-{lobby,gameplay,results}.png`,
`recording-<platform>.*`, `recording-four-way.mp4`). Large binaries are kept
out of git and attached to the PR / session instead; `report.json` and
`summary.md` describe each run. The clone-this manifest (`state.json`,
`events.jsonl`) records audits, inventories, checks and sweeps.

## Reference boundary

The source title is a commercial product that could not be run or purchased
in the build environment. Brickfolk's reference is the *publicly documented*
design — hub-and-experiences structure, avatar economy, party and social
features, and the obby / tycoon / tag genres. No proprietary assets, names,
logos, characters or audio were used or reproduced. "Visual parity" in the
manifest means the four Brickfolk clients match **each other** (web is the
baseline); it never claims pixel parity with the original.
