# Snowglobe Express — design and native QA

## Environment

Native macOS arm64 (Darwin 25.5.0), Xcode 26.6 (17F113), Swift 6.3,
iOS 26.5 Simulator. Visual review used iPhone 17e and iPhone 17 Pro Max;
the final nine XCTest tests ran on iPhone 17 Pro. No signing or App Store upload.

## Additional design pass

The original game passed functional validation but its flat procedural artwork
needed a stronger visual identity. The redesign replaces Canvas with a native
SceneKit miniature: ceramic cottages, layered roofs, chimney details, bakery
awning, fir boughs, parcel van, brass pedestal, shadows and localized window light.
SwiftUI typography, controls, fuel gauge, delivery seals, home and postcard now
share a restrained winter-post identity. Icon and launch art use the same palette.
Game rules, route data, persistence and test definitions remain unchanged.

### Review 1 — dimensional composition

Actual 17e and Pro Max review found excess warm light washing out delivered
facades, the van hiding the bakery/checkmark, ambiguous snow-number badges,
uneven home gutters, grid corners outside the base and a disconnected glass arc.
Native PNG export already matched the live SceneKit result.

Changed: reduced light/emission/bloom; parked the van farther toward the curb;
moved delivery seals above roofs; gave snow pills a snowflake and separate shape;
constrained artwork to the padded content width; enlarged the circular base;
tightened camera framing; muted tile color/seams; varied fir boughs and snow.
Replaced the flat arc with a hemispherical glass mesh seated on the pedestal.

### Review 2 — glass correction

The second 17e review confirmed balanced gutters, contained board and readable,
distinct bakery/snow markers. The glass shader created an unacceptable milky cap.
Stopped this diagnostic recording before final validation.

Changed: premultiplied the fragment RGB by its Fresnel alpha and explicitly used
alpha blending. Flattened/inset perimeter snow and removed its cast shadows.
Home, result and postcard now omit gameplay badges; playable boards retain them.

### Review 3 — final native walkthrough

Corrected glass preserves cottage, van, window and marker contrast on both sizes.
Home gutters, controls, tutorial, results and sharing fit. The exported postcard
opens in Files with matching clear glass and warm windows. The visual direction
remains a stylized miniature, with a strong grid and faceted snow rim.

Final original recording: `snowglobe-redesign-final`, 134.29 seconds.
Native metadata contains one setup, six test starts, six consolidated passed
assertions and 90 input actions. The original edited MP4 and full-phone
screenshots are delivered through the session, not committed.
Pro Max was left foreground at the three-star result.

## Current regression evidence

| Native interaction | Result |
|---|---|
| Expanded tutorial | All three rules and Ready action visible |
| East/north preview | 1/2 fuel; no spend from initial 15 |
| Drive, bakery delivery, delivery Undo | 15→13→11→13; prior snow/van/delivery restored |
| Pause/save-home/Continue and process relaunch | 11 fuel, bakery, stars and Off preferences retained |
| Settings on both sizes | Ordinary Off/On taps and readable labels; restored On |
| Route one on both sizes | N,N,E,E,S,S; 1100 points, 3 stars, 6 moves, 8 fuel |
| Replay/reset | Initial van/snow, dark homes, 15 fuel and disabled Undo |
| System Reduce Motion | Drive/Undo 15→13→15; direct changes in sampled frames |
| Share open/reopen and Save to Files | Fresh PNG opened with correct artwork and result text |

Reduce Motion was restored Off. Motion sampling is not exhaustive animation
verification. Save to Files chose “PNG image 2”; the newly saved file was inspected.
Simulator navigation needed retries while changing the system motion setting.

## Shell checks

Run from this game's directory; all commands below passed on the final source:

```sh
xcrun swift-format lint --strict -r SnowglobeExpress SnowglobeExpressTests Tools/GenerateAssets.swift

xcodebuild -project SnowglobeExpress.xcodeproj -scheme SnowglobeExpress \
  -configuration Debug -sdk iphonesimulator \
  -derivedDataPath /Users/devin/snowglobe-review-build CODE_SIGNING_ALLOWED=NO build

xcodebuild -project SnowglobeExpress.xcodeproj -scheme SnowglobeExpress \
  -configuration Release -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /Users/devin/snowglobe-review-build CODE_SIGNING_ALLOWED=NO build

xcodebuild -project SnowglobeExpress.xcodeproj -scheme SnowglobeExpress \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=691C57A7-98F5-4C32-A5AF-3074F4F0FBA3' \
  -derivedDataPath /Users/devin/snowglobe-review-build CODE_SIGNING_ALLOWED=NO test

ruby -c Tools/generate-project.rb
plutil -lint SnowglobeExpress/Info.plist
git diff --check
```

Debug/Release builds typecheck the native code. XCTest: nine tests, zero failures,
including all six three-star solutions, priority ordering, snow/fuel boundaries,
undo, last-fuel completion, stranded failure, UTC daily stability and persistence.
Use an available simulator UUID on another VM.

Nonblocking diagnostics: asset compiler warns about absent `AccentColor`;
App Intents metadata extraction is skipped; simulator runtime logs contain
`IOSurfaceClientSetSurfaceNotify failed e00002c7`. No corresponding visible
failure or shader compilation error was observed in the final walkthrough.

## Historical coverage and limits

The original Canvas implementation received three visual review passes.
Those fixed marker overlap, delivery/Undo movement, first-share payload ownership,
and settings tap/contrast issues. Failure/retry, daily/second-route smoke and
export were exercised then; failure/retry and daily/other-route GUI coverage
were not repeated after the rendering redesign. Current replay/reset was tested.

Physical-device audio/haptic quality, external-recipient sharing, full VoiceOver
traversal and rendering-failure injection remain untested. GUI completion was
not exhaustive across routes. Daily uses the UTC date but has no dated subtitle.
The native share header uses a generic icon; the exported postcard is correct.
The work targets simulator-validated native quality, not signed store submission.
