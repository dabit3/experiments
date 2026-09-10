# Lastfort

Lastfort is an original, top-down battle-royale shooter with building. Up to
16 players (deterministic bots fill the empty slots) drop from a sky bus onto
a 1000 x 1000 island, harvest wood / brick / metal, loot chests for weapons,
ammo and shields in five rarity tiers, build and edit walls, floors, ramps and
roofs, and outlast a shrinking storm. Solo, duos and squads; spectating after
elimination; a hub with a locker of original cosmetics, match stats and an
XP-based season pass.

One Dart/Flutter code base ships four real clients (web, iOS, Android, macOS)
that all play together on one authoritative Dart server. Nothing in the
repository is copied from any commercial game: art, names, cosmetics, map and
audio cues are original, and the design reference was public documentation of
the battle-royale genre (see `.devin/clone-this/lastfort/evidence/discovery/`).

```
lastfort/
  core/     shared Dart package: rules, deterministic simulation, protocol types, bots
  server/   authoritative WebSocket server (rooms, join codes, bots, reconnection, test controls)
  client/   Flutter + Flame app: web, iOS, Android, macOS
  test/     cross-platform multiplayer end-to-end harness
  PROTOCOL.md  JSON-over-WebSocket protocol
  .devin/clone-this/lastfort/  clone-this run manifest and evidence
```

## Requirements

- Flutter 3.47 (stable) with Dart 3.13 — `brew install --cask flutter`
- Xcode 26 with an iOS 26 simulator (iOS / macOS targets)
- Android SDK with platform-tools, `emulator`, `build-tools;36`,
  `platforms;android-36` and an arm64 AVD (Android target)
- Node 20+ (web end-to-end driver, installs Playwright Chromium)
- Python 3.9+ (harness helpers, clone-this scripts)

`core` and `server` are plain Dart packages; `client` depends on `core` by
path.

## Run the server

```sh
cd lastfort/server
dart pub get
dart run bin/server.dart --port 8787            # ws://localhost:8787/ws
dart run bin/server.dart --web-root ../client/build/web   # also serve the web build
```

Flags: `--port`, `--host`, `--web-root <dir>`, `--fast` (short bus/storm
timings for every room), `--seed N`, `--quiet`. `GET /health` reports rooms
and connected clients; see `PROTOCOL.md` for the rest.

## Run the clients

All clients default to `ws://localhost:8787/ws` (Android: `ws://10.0.2.2:8787/ws`).
Override with `--dart-define=LASTFORT_SERVER=ws://host:port/ws` or, on the
web, `?server=ws://host:port/ws`.

```sh
cd lastfort/client
flutter pub get

# web
flutter run -d chrome
flutter build web --release --no-web-resources-cdn   # -> build/web

# iOS simulator
open -a Simulator
flutter run -d iPhone
flutter build ios --simulator --debug                # -> build/ios/iphonesimulator/Runner.app

# Android emulator
$ANDROID_HOME/emulator/emulator -avd <avd> &
flutter run -d emulator-5554
flutter build apk --debug                            # -> build/app/outputs/flutter-apk/app-debug.apk

# macOS
flutter run -d macos
flutter build macos --release                        # -> build/macos/Build/Products/Release/Lastfort.app
```

Playing across platforms: one client creates a room in the hub (choose Solo /
Duos / Squads), the others enter the 5-letter join code, everyone readies up
and the host presses Start. Empty slots are filled with bots. A client that
loses its connection mid-match is kept alive for 60 s and resumes where it was
when it reconnects.

### Controls

| Action | Keyboard / mouse | Touch |
|--------|------------------|-------|
| Move / sprint | WASD or arrows, Shift | left stick |
| Aim / fire | mouse, left button | right stick (fire on release), Fire button |
| Jump / drop from bus | Space | Jump |
| Interact / open chest | E | Interact |
| Build mode, piece, material | Q; Z X C V; M | Build, piece chips |
| Place / edit | left click; F | tap, Edit |
| Hotbar | 1-6, Tab | hotbar |
| Reload / drop | R / G | Reload |
| Spectate next, emote, thank | Tab, B, T | buttons |
| Match menu (leave) | Esc | menu button |

## Automated four-platform multiplayer test

```sh
cd lastfort
./test/multiplayer-e2e.sh
```

The harness builds the web, iOS-simulator, Android APK and macOS release
artifacts with test defines, starts the server on `:8790`, launches the web
client under Playwright/Chromium, installs and launches the iOS build with
`xcrun simctl`, the Android build with `adb`, and the macOS app natively. All
four join room `LFE2E` as one squad, enable the deterministic server-side
autopilot, the host starts the match (bots fill the other 12 slots), and the
clients play a full fast match: bus, drop, harvest, build, loot, storm phases,
eliminations. At the end every client reports the summary it displayed; the
harness asserts that all reports are byte-identical to each other and to the
server's own summary, that the humans shared one team, that a winner exists,
that harvesting and building happened, and that the storm progressed. Test
builds pin the light theme and load a fresh, namespaced profile
(`LASTFORT_TEST=<id>`), so a run never inherits or disturbs the real profile,
theme or session token on the device. It also
captures lobby / bus / gameplay / midgame / matchover / results screenshots per platform
plus a screen recording of all clients at once, then cuts that recording into
an edited review video (see below).

Output goes to `.devin/clone-this/lastfort/evidence/tests/e2e-<timestamp>/`
(`run.json`, `result.json`, `report.md`, `reports.json`, `server-summary.json`,
`*-lobby.png` … `*-results.png`, `all-*.png` composites, `four-way.mov`,
`harness.log`, `server.log`). macOS screenshots are window-level captures
(`test/window_id.swift` resolves the window id) so nothing overlapping the
window leaks into the evidence. `test/pixel_diff.py` then compares the web
capture (baseline) with the macOS content area for the lobby, match-over and
results screens and writes `diff-web-macos-*.png` plus `visual.jsonl` with the
measured differing-pixel counts.

Environment overrides: `LF_PORT`, `LF_ROOM`, `LF_SEED`, `LF_OUT`,
`LF_SKIP_BUILD=1`, `LF_BUILD_ALL=1`, `LF_IOS_UDID`, `LF_AVD`,
`LF_MATCH_TIMEOUT`, `LF_REVIEW=0`, and `LF_PLATFORMS=web,ios,macos` to run
without a platform (only the listed platforms are built; the run is then
recorded as partial in `run.json`; it never counts as a full four-way pass).

### Web x iOS review video

```sh
cd lastfort
LF_PLATFORMS=web,ios ./test/multiplayer-e2e.sh
```

runs two clients in two separate environments in parallel — Chromium and the
iOS Simulator — against one server and one room, in a two-up window layout.
When the match ends `test/review_video.py` turns the raw `four-way.mov` into
`review.mp4`: a title card, six captioned chapters cut around the moments the
harness took its screenshots (lobby, drop, gameplay, storm, match over,
results) with a platform tag over each window, side-by-side gameplay and
results comparison cards with each client's digest, and a PASS/FAIL verdict
card, plus `review.mp4.chapters.json` with chapter timestamps. Cards and
captions are rendered with Pillow in the game's Rajdhani font; ffmpeg only
trims, crops, overlays and concatenates. Anchors come from `timeline.jsonl`
(wall-clock times of the recording start and every screenshot), so the cut is
reproducible from the run directory: `python3 test/review_video.py <run-dir>`.
Requires `ffmpeg` and `pillow`.

The Android emulator needs hardware virtualization. On a host without it
(`emulator -accel-check` fails, e.g. a macOS VM without nested
virtualization) the harness stops with an explicit message; attach a physical
device over `adb` or run with `LF_PLATFORMS=web,ios,macos`.

## Development checks

```sh
cd lastfort/core   && dart format --set-exit-if-changed . && dart analyze && dart test
cd lastfort/server && dart format --set-exit-if-changed . && dart analyze && dart test
cd lastfort/client && dart format --set-exit-if-changed lib test && flutter analyze && flutter test
```

`core/tool/check_web_determinism.sh` runs the same seeded island generation
and a full bot match on the Dart VM and as dart2js output under Node and
fails if the transcripts differ, which guards the web client against integer
semantics that diverge from native.

The server suite includes a protocol-level version of the four-platform
match (`four platforms in one squad finish a match with identical summaries`)
that runs in a few seconds without any simulator.

## Design notes

- **Authority**: the server runs `Sim` from `core` at 20 Hz and is the only
  source of truth for movement validation, hits, damage, building, looting and
  the storm. Clients send `InputFrame`s and predict their own movement; the
  snapshot carries the last applied input sequence for reconciliation.
- **Interest management**: each snapshot contains only what the viewer can
  see (radius 90 around the player, or around the spectated player), with
  delta-encoded structures, resource nodes and chests.
- **Determinism**: island, loot, chests, bus path, storm centres and bot
  behaviour derive from the match seed via a small xorshift `Rng`, so a seeded
  fast room replays identically on every platform.
- **Design system**: `client/lib/app/theme.dart` defines colour tokens
  (dark and light), a type scale, spacing, radii, elevation and motion
  durations; `widgets.dart` holds the shared panel, button, chip and badge
  primitives used by hub, locker, pass, settings, HUD and results screens.
  Layouts adapt to phone, tablet and desktop widths, honour safe areas, and
  input is keyboard + mouse on desktop/web and twin-stick touch on phones.

## Evidence

The clone-this run manifest lives in `.devin/clone-this/lastfort/state.json`
with `events.jsonl` next to it. Screenshots and the recording of the automated
match are kept out of git (see the pull request for the attached images).
