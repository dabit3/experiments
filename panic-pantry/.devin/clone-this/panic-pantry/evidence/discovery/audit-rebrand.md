# Audit: rebrand

Goal: no source trademark, character, level name, logo or asset anywhere in
the shipped product; every identity surface carries "Panic Pantry".

## Sweep (run against the current revision)

```sh
grep -rniI --exclude-dir=.devin --exclude-dir=build --exclude-dir=node_modules \
  --exclude-dir=.dart_tool --exclude-dir=Pods --exclude-dir=.gradle \
  --exclude-dir=ephemeral "overcooked\|ghost town\|team17" .
```

Result: zero hits in source, configs, assets and tests. The only mention of
the source title outside this run directory is `README.md` "Reference
boundary and originality", which names the reference and states that no
parity with it is claimed (a factual attribution, not branding).

## Identity surfaces

| Surface | Value | File |
| --- | --- | --- |
| Web `<title>`, description, apple-mobile-web-app-title | Panic Pantry | `app/web/index.html` |
| Web manifest name / short_name / colours | Panic Pantry, cream `#FFF8EC` background, red `#E6533C` theme | `app/web/manifest.json` |
| Web icons + favicon | generated originals (192/512, maskable) | `app/web/icons/*.png`, `app/web/favicon.png` |
| iOS `CFBundleDisplayName` / `CFBundleName` | Panic Pantry | `app/ios/Runner/Info.plist` |
| iOS app icon set | generated originals, all sizes | `app/ios/Runner/Assets.xcassets/AppIcon.appiconset` |
| macOS product name / bundle id / copyright | Panic Pantry / `dev.panicpantry.panicPantry` | `app/macos/Runner/Configs/AppInfo.xcconfig` |
| macOS icon set | generated originals | `app/macos/Runner/Assets.xcassets/AppIcon.appiconset` |
| Android label / applicationId / namespace | Panic Pantry / `dev.panicpantry.panic_pantry` | `AndroidManifest.xml`, `app/android/app/build.gradle.kts` |
| Android launcher icons | generated originals, all densities | `app/android/app/src/main/res/mipmap-*/ic_launcher.png` |
| Dart package names | `panic_pantry`, `panic_pantry_core`, `panic_pantry_server` | `pubspec.yaml` files |
| In-app copy | "Panic Pantry", original dish / chef / level names (Training Kitchen, Corner Cafe, Conveyor Canteen, Split Shift, Drift Deck) | `core/lib/src/levels.dart`, `items.dart`, screens |

Icon generator: `app/tool/make_icons.swift` (CoreGraphics; cream tile, red
stock pot, gold lid knob, steam wisps, checker accents) writes every size
above. It parses cleanly (`swiftc -parse`, `evidence/tests/quality.log`).

Visible in evidence: home screens on all four platforms show the Panic Pantry
mark and name (`evidence/clone/home-*.png`, `evidence/reference/home-web-*.png`,
`evidence/tests/ui-smoke/02-home-light.png`); the E2E log records the
native bundles launched by id (`dev.panicpantry.panicPantry` on iOS/macOS,
`dev.panicpantry.panic_pantry` on Android) in `evidence/e2e/<final>/e2e.log`.
