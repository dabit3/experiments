# Snowglobe Express — V1 QA and design log

## Verified environment

- Native macOS arm64 VM (Darwin 25.5.0).
- Xcode 26.6, build 17F113.
- iOS 26.5 simulator runtime, build 23F73.
- Available iPhones include 17 Pro, 17 Pro Max, 17e, Air and 17.
- Simulator signing is disabled. No physical-device validation or App Store upload.

## Design baseline

Original procedural isometric miniature: curved glass, layered powder-blue roads,
porcelain cottages, snow-capped fir trees, amber windows and a cranberry parcel van.
The gold preview tile and diagonal direction controls describe the same grid.
Fuel is explicit before every move. A first-delivery tutorial teaches priority,
snow displacement and undo. Completion renders the actual illuminated game state
as a shareable postcard.

## Verification log

Initial Debug and Release simulator builds and strict `swift-format` lint passed.
XCTest passed on iPhone 17e: 9 tests, 0 failures. This includes three-star solutions
for all six routes, full-state undo, blocked/overflow moves, priority delivery,
last-fuel success, daily UTC stability, persistence and corrupt-save fallback.

### Pass 1 — composition and identity

The tester operated the native iPhone 17 Pro simulator through home, tutorial,
preview and the first move. Home and tutorial fit. Preview cost 2 fuel without
changing state, then Drive changed fuel from 15 to 13.

Observed: house 3's floating number overlapped the bakery doorway; the plain snow
depth number looked like another home and became hidden behind the building.
The playable portion of the globe was smaller than the available layout allowed.

Changes: enlarged the village's isometric spacing and gameplay globe; reduced
building/tree scale slightly; placed numbered home plaques beside their facades,
with all plaques drawn above the geometry. Snow depths now use compact dark pills
with a drawn snowflake, rendered over the artwork. Replaced the HUD's unexplained
priority dot with numbered home markers. Added interpolated van motion and amber
orbiting sparkles for the illuminated result.

### Pass 2 — readability and controls

The tester inspected the rebuilt game on iPhone 17 Pro. The revised board and
HUD were clearer. Preview east then north cost 1 then 2 without spending fuel.
Drive and Undo restored the initial snow, van and fuel; recorded intermediate
frames confirmed van interpolation. N,N,E,E,S,S won in 6 moves using 8 fuel,
with 3 stars and 1100 points. The result and actions fit.

Observed: the snow pill still collided with the bakery's delivered checkmark.
The van covered delivered windows when parked exactly on a house. Undo snapped
instead of using the same glide as Drive.

Changes: moved home badges to the left of their facade, away from the northbound
snow bank's pill; smoothly offset the van toward the curb as it approaches any
home, leaving its windows visible; applied the Drive animation to Undo.
Snow depth changes remain immediate logical turn updates.

### Pass 3 — small-screen review and sharing correction

On iPhone 17e, the tester verified home/tutorial fit, blocked moves, previews,
delivery Undo and the 1100-point success. Home badges and snow pills were distinct,
and all lit windows remained visible. The first share presentation opened an empty
sheet. The run was stopped and its artifacts retained as diagnostic evidence only.

The presentation used separate Boolean and optional image state. Changed it to
one identifiable postcard payload passed directly into `sheet(item:)`, so the
sheet content receives the image/text responsible for presenting it. A rendering
failure now reports an error while retaining the result.

The retest verified first-share and reopen, plus Save to Files. The exported PNG
opened in Files with the illuminated village and correct score, fuel and stars.
Failure/retry, replay, save-home/Continue and actual termination/relaunch passed.
Journey, three accumulated stars and settings persisted. Cranberry lane and daily
play accepted movement; home/tutorial/gameplay/result/share fit on Pro Max.
Reduce Motion preserved correct Drive/Undo state.

Ordinary app switch taps did not visibly change state on either device, although
thumb drags did. System Settings switches accepted the same ordinary taps. The
settings controls were moved into a dedicated View owning its own `@AppStorage`
observation and bindings, rather than reading the parent properties only inside
the sheet closure. The tap failure persisted after that change; state ownership
was not sufficient to resolve it. Replaced the switch affordances with native
segmented Off/On pickers, giving each preference two explicit targets.
Ordinary Off/On taps passed on Pro Max and 17e; Off persisted through both sheet
reopening and actual process termination/relaunch. The native segmented controls
inherited the game's dark scheme, causing pale labels against the cream panel.
Cream panels now request a light color scheme for readable native controls.
Final contrast and Off/On taps passed on both 17e and Pro Max. The final native
recording repeats tutorial, previews, Drive, first-move Undo, delivery Undo, the
three-star completion and native share open/reopen, with seven passed assertions.
Recorded frames show intermediate van positions for both Drive and Undo; earlier
Reduce Motion frames show direct transitions with correct fuel. Motion inspection
is sampled at 15 fps. The app is left running at the Pro Max result.

## Shell checks

Run from this game's directory on the native VM:

```sh
xcrun swift-format lint --strict -r SnowglobeExpress SnowglobeExpressTests Tools/GenerateAssets.swift

xcodebuild -project SnowglobeExpress.xcodeproj -scheme SnowglobeExpress \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /Users/devin/snowglobe-review-build CODE_SIGNING_ALLOWED=NO build

xcodebuild -project SnowglobeExpress.xcodeproj -scheme SnowglobeExpress \
  -configuration Release -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /Users/devin/snowglobe-review-build CODE_SIGNING_ALLOWED=NO build

xcodebuild -project SnowglobeExpress.xcodeproj -scheme SnowglobeExpress \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=97EB512B-0C2B-41C5-BAA0-C9C96F1BCB9D' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO test

ruby -c Tools/generate-project.rb
plutil -lint SnowglobeExpress/Info.plist
git diff --check
```

All passed again on the final implementation (`37439682`), including Debug and
Release, strict formatting, and XCTest with 9 tests and 0 failures. Build checks
also typecheck the SwiftUI code.
Use a UUID from `xcrun simctl list devices available` on another VM.
PR checks report no configured CI jobs; these are local native verification results.

## Evidence and limitations

Final recording: `snowglobe-final-v5`, 66.54 seconds, with native setup, test-start,
passed-assertion and input-action annotations. The original edited MP4 is attached
to the session alongside full-phone gameplay/result screenshots and the tester's
consolidated report; generated evidence is not committed.

The broader v2/v4 runs verified unchanged failure/retry, replay, pause/Continue,
relaunch persistence, daily/second-route play and postcard export. Historical
failures in those diagnostic recordings were fixed and superseded by v5.

Physical-device audio/haptics, external-recipient sharing, full VoiceOver traversal
and rendering-failure injection were not tested. Every authored route has a
three-star unit-tested solution; GUI completion was not exhaustive across routes.
The share header uses a generic text icon, while its exported image is correct.
Daily play is deterministic from the UTC date, without a dated subtitle in the UI.
