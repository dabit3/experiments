# Gambit Court arcade redesign — final verification report

PR: https://github.com/dabit3/experiments/pull/39

## Outcome

The arcade redesign is implemented and verified on web, native macOS and iOS
Simulator. All four targets build from a clean checkout. Full completion remains
blocked by Android emulator virtualization and unavailable iOS audio output.

Source commit: `703c987a67be76cd88e14fafddd00318fddb096d`.

Content fingerprint:
`sha256:c4ab07ded4212875064fd8201f8a3fbd9584f47279a1d315c029b2c61e654bbc`.

Clone: `/Users/devin/repos/experiments/gambit-court`.

Evidence root:
`gambit-court/.devin/clone-this/gambit-court/evidence/tests/arcade-pass4/`.

The PR changes only `gambit-court/`. Shared rules, the authoritative Dart
WebSocket server and native Flutter targets are preserved. The original arcade
identity adds an arena illustration, Bungee/Manrope/IBM Plex Mono typography,
cobalt and yellow controls, ceramic pieces, scoreboards and trophy results.

## Verified scope

| Platform | Clean build | Current runtime |
| --- | --- | --- |
| Web/Chromium | Passed | Black |
| Native macOS | Passed | White |
| iOS Simulator | Passed | Spectator |
| Android | APK passed | Blocked; no runtime screenshot |

The current network run exits 0 with **58/58 assertions**, room `U8LZ5W`.
All three available clients converge through 33 plies ending `17. Rd8#`, score
`1–0`, frozen clocks `212000 / 210000 ms`, matching SAN, PGN and final FEN:

```text
1n1Rkb1r/p4ppp/4q3/4p1B1/4P3/8/PPP2PPP/2K5 b k - 1 17
```

History, spectator reconnect, imported review, rematch seat/color swap and reset,
and themes pass. Four normalized client comparisons pass. Current manual testing
covers 1440×900 desktop and 375×812 phone layouts, fresh invite/checkmate, bot
reply/resignation, result containment, PGN copy/import and keyboard history.
Promotion, premove, keyboard flip, offers and Quick pair manual checks are
explicitly supplemental previous-revision evidence.

The clean-checkout suite passes 27 core tests, 6 server tests and 6 widget tests;
Dart formatting and analysis, Flutter analysis, ShellCheck, JavaScript syntax,
Python lint/compilation and npm audit pass. Web, macOS, iOS Simulator and Android
release APK builds pass. The token contrast audit passes 37 combinations with
minimum ratio 4.542. This is not a complete screen-reader or accessibility audit.

Production `/health` responds successfully and `/control/state` returns 404
without `--control`. Source scans found no tracked credential files or credential
patterns. The manual browser console has no page errors. The network harness did
not persist its browser console.

## Recording and screenshots

The recommended recording is `network/arcade-pass4-final-annotated.mp4`:
80 seconds, 15fps, real-time playback, 1600×1250 including a caption strip.
It begins with the three windows separated, shows macOS White versus web Black
with iOS spectating, and ends before parity navigation/resizing.

The original recording editor compressed 83.267 seconds to 11.792 seconds due
to malformed frame-rate metadata. The delivered fallback uses the original
timestamps and transparently postprocessed setup/test/assertion captions.
`network/rendered-captions.json` records their timing.

`network/{web,macos,ios}-{lobby,midgame,results}.png` provides nine current platform
captures. Full-desktop lobby, midgame and checkmate captures retain window
context. The late rematch frame is correctly named `fullscreen-rematch.png`;
`fullscreen-checkmate.png` is a verified frame extracted at raw 60 seconds.

## Run locally

Install the versions and platform prerequisites documented in `README.md`.
From `gambit-court/`, start the server:

```sh
(cd server && dart pub get && dart run bin/server.dart --port 8765)
```

In a second terminal, select a client:

```sh
cd app
flutter pub get
flutter run -d chrome --dart-define=GC_SERVER=ws://127.0.0.1:8765/ws
flutter run -d macos --dart-define=GC_SERVER=ws://127.0.0.1:8765/ws
flutter devices
flutter run -d <ios-simulator-id> --dart-define=GC_SERVER=ws://127.0.0.1:8765/ws
flutter run -d <android-emulator-id> --dart-define=GC_SERVER=ws://10.0.2.2:8765/ws
```

Automated match, from `gambit-court/`:

```sh
(cd test/e2e && npm ci && npx playwright install chromium)
PLATFORMS=web,ios,macos WHITE=macos BLACK=web ./test/multiplayer-e2e.sh
```

For all four devices on a capable host:

```sh
./test/multiplayer-e2e.sh
```

The harness starts its own deterministic server, uses the opt-in automation
bridge and frozen clocks, launches available clients and writes evidence.
The annotated independent-recorder invocation is preserved in
`network/commands.txt`; `--skip-build` was used only after current runtime builds.

## Completion gate and external blockers

Two independent final zero-discovery sweeps, all ten audits and all five executed
checks are indexed against the current fingerprint. Historical events were
preserved and the final event was appended.

`verify_state.py` exits **1**, intentionally. Its only remaining issues concern
the blocked run, nonempty blocker list, and unverified Android/four-way/audio
inventory records. It reports no missing evidence, stale completed records,
fingerprint mismatch, failed comparison or missing final sweep.

1. **Android:** `kern.hv_support=0`. The emulator cannot run despite several
   configurations; a compiled APK is not runtime proof. Resume the four-device
   match on a virtualization-enabled host.
2. **iOS sound:** Simulator CoreAudio has no output device and reports errors
   `-66680` and `560947818`. Sound assets and graceful failure handling exist,
   but audible output must be checked on a capable host or physical device.

The verifier command uses the installed clone-this skill:

```sh
python3 -B "$CLONE_THIS_SKILL/scripts/verify_state.py" \
  .devin/clone-this/gambit-court/state.json
```

Set `CLONE_THIS_SKILL` to the installed skill directory. The manifest's absolute
`clone_root` must match the checkout used for verification; binary evidence is
delivered separately and must also be present.

## Reference and visual boundary

The commercial reference was not run or purchased. Public FIDE/SAN/PGN rules and
documented chess conventions are the reference; branding, art and sound are
original. Flutter CustomPainter is the recorded alternative to Flame.

Visual comparisons use Gambit Court web as the baseline for its own native
clients. Native captures are normalized to logical dimensions and application
content, then compared in 20×20 blocks using coverage and mean color tolerances.
Zero differing normalized blocks does not mean raw pixel identity or literal
parity with a commercial game.
