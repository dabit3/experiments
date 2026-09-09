# Tower Tussle

A real-time card/tower battle game in the spirit of Clash Royale, built twice from
scratch: a native iOS app (Swift 5.9, SwiftUI, `Canvas`) and a native Android app
(Kotlin, Jetpack Compose). Both share the same rules, card roster, arena layout and
visual language; neither uses any Supercell code, art, fonts or names.

## Gameplay

- 18x32 logical arena, river across the middle, two bridges. Player deploys troops on
  the lower half; spells can land anywhere.
- Two guard towers plus a central keep per side. Destroying a tower earns a crown;
  destroying the keep is an instant 3-crown win.
- Elixir starts at 5, regenerates continuously, caps at 10. Double elixir in the last
  regulation minute; 3:00 regulation then 1:00 sudden-death overtime.
- 4-card hand with a next-card preview; 10-card roster (Knight, Archers, Colossus,
  Duelist, Sharpshooter, Gremlins, Bone Brigade, Whelp, Meteor, Volley).
- Enemy AI deploys troops and cluster-targets spells.
- Trophies, gold, W/L/D record and deck composition persist across launches
  (UserDefaults / SharedPreferences). Surrendering counts as a 3-crown defeat.

## iOS

```sh
cd ios
xcodegen generate               # regenerates TowerTussle.xcodeproj from project.yml
xcodebuild -project TowerTussle.xcodeproj -scheme TowerTussle -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build
xcrun simctl boot "iPhone 17"
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/TowerTussle.app
xcrun simctl launch booted com.dabit3.towertussle
```

## Android

Requires JDK 17 and an Android SDK with platform 35 (`sdk.dir` in `android/local.properties`
or `ANDROID_HOME`). `settings.gradle.kts` lists Google's Maven Central mirror ahead of
Maven Central to avoid rate limiting.

```sh
cd android
./gradlew assembleDebug testDebugUnitTest lintDebug
emulator -avd TowerTussle &          # any API 26+ AVD
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.dabit3.towertussle/.MainActivity
```

`app/src/test` holds JVM unit tests for the battle engine (hand cycling, elixir,
deployment rules, timers, surrender, crowns).

## Graphics

All artwork is original and drawn at runtime as vector graphics; there are no bitmap
assets. Each platform has the same three rendering layers:

- `Art` (`ios/TowerTussle/Art.swift`, `android/.../Art.kt`): palette, shared shape
  helpers, tower/character/icon painters and the per-card illustrations.
- `ArenaCanvas`: textured grass, river with animated water, plank bridges, perimeter
  walls and scenery; shaded towers with flags and keep dome; animated troop sprites
  with shadows and hit flashes; typed projectiles (arrows, bolts, fireballs,
  cannonballs); Meteor/Volley effects, particles and merged floating damage numbers,
  all drawn in y-sorted order.
- `Widgets`: painted scenery backdrop, beveled buttons, layered panels, framed card
  art with elixir badges, vector crown/trophy/coin icons and the results emblem.

## Test identifiers

Both apps expose the same identifiers (iOS `accessibilityIdentifier`, Android `testTag`):
`battleButton`, `cardsButton`, `backButton`, `resetDeckButton`, `avgElixir`, `deck-<id>`,
`collection-<id>`, `quitButton`, `timer`, `playerCrowns`, `enemyCrowns`, `nextCard`,
`hand-0..3`, `elixirBar`, `arena`, `announcement`, `resultTitle`, `rematchButton`, `homeButton`.

## Clone workflow

Built with the `clone-this` workflow; run state and evidence live in
`.devin/clone-this/tower-tussle/`. Because no authorized Clash Royale source or binary
was available, the source audit records inferred requirements and the visual parity
check is explicitly blocked rather than claimed.
