# Breakwater

A native iPhone harbor rescue game made with SwiftUI and a textured Canvas diorama.
Draw a route for a coral tug, gather the rope-linked fleet, and bring every boat to
the lighthouse. Four authored rescues unlock in order. Daily harbor provides an
endless series of watches with a stable UTC date seed, mirrored charts and tightening
fuel budgets. Scores and campaign progress stay on the device.

## Art direction

The coastal rescue identity pairs Baskerville lettering, a custom lighthouse seal,
brass chart instruments, ivory voyage reports and a framed rescue postcard.
Bundled original generated illustrations provide the home portrait, limestone
islands, coral tug, lighthouse and water texture. Native Canvas adds moving
surface glints, shoreline foam, current streamlines, wakes, routes and the towing
simulation. Artwork is local in `Assets.xcassets`; no image service runs in the app.
Island footprints retain the circular reef geometry used by the collision rules.

## Build and run

Requirements: macOS, Xcode 26.6 (tested), iOS 17+ deployment target. No runtime packages,
backend, account, signing identity, or network connection required.

The checked-in Xcode project and shared **Breakwater** scheme run directly:

```sh
cd native-games/ios/breakwater
xcodebuild -project Breakwater.xcodeproj -scheme Breakwater \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Breakwater.xcodeproj -scheme Breakwater \
  -configuration Release -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
xcrun simctl list devices available
# Choose an available iPhone UUID:
xcrun simctl boot <UUID>
open -a Simulator
xcrun simctl install <UUID> build/Build/Products/Debug-iphonesimulator/Breakwater.app
xcrun simctl launch <UUID> com.dabit.breakwater
```

If editing project configuration, install XcodeGen 2.46.0 (`brew install xcodegen`)
and run `xcodegen generate`. `project.yml` is the source of truth for the committed
project. Regenerate the procedural 1024px icon with
`swift Scripts/GenerateIcon.swift`.

## Checks

```sh
xcrun swift-format lint --strict --recursive Sources Tests Scripts
xcodebuild -project Breakwater.xcodeproj -scheme Breakwater \
  -configuration Debug -destination 'platform=iOS Simulator,id=<UUID>' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO test
```

The compiler type-checks all app and test code. Tests exercise corner interpolation,
hull collision boundaries, currents, scoring, all authored solutions, mirrored and
late daily watches, missing rescues, fuel failure, retry, pause, undo and persistence.

## Controls and rules

- Trace from the coral tug through each numbered beacon, then into the brass HOME
  ring. Drag continuously or tap straight waypoints; append strokes before launch.
- Starting a new stroke near the tug redraws from the beginning. Undo removes the
  latest stroke. Clear removes the route. The eye reveals a suggested course.
- Launch starts the crossing. Boat pickup is automatic within the beacon radius.
  Rope-linked boats follow the tug's actual wake; currents offset the course.
- Reefs, map edges, exhausted fuel and routes ending without the whole fleet at
  the harbor fail the watch. Every rescue is achievable with its guide course.
- Fuel is distance-based with a small tow load cost. Score combines rescued boats,
  remaining fuel and route economy. Progress records each chart's best score.
- Pause freezes the crossing. Backgrounding automatically pauses; resume explicitly.
  Retry can preserve the route for edits. Relaunch preserves settings/bests/unlocks,
  but starts at the home screen; an unfinished crossing is not saved.
- The result share button opens the native iOS share sheet with an illustrated
  postcard containing the actual route, rescued count, score and daily seed.

## Accessibility and limitations

Portrait iPhone layout respects safe areas; controls have explicit accessibility
labels and identifiers. Route input supports taps as an alternative to dragging.
Reduced Motion freezes ambient waves, boat bobbing and rotating lighthouse light.
Help and chart lists scroll. Navigation and settings are VoiceOver labeled, but
spatial route drawing is visual and is not a complete nonvisual gameplay mode.
Typography supports system text where practical; chart labels use fixed small
nautical annotations, and very large accessibility text sizes are not fully optimized.

Audio uses local synthesized chimes and honors Silent Mode. Haptics are optional.
Simulator checks cannot validate physical-device audio output or haptic feel.
Daily charts are local deterministic challenges, with no online leaderboard.
No App Store upload or signed physical-device distribution is included.
