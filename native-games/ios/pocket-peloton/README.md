# Pocket Peloton

A native, offline iPhone cycling sprint. SwiftUI + Canvas, original procedural coastal illustrations, four riders and three short roads. No packages, services, accounts, or signing credentials are needed for simulator builds.

## Open and run

Open `PocketPeloton.xcodeproj` in Xcode. Select the shared **PocketPeloton** scheme, choose an iPhone simulator and run. Requires Xcode 16 or newer with the iOS 17+ SDK; validated here with Xcode 26.6 and iOS 26.5. Portrait iPhone is the intended platform.

From this directory:

```sh
xcodebuild -project PocketPeloton.xcodeproj -scheme PocketPeloton \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build

xcodebuild -project PocketPeloton.xcodeproj -scheme PocketPeloton \
  -configuration Release -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build

xcrun simctl list devices available
# Substitute an available iPhone UUID, boot it if necessary, then:
xcrun simctl install booted DerivedData/Build/Products/Debug-iphonesimulator/PocketPeloton.app
xcrun simctl launch booted com.pocketsports.peloton
```

## Race craft

- Swipe horizontally on the road, or use the large left/right buttons, to change between three positions.
- Hold **SPRINT** to attack. Release to recover. The tutorial and settings include **tap-to-toggle sprint** for mouse and one-tap use.
- Follow within 4–42 meters of a rider in your lane without sprinting to draft. The pale trail is their slipstream. Drafting restores energy twice as fast.
- After 1.8 seconds in the draft, switch lanes for a 2.6-second slingshot.
- The inside lane of a bend is slightly faster. Striped road blocks cause a short slowdown and cost energy.
- Exhausting your energy prevents sprinting until it recovers to 28%.
- Rivals have fixed, disclosed-in-code paces and avoid road blocks early. They do not rubber-band or teleport. Positions use actual traveled distance; results interpolate exact line-crossing times. The fastest rival's remaining time is exact because its pace is constant.
- Race lengths are 620, 780 and 900 meters. Rivals get progressively faster. All routes are available immediately; the race book keeps your last 100 finishes and fastest time per course.
- Pause supports resume, immediate restart and leaving. Backgrounding pauses automatically and releases sprint. Relaunch returns to the clubhouse; an unfinished attempt is not recorded.
- Results provide replay, a native share sheet with a 1200×1640 editorial poster and return to the clubhouse.

## Checks

```sh
xcrun swift-format lint --strict --recursive PocketPeloton PocketPelotonTests Tools

# Use a UUID from `xcrun simctl list devices available`:
xcodebuild -project PocketPeloton.xcodeproj -scheme PocketPeloton \
  -configuration Debug -destination 'platform=iOS Simulator,id=YOUR_IPHONE_UUID' \
  -parallel-testing-enabled NO \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO test
```

The XCTest suite covers drafting boundaries and recovery, sprint exhaustion/recovery, valid slingshots, obstacle lane/collision behavior, frame-rate tolerance, actual finish gaps, achievable wins on all courses, state freezing after finish, interrupted-frame limits, pause and persistence. The simulator build typechecks all Swift source. There is no separate third-party linter. On resource-constrained VMs, finish XCTest before interactive testing and boot only one simulator at a time.

## Artwork

The coastal road, sailboats, palms, villas and riders are drawn natively in `CoastArtwork.swift`. The app icon and launch monogram are generated assets with a checked-in native generator:

```sh
xcrun swift Tools/GenerateArtwork.swift PocketPeloton/Assets.xcassets
```

## Accessibility and limitations

Interactive controls have accessibility names/identifiers. Tap-to-toggle sprint avoids prolonged pressing; buttons provide an alternative to swipe steering. Reduce Motion suppresses pedaling and speed particles. Tutorial, settings and results can scroll on smaller displays.

This is a visual reflex game: live spatial obstacles are not fully playable with VoiceOver alone. Haptics and sound effects have independent settings, but physical-device audio, vibration, performance, signing and App Store submission are not validated by simulator evidence. No daily/online ranking, multiplayer, purchases or cloud sync are implied. See the accompanying QA/design report for the specific simulator runs and visual revisions.
