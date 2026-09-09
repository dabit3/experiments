# Check evidence — Tower Tussle

## build (passed)
- iOS: `xcodebuild -project TowerTussle.xcodeproj -scheme TowerTussle -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build` → `** BUILD SUCCEEDED **` (Xcode 26.6, Swift 5.9, iOS 17 target).
- Android: `./gradlew assembleDebug` (JDK 17, Gradle 8.11.1 wrapper, AGP 8.7.3, Kotlin 2.0.21) → `BUILD SUCCESSFUL`; APK at `android/app/build/outputs/apk/debug/app-debug.apk`.

## functional
- iOS (passed, recorded in Simulator on iPhone 17 / iOS 26.5): home counters + record; cards deck/collection swap (avg 3.5 → 3.2) and reset; battle arena render, timer countdown, elixir regen, deploy restriction announcement, deploy + hand cycling, troop pathing over bridge, enemy AI deploys, tower projectiles; natural defeat → results (−20 trophies floored at 0, +10 gold) → rematch fresh state → home record 0W/2L/0D; surrender → DEFEAT with 3 enemy crowns → home 0W/3L/0D. Screenshots in `evidence/ios/`.
- Android (partial): JVM unit tests `./gradlew testDebugUnitTest` → 10/10 passed (`evidence/android/battle-engine-unit-tests.xml`) covering hand/next-card setup, elixir regen and cap, deploy zone rules, hand cycling and elixir spend, invalid-deploy announcements, double-elixir timing, match end after overtime, surrender defeat, keep-destroyed 3 crowns. **Runtime UI on an emulator was not exercised**: the host has no hypervisor (`kern.hv_support: 0`, `HVF error: HV_UNSUPPORTED`, see `evidence/android/emulator-boot-failure.log`) and the arm64 emulator has no software fallback. Recorded as blocker `android-emulator`.

## visual (blocked)
- No authorized Clash Royale reference (source, binary, or screenshots) was available, so pixel comparison against a reference is impossible. The visual audit is limited to the clone's own captures (`evidence/ios/*.png`); no parity claim is made. Recorded as blocker `no-reference`.

## quality (passed)
- Android lint: `./gradlew lintDebug` → 0 errors, 7 warnings (`evidence/checks/android-lint-results.txt`).
- Xcode build emits no compiler warnings in project sources.
- clone-this skill tests: `python3 -B -m unittest discover -s .devin/skills/clone-this/tests -v` (run from the plugin root) — see `skill-tests.log`.

## security (passed)
- No network access, no permissions requested (AndroidManifest declares none), no credentials or third-party services. Persistence is local-only (UserDefaults / SharedPreferences). No Supercell assets, fonts, names or code copied; all art is runtime-drawn vectors/emoji.
