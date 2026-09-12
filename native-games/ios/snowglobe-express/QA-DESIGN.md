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

## Sans-serif product design pass

This section supersedes the earlier interface observations above. The product is
a short-session route puzzle: Home helps select or resume a delivery, gameplay
supports comparing moves with the fuel budget, and results support improvement,
progression and sharing. The SceneKit village, winter teal, cranberry van and
amber windows remain the visual identity.

The five highest-impact interface changes:

1. Replaced editorial serif headings and scattered sizes with `DispatchType`,
   a small SF sans-serif scale. Rounded SF titles/numbers and standard SF labels
   distinguish roles without tiny tracked capitals.
2. Replaced promotional Home composition with the actual saved or next village,
   its delivery status, a direct action and simple route/daily rows.
3. Replaced the gradient/star-field background and gradient capsule actions with
   solid winter teal and flat cranberry buttons; amber retains fuel/star meaning.
4. Removed ornamental grouping in gameplay. Fuel, deliveries, move cost and Drive
   now follow the planning sequence; open groups and separators replace nesting.
5. Made results/settings denser and actionable. Shared spacing and surface tokens,
   Dynamic Type stacking and wide side-by-side layouts support native phones/iPad.

### Observed corrections

- iPhone 17e at AX1 initially allowed scrolled Home content behind the status bar.
  Moved the full-bleed background outside the clipped content layer. Rechecked
  scrolled Home and the route sheet: clock, icons and notch remain clear.
- Empty Daily history now says “Not played” and shows the UTC date.
- A completed save initially retained unfinished-route copy. Home now distinguishes
  active, completed and stranded journeys with “Resume route,” “View result,” and
  “Undo or retry,” preserving the existing saved-journey routing.
- The corrected build passed actual completed/stranded relaunch, result/failure
  restoration and retry on iPad. Landscape Home, gameplay and results fit; the long
  route title and settings persistence also passed.

### Current shell validation

Strict formatting and Debug/Release simulator builds passed after the final UI
copy correction, source revision `869ed33b351d37e54e2ba258d468bdcefc79f9f1`:

```sh
xcrun swift-format lint --strict -r SnowglobeExpress SnowglobeExpressTests Tools/GenerateAssets.swift
git diff --check
xcodebuild -project SnowglobeExpress.xcodeproj -scheme SnowglobeExpress \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /Users/devin/snowglobe-review-build CODE_SIGNING_ALLOWED=NO build
xcodebuild -project SnowglobeExpress.xcodeproj -scheme SnowglobeExpress \
  -configuration Release -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /Users/devin/snowglobe-review-build CODE_SIGNING_ALLOWED=NO build
```

Nine XCTest tests passed during this sans-serif pass using the test command above.
The subsequent safe-area and Home-copy corrections did not change the engine or
tests; those corrections were rebuilt and reviewed through the native interface.
No dependencies, game rules or persistence models changed.

### Final native review

The corrected source passed fresh iPad Pro 11-inch landscape and iPhone 17 Pro Max
interaction review. This covered empty progress, long titles, tutorial, completion,
blocked Drive, exhaustion/retry, delivery Undo, replay/next, saved completed/stranded
states, Daily persistence, settings, sampled Reduce Motion and native share/export.
The new PNG opened in Files with the lit village and sans-serif result statistics.
Pro Max AX1 controls/rows fit after scrolling; Dynamic Type and motion settings were
restored. Earlier 17e AX1 safe-area proof is retained from `e256dc2`, rather than
claimed as a fresh run of the final Home-copy correction.

The original `snowglobe-sans-final-v3-edited.mp4` is 154.83 seconds with native
annotation metadata: one setup, eight test starts, eleven passed consolidated
assertions and 118 input actions. The original screencasts file is delivered
directly so its action timeline stays associated with the video.
[Detailed native report](https://app.devin.ai/attachments/a2a9c0bc-75a5-4efa-a768-858e1e430e1a/report-869ed33.md).
Pro Max remains running at Cranberry lane.

The interface depends on the actual snow grid, fuel budget, delivery sequence and
illuminated village; swapping a logo would not make it an unrelated product screen.
The strong grid and faceted snow rim remain a stylistic limitation, with no marker
occlusion or glass washout observed in this review.

Still unverified: physical audio/haptics, external-recipient sharing, full VoiceOver
traversal, render-failure injection, exhaustive GUI route coverage (including route
six), frame-level animation analysis and postcard scaling across Dynamic Type sizes.
Concurrent Simulator setup stalled earlier; sequential device use recovered.
System Settings loading required tap retries but the final motion check passed.
