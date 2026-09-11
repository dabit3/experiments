# Arcade redesign verification — September 11, 2026

## Status

**Blocked; not a completed four-platform redesign run.**

Source fingerprint:
`sha256:2c6e754e4196f7105b67dc01c0dcc562fd7b8d44b3420c0fc7d4601617732ea4`

The Android 35 ATD guest running under software-only
TCG/SwiftShader crashed its `system_server` after nine shared moves in
`e2e-20260911T043452Z`. Zygote recorded SIGSEGV and exited; Android services
reported `DeadSystemException`. Android disconnected, and the game ended by
Board B abandonment. After preserving that state, the stalled driver was
stopped by shutting down its test server; its cleanup exit code was 52.

The required match must be repeated on a stable hardware-accelerated Android
emulator or connected Android device. The three missing Android visual cases
and measured 60 fps on supported target hardware remain pending. The manifest
is `blocked`, and `verify_state.py` exits 1 as expected for this incomplete run.

## Completed checks

| Check | Result | Evidence |
| --- | --- | --- |
| Format / analysis | Pass: Dart format, core/server analysis, Flutter analysis | `arcade-quality.log` |
| Tests | Pass: core 22, server 10, app 13, launcher generation 1 | `arcade-quality.log` |
| Script syntax | Pass: Bash, Node and Python compilation | `arcade-quality.log` |
| Fresh sessions | Pass: seeds 73 and 97; host guard, room/partner chat, transfer/pre-drop, resignation/BPGN, rematch, resume, Leave and bots | `arcade-fresh-sessions.log`, `fresh_sessions.dart` |
| Clean builds | Pass: server executable, web release, iOS Simulator, Android release APK, macOS release | `arcade-clean-checkout.log` |
| Clean source | All 167 fingerprinted source files and modes match the clean build copy | `arcade-clean-source-match.log` |
| Security checks | No credential-pattern matches; npm audit reports no vulnerabilities | `arcade-security-scan.log`, `arcade-npm-audit.json` |
| Current three-platform match | Pass: web A-White, iOS A-Black, macOS B-Black, bot B-White; eight moves, 1-0 by checkmate, identical FENs/moves/BPGN/result/score | `partial-visual-current/summary.json`, `partial-visual-current/e2e.log` |
| Current three-platform visuals | 7/7 normalized zero; negative controls nonzero | `partial-visual-current/visual/summary.json` |

The independent three-platform driver uses a simplified Board A mate and one
server bot. It is saved as `partial-visual-current/driver.sh`; it is not the
required four-platform driver and does not substitute for that gate.

Text logs have trailing whitespace normalized. The vendored Barlow license
is retained verbatim; its upstream trailing space is excluded from the Git
whitespace check.

## Visual evidence

The unchanged comparison bounds use tolerance 16, a 2px edge band,
anti-aliasing handling and a 1px jitter radius. Each comparison JSON records
its raw differences and normalization. No tolerances or masks were widened
to obtain the current result.

- iOS Home dark, Home light and Results: normalized 0.
- macOS Home dark, Home light, Lobby and Results: normalized 0.
- Negative controls: screen swap 272956 px; 4px shift 10508 px;
  theme swap 781441 px.

`partial-visual-current/` contains full lobby, gameplay and Results captures
for web, iOS and macOS, plus a 95.65-second recording. Android has a current
lobby capture in `e2e-20260911T043452Z/android-lobby.png`; it is visibly dimmed
by the software-emulated host capture path. The earlier diagnostic
`android-arcade-recovery/android-home-client.png` is a client-rendered frame,
not a host screenshot or an Android visual-parity pass.

## Reproduce

From the repository root:

```sh
cd swapmate/server
dart pub get
dart run bin/server.dart --port 8787 --static ../app/build/web
```

In a second terminal:

```sh
cd swapmate/app
flutter pub get
flutter build web --release
flutter run -d macos
flutter run -d <iphone-simulator-id>
flutter run -d emulator-5554
```

Run the required full gate from the game directory:

```sh
test/multiplayer-e2e.sh --platforms web,ios,android,macos
```

## Boundaries

The reference is publicly documented chess.com/FICS Bughouse rules and design,
not a running commercial title. All Swapmate artwork and branding are
original. Visual parity means Swapmate's own clients compared with its web
baseline under the recorded normalization.

VoiceOver/TalkBack traversal and sustained 60 fps on all target hardware are
not verified. A dropped socket can resume with its in-memory token; a full
browser page reload does not restore that token.
