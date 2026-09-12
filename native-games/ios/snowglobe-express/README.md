# Snowglobe Express

A native, offline iOS route puzzle made with SwiftUI and procedural Canvas artwork.
Drive a cranberry snowplow through a porcelain winter village, deliver three parcels,
and light every window inside the glass globe.

## Run

Open `SnowglobeExpress.xcodeproj`, select the shared **SnowglobeExpress** scheme,
choose an iPhone simulator and press Run. No accounts, signing team, network,
package resolution or third-party runtime dependencies are required.

Built with Xcode 26.6 (17F113), Swift 6.3, macOS arm64 and the iOS 26.5 simulator.
The deployment target is iOS 17.0. iPhone portrait is the primary layout; iPad also
supports landscape.

From this directory:

```sh
xcodebuild -project SnowglobeExpress.xcodeproj -scheme SnowglobeExpress \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build

xcodebuild -project SnowglobeExpress.xcodeproj -scheme SnowglobeExpress \
  -configuration Release -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build

xcrun simctl list devices available
# Replace DEVICE_UUID with a UUID from the list.
xcodebuild -project SnowglobeExpress.xcodeproj -scheme SnowglobeExpress \
  -configuration Debug -destination 'platform=iOS Simulator,id=DEVICE_UUID' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO test

xcrun swift-format lint --strict -r SnowglobeExpress SnowglobeExpressTests Tools/GenerateAssets.swift
```

Install a built app on a booted simulator:

```sh
xcrun simctl install booted DerivedData/Build/Products/Debug-iphonesimulator/SnowglobeExpress.app
xcrun simctl launch booted com.nader.snowglobeexpress
```

The project and assets are checked in. Optional regeneration requires Ruby's
`xcodeproj` gem 1.27.0 (`gem install --user-install xcodeproj -v 1.27.0`):

```sh
ruby Tools/generate-project.rb
xcrun swift Tools/GenerateAssets.swift "$PWD"
sips -z 128 128 SnowglobeExpress/Assets.xcassets/AppIcon.appiconset/AppIcon.png \
  --out SnowglobeExpress/Assets.xcassets/LaunchMark.imageset/LaunchMark.png
```

## Play

- Choose a direction to preview the gold destination tile and its exact fuel cost.
  The diagonal arrow matches the miniature's isometric lanes: north is up-right,
  east down-right, south down-left and west up-left.
- Press **Drive** to commit one move. Each move uses **1 + the destination's snow depth**
  fuel. Entering snow pushes all of it one square ahead and clears your destination.
- A drift holds at most three layers. Trees block movement and snow pushes.
  Snow pushed beyond the board spills off the village edge. The van cannot leave.
- Deliver to the red **1 bakery** first. Then reach homes 2 and 3 in either order.
  Visiting those early does not deliver their parcels; you must come back.
- The route ends successfully as soon as all three homes are lit, even on the last
  unit of fuel. If no affordable legal move remains, undo or retry immediately.
- **Undo** restores snow, position, parcels and fuel. There is no undo penalty.
  Pause also offers restart and save-to-home. Backgrounding pauses active play.

Six authored routes are always selectable. Stars reward fuel efficiency: three at
or below the displayed target, two within four fuel of it, otherwise one.
Efficiency points are `max(100, 1500 - 50 × fuel used)` on a completed route.
Personal best scores and stars only increase.

**Daily dispatch** is a score attack using one of the authored, solvable villages,
chosen by a deterministic UTC calendar-date seed. Everyone on that date gets the
same layout; it is a local personal best, not an online leaderboard.

The native share sheet exports a rendered 1170 × 1980 illuminated-village postcard
and result text. Settings control the synthesized delivery chime and haptics.
Motion respects Reduce Motion. Interactive controls have accessibility names and
identifiers; the game can be played through the labeled directional controls.

## State and limitations

Progress, the current route and its complete undo history are stored in
`UserDefaults`. Relaunch opens home with **Continue your route**. Data stays local
and is removed by uninstalling. No analytics, purchases, cloud sync or backend.

Simulator builds do not validate physical-device haptic feel, silent-switch
behavior or speaker quality. Signing and App Store submission are outside this
project. The procedural board has a combined VoiceOver description; the four
directional preview controls expose the legal move state and cost.

`QA-DESIGN.md` records the actual build commands, visual review changes and
simulator evidence collected for this version.
