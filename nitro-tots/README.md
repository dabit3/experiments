# Nitro Tots

An original arcade kart racer for **web, iOS, Android and macOS** with real
cross-platform multiplayer: one Flutter/Flame codebase, one shared deterministic
Dart simulation, and one authoritative WebSocket server that every platform
races through. A player on the web can race a player on an iPhone, an Android
phone and a Mac in the same room, with server-side bots filling any empty seats.

Nitro Tots is built from the publicly documented design of arcade kart racers
(drift boosts, item boxes, Grand Prix cups, battle arenas). All characters,
karts, tracks, items, names, art, fonts (OFL) and audio are original.

## What is in the game

- **8 characters** (Pip, Bea, Juno, Ozzie, Mabel, Kiki, Rocco, Tank) × **6 karts**
  (Jellybean, Tin Can, Bubble Buggy, Pinewood Racer, Rocket Scoot, Big Wheel)
  with different speed / accel / handling / weight stats.
- **4 hand-designed tracks** — Sprinkle Speedway, Mossy Hollow, Tin City Loop,
  Frostbite Pass — each with shortcuts, jumps, boost pads and hazards, plus the
  **Bumper Bowl** battle arena.
- **Drift + mini-turbo**, slipstream, off-road slowdown, wall bounces, wrong-way
  detection, respawns.
- **8 items** with position-weighted odds: Turbo Can, Triple Turbo, Homing
  Rocket, Bouncy Orb, Syrup Slick, Bubble Shield, Thunder Zap, Comet Ride.
- **Modes:** single race, **Grand Prix** (Sugar Cup, Nitro Cup — points 15/12/10/9/8/7/6/5,
  standings across 4 races), **time trial with ghost**, **battle** (balloons).
- **Screens:** title, garage (character/kart), track & cup select, online lobby
  with join codes, race HUD (position, lap, item, minimap, countdown, wrong-way,
  boost meter), results + podium, Grand Prix standings, settings (controls,
  audio, theme).
- **Multiplayer:** rooms with 4–6 character join codes, host controls, ready-up,
  reconnect/resume with a session token, up to 8 racers, deterministic bots for
  empty seats, client-side prediction + reconciliation for the local kart and
  interpolation for remote karts.
- **Design system:** Fredoka display + Nunito body type scale, colour tokens
  (nitro orange, bubblegum, sky, lime, sunny, grape, mint), spacing/elevation
  scale, light and dark themes, responsive phone / tablet / desktop layouts,
  safe-area aware, keyboard + touch + mouse input.

## Layout

```
nitro-tots/
  app/                      Flutter app (web, ios, android, macos runners)
    lib/game/               Flame race game, HUD, kart/track vector art, controls
    lib/net/                WebSocket client, prediction/reconciliation
    lib/screens/            title, garage, track, online, lobby, race, podium, settings
    lib/theme, lib/widgets  design tokens and shared widgets
    test/                   widget smoke tests (all screens × 4 viewports × 2 themes)
  packages/nitro_core/      shared deterministic sim, tracks, items, bots, protocol types
  packages/nitro_server/    authoritative shelf + web_socket_channel server
  test/                     multiplayer-e2e.sh + Playwright web driver + verifier
  tools/gen_audio.py        generates the original WAV sound set
  PROTOCOL.md               JSON-over-WebSocket protocol
  .devin/clone-this/        clone-this run manifest and evidence index
```

## Requirements

- Flutter 3.47+ (`brew install --cask flutter`), Dart SDK bundled.
- macOS with Xcode 26 + an iOS Simulator for the iOS/macOS targets, CocoaPods.
- Android SDK command-line tools + platform 35 / build-tools for the Android target;
  an AVD (or physical device) to run it. `ANDROID_HOME` must be set.
- Node 18+ (only for the Playwright web driver used by the e2e test).
- Python 3.9+ (e2e verifier, clone-this scripts).

## Run it

Start the server (any platform's client can point at it from Settings → Server):

```sh
cd nitro-tots/packages/nitro_server
dart pub get
dart run bin/nitro_server.dart --port 8787 --seed 4242 -v
# GET http://localhost:8787/health   → {"ok":true,...}
# GET http://localhost:8787/rooms/ABCD → room inspection
```

Then run one or more clients from `nitro-tots/app`:

```sh
flutter pub get

flutter run -d chrome                       # web
flutter run -d macos                        # native macOS window
open -a Simulator && flutter run -d iPhone  # iOS Simulator
emulator -avd <name> & flutter run -d emulator-5554   # Android emulator

# release builds
flutter build web --release        # app/build/web
flutter build macos --release      # app/build/macos/Build/Products/Release/Nitro Tots.app
flutter build ios --simulator      # app/build/ios/iphonesimulator/Runner.app
flutter build apk --release        # app/build/app/outputs/flutter-apk/app-release.apk
```

Play: **Online → Create room** on one client, share the join code, **Join** on
the others, ready up, host presses **Start race**. Keyboard: arrows / WASD,
Space or Shift to drift, Z / X / Enter / E for items, Q to look back, Esc to
pause. Touch: on-screen gas/brake/steer/drift/item controls.

The Android emulator reaches the host machine's server at `ws://10.0.2.2:8787/ws`
(the default on Android); other platforms default to `ws://localhost:8787/ws`.

## Automated cross-platform multiplayer test

`test/multiplayer-e2e.sh` starts the server with a fixed seed, builds and
launches one client per platform (web via Playwright, iOS Simulator via
`simctl`, Android via `adb`, the native macOS app), has them all join the same
room, runs a full 4-race Grand Prix with the scripted autopilot, and asserts
that every client reported the same final standings and result hash as the
server. It writes per-platform screenshots for lobby / racing / results /
match-over, a screen recording of the whole match, all logs and the verifier
report to an evidence directory.

```sh
cd nitro-tots
xcrun simctl boot "iPhone 17"                     # any booted iOS simulator
NT_PLATFORMS="web ios android macos" bash test/multiplayer-e2e.sh
# → PASS: all clients (...) agree on the final standings and hash

# knobs
NT_PLATFORMS="web ios macos"   # subset (android needs an attached emulator/device)
NT_BUILD=0                      # reuse existing builds
NT_RECORD=0                     # skip the screen recording
NT_OUT=/tmp/nitro-e2e           # evidence dir (default: .devin/clone-this/nitro-tots/evidence/multiplayer/<stamp>)
NT_SEED=4242 NT_ROOM=E2E NT_LAPS=1 NT_CUP=sugar NT_TIMEOUT=900
```

Clients are put into test mode with `--dart-define`s (`NT_TEST`, `NT_ROOM`,
`NT_LAPS`, `NT_CUP`; see `app/lib/state/test_config.dart`) or, for the web
build, URL parameters (`?test=1&room=E2E&players=3`). In test mode the client
joins the room automatically, readies up, the first client hosts and starts
once every expected player is present, and the autopilot drives the kart. Every
client posts `test_report` messages with the phase, displayed standings and
hash; `test/verify_room.py` reads them back from `GET /rooms/<code>` and
compares them with the server's authoritative result.

### Latest verified run

Live clients: **web + iOS Simulator + macOS** (3 humans + 5 bots, Sugar Cup,
4 races, seed 4242) → `PASS`, all three clients and the server reported the
same result hash and identical standings (the hash is recorded in the run's
`result.json`; it is a function of the seed, the track set and the racers, so
it changes whenever the deterministic core changes). Screenshots and the recording are
linked from the pull request; the evidence index lives in
`.devin/clone-this/nitro-tots/evidence/` (large PNG/MP4 files are attached to
the PR rather than committed).

**Android:** the release APK builds from the same codebase
(`flutter build apk --release`), but the Android emulator could not boot on the
build machine (`kern.hv_support = 0` — no nested virtualization, so the arm64
system image fails with `HVF error: HV_UNSUPPORTED`). The live Android seat was
therefore not part of the verified run. With an attached emulator/device the
same script covers it: `NT_PLATFORMS="web ios android macos"`.

## Cross-platform visual parity

The web build is the visual baseline for the other clients. `test/visual_parity.py`
opens every menu screen (title, garage, track select, settings, online) on the
web client (Playwright, 800×532 CSS px, DPR 1) and in the native macOS app
(window content area forced to 800×532 via `NT_WINDOW=800x532`), with the same
synthetic profile, light theme, persisted preferences ignored and animations
frozen (`?still=1`), and compares the captures pixel by pixel after a documented,
narrowly bounded normalization: the two bottom window corners (macOS rounds them)
are masked, both captures are box-downscaled 8×, and a cell counts as different
when any channel differs by more than 64/255. That absorbs the sub-pixel glyph
rasterization differences between Chromium/CanvasKit and Impeller/Metal while
still flagging any layout, geometry, colour-token or copy mismatch — every run
also proves this with a sensitivity self-check (a 4 px shift of the baseline and
a different screen must both register as differences). Raw captures, normalized
images, magenta diff maps and `visual_parity.json` land in the evidence
directory. iOS is captured as declared evidence only: the phone layout family
(safe-area insets, compact breakpoints) cannot share a viewport with desktop.

```sh
cd nitro-tots && python3 test/visual_parity.py --out .devin/clone-this/nitro-tots/evidence/parity
# → PASS: all screens match after normalization
```

## Development checks

```sh
cd nitro-tots/packages/nitro_core   && dart format --set-exit-if-changed . && dart analyze && dart test
cd nitro-tots/packages/nitro_server && dart format --set-exit-if-changed . && dart analyze && dart test
cd nitro-tots/app                   && dart format --set-exit-if-changed lib test && flutter analyze && flutter test
```

`flutter test` in `app/` renders every screen at phone (portrait + landscape),
tablet and desktop sizes in both themes with semantics enabled and fails on any
layout exception or overflow.
