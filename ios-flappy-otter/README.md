# Flappy Otter

A native, portrait iPhone arcade game starring **Wiskers**, the orange otter in the
user-supplied artwork. Tap to flap through a softly illustrated river, slip between
mossy rock columns, and chase your personal best. SwiftUI and Canvas; iOS 17+;
no third-party runtime dependencies, accounts, ads, or network access.

## Play

Choose **Let's fly**, then tap anywhere to begin. Every tap gives Wiskers an upward
impulse; gravity brings him down. Clearing a complete pair of rocks earns one point.
Touching a rock, the top boundary, or the water ends the flight. Speed gradually
increases and gaps narrow, with bounded difficulty and adjacent height changes.

Pause from the top-right control; leaving the foreground pauses automatically and
requires a manual resume. Restart from the results card or return home. Sound and
haptics can be toggled in **How to fly** and the pause menu; sound respects the silent
switch and mixes with other audio. Share uses the native iOS share sheet.

Personal best, completed flights, total gates, sound and haptic preferences persist
on the device. River badges unlock per flight at 5, 15, 30, and 50 gates. Active
flights are not restored after process termination.

## Build and run

Open `FlappyOtter.xcodeproj` in Xcode, choose **FlappyOtter**, select an iPhone
Simulator and Run. Physical iPhones require selecting your own Apple development
team in Signing & Capabilities. The committed project needs no generation step.

```sh
bash Scripts/validate.sh build
xcrun simctl install booted DerivedData/Build/Products/Debug-iphonesimulator/FlappyOtter.app
xcrun simctl launch booted studio.flappyotter.game
```

Project configuration lives in `project.yml`. If changing targets, regenerate with
XcodeGen 2.46.0 (`brew install xcodegen`, then `xcodegen generate`). Rebuild the app
icon with `swift Scripts/MakeIcon.swift`. The original supplied image is bundled in
the Otter image asset and used for the player, home, results, and icon.

## Automated verification

From the repository root:

```sh
bash validate-native-apps.sh all ios-flappy-otter
```

Or from this directory:

```sh
bash Scripts/validate.sh lint
bash Scripts/validate.sh test
```

The suite runs strict `swift-format` lint, Swift Package XCTest rules/persistence
tests, and app-hosted iOS XCTest through `xcodebuild test`, which also compiles and
links the full app. Defaults to the iPhone 17 Simulator; override with
`IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro'`.

Rules tests exercise first-tap start, gravity, both bounds, rounded corner
collisions, real gate collisions, pause/resume, frame-rate independence, invalid
frame deltas, seeded courses, 100-gate flights across five seeds, bounded obstacle
counts/difficulty, exactly-once scoring, restart, saved preferences and badge
thresholds. The test pilot exists only in test targets.

App tests cover the actual store's completion/persistence path, resume after a
wall-clock jump, bundled artwork/icon metadata, sound decoding, and rendering at
compact and large iPhone sizes. Xcode stores static render attachments in its
`.xcresult` test bundle. These checks do not assert pixel-perfect appearance,
physical-device audio/haptics, or real touch ergonomics. No screen recording is
needed or produced.

Controls have accessibility labels, the guide and modal cards scroll on compact
screens, and decoration is hidden from VoiceOver. Real-time spatial gameplay
requires visual tracking; no nonvisual navigation mode is included.
