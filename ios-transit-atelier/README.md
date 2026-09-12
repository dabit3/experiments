# Transit Atelier

A native, offline iPhone transit game. Turn a growing coastal city into a living diagram: draw lines, carry passengers to matching shapes, build interchanges and keep stations from overcrowding.

## Build and run

Requires macOS, Xcode 16 or newer (validated with Xcode 26.6), and XcodeGen 2.46.0. No signing, accounts, backend, dependencies or proprietary assets are needed for Simulator play.

```sh
cd ios-transit-atelier
brew install xcodegen # only if missing
xcodegen generate
xcodebuild -project TransitAtelier.xcodeproj -scheme TransitAtelier \
  -sdk iphonesimulator -configuration Debug \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
open TransitAtelier.xcodeproj
```

Select an iPhone Simulator in Xcode and Run. Minimum iOS 17, portrait orientation. The generated project is included; `project.yml` is its source of truth.

## Checks

```sh
swift format lint --strict --recursive Sources Tests Scripts Package.swift
swift test
```

The shared simulation is dependency-free Swift, tested on macOS through SwiftPM. Deterministic checks cover boarding/delivery, interchanges, conservation during redraw, tunnel limits, congestion, growth/upgrades, save restoration and invalid routes. Native UI must also be tested in iOS Simulator.

## Play

- Choose **Pearl Harbour** or **Saffron Estuary**, then **Begin a new journey**.
- Select a colored line. Tap station shapes in order, or drag from one station to another. The clock starts with the first connected pair.
- Trains shuttle automatically. Tiny shapes beside stations are passenger destinations; matching shapes are delivered. Connected lines allow transfers.
- Tap a new station to extend the selected line. **Undo** removes the last stop; the eraser clears the line after confirmation. A redraw safely returns passengers aboard to their last station.
- River-crossing segments consume tunnels. You begin with two lines, one six-seat train per line and three tunnels.
- Every 50 simulation seconds, choose more seats, more tunnels, or another line and locomotive (up to four).
- New stations appear every 28 seconds. At 12 waiting passengers a station's red ring begins filling. Carry passengers away before 24 seconds of overcrowding end the run.
- Deliver as many passengers as possible before the five-minute closing time. Use 1× / 2× speed, pause/resume, immediate replay, city selection and native result sharing.

## Persistence and lifecycle

Best delivered counts are saved separately for each city. Active runs save after edits, upgrades, periodically and when backgrounded. **Save & leave** returns to the title; **Continue journey** resumes paused. Backgrounding automatically pauses without advancing the simulation. Starting a new journey intentionally replaces the saved active run.

Synthesized, original two-note feedback uses the ambient audio session and respects silent mode. Sound preference persists. Haptics run where supported. Reduced Motion disables delivery rings; train movement remains essential game information.

## Scope

Two designed maps, twelve stations per map, four destination shapes, procedural passenger demand and a condensed five-minute challenge. This is an original small V1 inspired by transit-network puzzles; it is not a reproduction of the reference game's full feature or map catalog. Local bests only. Portrait iPhone layouts; no iPad-specific layout, localization, cloud sync or App Store submission is included. Audio and haptic perception should be checked on hardware.

## Artwork

All maps, symbols, trains and UI are drawn with native SwiftUI Canvas. The original icon can be regenerated on macOS:

```sh
swift Scripts/MakeIcon.swift Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```
