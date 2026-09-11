# Skybound rendered-art redesign — iteration 5

Current source fingerprint:
`sha256:a75980137fec6536c61bdbdab78bb5e8ebee0d8a8ff0082885c0ae614443a0a0`

## Delivered artwork

Original Blender 4.5.3 models/materials and Pillow 11.3.0 packaging replace the
main vector illustrations. Each native client contains the same 25 PNGs:
10 card portraits, 8 troop atlases, 4 towers, hero island, arena and emblem.
Atlases contain 12 poses: 6 blue and 6 red. Matching native app icons and four
synthesized WAV cues are included. Runtime installation needs no art tools,
network, accounts, downloaded models, or third-party game assets.

`art/assets.json` records source PNG dimensions/checksums. Packaging checked
all 25 PNG pairs for byte identity. Native build resource processing may
re-encode PNGs; Swift loads loose resources explicitly through bundle URLs.

## Build and source checks on the current implementation

- iOS: XcodeGen generation, `xcodebuild ... build analyze` succeeded.
- iOS: `xcrun swiftc -frontend -parse ios/TowerTussle/*.swift` succeeded.
- Android: `./gradlew assembleDebug testDebugUnitTest lintDebug` succeeded.
  10 engine tests, 0 failures/errors/skips; lint: 0 errors, 7 warnings.
- Art scripts: Ruff 0.12.11 `--select E9,F63,F7,F82` passed.
- `git diff --check` passed.
- clone-this plugin: 92 dependency-free tests passed from its installed root.
  The requested `devin skills list --trigger user` CLI check could not run:
  this macOS host has no `devin` executable. The installed skill was read and
  used through the session tooling.

Logs: `arcade-ios-build.log`, `arcade-android-build.log`,
`arcade-android-lint.txt`, `arcade-engine-tests.xml`, `arcade-skill-tests.log`
in this directory.

## iOS visual/play regression

Device: iPhone 17 Simulator, iOS 26.5. Testing was delegated to the persistent
UI tester, using actual interactions plus native and full-desktop captures.

The first run exposed a missing hero. Runtime logs showed SwiftUI's named
image lookup only searched the asset catalog. All image entry points now use
an explicit bundle URL/UIImage cache, including cards, arena, towers and atlases.
The rebuilt game was then recorded through Home, all ten Cards, deck swap/reset
and relaunch persistence, deployment restrictions, insufficient elixir, rapid
hand cycling, bridge combat, Whelp flight, Meteor, Volley, natural defeat at
2:39, Results, rematch, surrender and persisted rewards. No app crash occurred.
This full-match run preceded the final rendering-only polish below.

That run also exposed overlapping opposing damage numbers. Both renderers now
measure their maximum animated bounds, reserve separate rectangles inside the
arena, and keep recent labels visible without concatenation. Troop presentation
was enlarged about 15%; gameplay collision radii remain unchanged.

The **current fingerprint** was then tested in a second recording: 2:31 of active
combat with Bone Brigade bridge swarms, simultaneous red/yellow damage, pop/fade
states, same-color labels, enlarged sprites, health bars and team rings.
Sampled frames showed separate yellow 140/70 and red 360/260/160. Home, all card
portraits, swap/reset, Battle, surrender Results and rematch passed smoke checks.
Final observed profile: 220 gold, 0 trophies, 0W/12L/0D. No clipping, app crashes
or unresponsive controls were observed.

Current native captures are named `evidence/ios/polish-*.png`; the primary
annotated recording is `tower-tussle-label-polish-edited.mp4`, attached to the
session. PR #12 contains the selected captures and a gameplay clip. Earlier
`arcade-*` captures/full natural-match recording document the pre-polish run;
they are not relabeled as current-fingerprint evidence.

## Limits and checkpoint status

- Android runtime remains blocked. Recheck returned `kern.hv_support: 0` and no
  attached adb devices; the earlier HVF failure remains applicable. Android
  screenshots, sound and interaction behavior are not claimed as verified.
- Audio audibility, physical haptics, quantitative FPS, every animation frame,
  VoiceOver and other screen sizes were not tested.
- Dense swarms still overlap individual silhouettes; team colors and bridge
  crossings stayed readable in the observed test.
- No authorized Clash Royale reference exists. Source pixel parity, proprietary
  behavior and commercial-production quality equivalence are not claimed.
- This is a blocked clone-this checkpoint, not a passed parity gate. Historical
  inventory entries retain their actual earlier verification revisions. Only
  explicitly rerun checks/new visual evidence are assigned this fingerprint.
- No new runtime permissions, networking, external services or credential
  handling were introduced. This is a local game; the audit is source review,
  not a penetration test or formal security assessment.
