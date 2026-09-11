# Check evidence — Tower Tussle

## Current checkpoint: Skybound rendered-art redesign

See [arcade-redesign.md](arcade-redesign.md) for iteration 5, current builds,
two recorded iOS play tests, the missing-image/overlapping-label fixes, and
verification limits. The sections below describe the earlier vector-art
revision and are retained as history.

## build (passed)
- iOS: `xcodebuild -project TowerTussle.xcodeproj -scheme TowerTussle -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build` → `** BUILD SUCCEEDED **` (Xcode 26.6, Swift 5.9, iOS 17 target).
- Android: `./gradlew assembleDebug` (JDK 17, Gradle 8.11.1 wrapper, AGP 8.7.3, Kotlin 2.0.21) → `BUILD SUCCESSFUL`; APK at `android/app/build/outputs/apk/debug/app-debug.apk`.

## functional
- iOS (passed, recorded in Simulator on iPhone 17 / iOS 26.5): home counters + record; cards deck/collection swap (avg 3.5 → 3.2) and reset; battle arena render, timer countdown, elixir regen, deploy restriction announcement, deploy + hand cycling, troop pathing over bridge, enemy AI deploys, tower projectiles; natural defeat → results (−20 trophies floored at 0, +10 gold) → rematch fresh state → home record 0W/2L/0D; surrender → DEFEAT with 3 enemy crowns → home 0W/3L/0D. Screenshots in `evidence/ios/`.
- iOS graphics retest (iteration 4, recorded, iPhone 17 Simulator): full golden path replayed on the rebuilt art — home branding/pills/beveled buttons, framed card art + swap/reset (avg 3.5 → 3.2), textured arena (grass, river, bridges, walls), shaded towers, troop sprites crossing bridges, typed projectiles, Meteor/Volley FX with particles, floating damage numbers, tower rubble, surrender → illustrated DEFEAT results → rematch → home record update. Two defects found and fixed, then re-verified: hand-card art briefly showing the outgoing card's name/cost during cycling (`visual-card-cycle-mismatch.png` → `visual-card-cycle-fixed.png`) and stacked damage numbers over clustered troops (`visual-damage-number-overlap.png` → `visual-damage-numbers-fixed.png`; numbers now merge when landing near a fresh one).
- Android (partial): JVM unit tests `./gradlew testDebugUnitTest` → 10/10 passed (`evidence/android/battle-engine-unit-tests.xml`) covering hand/next-card setup, elixir regen and cap, deploy zone rules, hand cycling and elixir spend, invalid-deploy announcements, double-elixir timing, match end after overtime, surrender defeat, keep-destroyed 3 crowns. **Runtime UI on an emulator was not exercised**: the host has no hypervisor (`kern.hv_support: 0`, `HVF error: HV_UNSUPPORTED`, see `evidence/android/emulator-boot-failure.log`) and the arm64 emulator has no software fallback. Recorded as blocker `android-emulator`.

## visual (blocked)
- No authorized Clash Royale reference (source, binary, or screenshots) was available, so pixel comparison against a reference is impossible. The visual audit is limited to the clone's own captures (`evidence/ios/*.png`); no parity claim is made. Recorded as blocker `no-reference`.
- Iteration 4 replaced all emoji/flat-fill art on both platforms with original runtime-drawn vector art (`ios/TowerTussle/Art.swift`, `ArenaCanvas.swift`, `Widgets.swift`; `android/.../Art.kt`, `ArenaCanvas.kt`, `Widgets.kt`). The tester's qualitative assessment: a large improvement over the previous build, still a clean cartoon-vector look rather than the reference's pre-rendered 3D production art. Android screens were not visually inspected (no emulator).

## quality (passed)
- Android lint: `./gradlew lintDebug` → 0 errors (`evidence/checks/android-lint-results.txt`); re-run clean after the iteration-4 renderer/UI rewrite.
- Xcode build emits no compiler warnings in project sources.
- clone-this skill tests: `python3 -B -m unittest discover -s .devin/skills/clone-this/tests -v` (run from the plugin root) — see `skill-tests.log`.

## security (passed)
- No network access, no permissions requested (AndroidManifest declares none), no credentials or third-party services. Persistence is local-only (UserDefaults / SharedPreferences). No Supercell assets, fonts, names or code copied; all art is runtime-drawn vector graphics (no bitmap assets).
