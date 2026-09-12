# Rippletone — V1 design and QA

## Native environment

- macOS arm64; Xcode 26.6 (17F113); iOS 26.5 Simulator.
- iPhone 17 Pro Max: 440×956 points / 1320×2868 pixels.
- iPhone SE (3rd generation): 375×667 points / 750×1334 pixels.
- Final app revision: `b349dc65da7c222bde1db25dc9c50b6f91064b8c`.
- PR: https://github.com/dabit3/experiments/pull/112

## Build and automated checks

Run from this directory:

```sh
xcrun swift-format lint --strict --recursive Rippletone Tests Tools
xcodebuild -project Rippletone.xcodeproj -scheme Rippletone \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Rippletone.xcodeproj -scheme Rippletone \
  -configuration Release -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Rippletone.xcodeproj -scheme Rippletone \
  -destination 'platform=iOS Simulator,id=691C57A7-98F5-4C32-A5AF-3074F4F0FBA3' \
  -derivedDataPath .build \
  -resultBundlePath /Users/devin/rippletone-tests.xcresult \
  CODE_SIGNING_ALLOWED=NO test
```

Both final simulator configurations and strict formatting passed. Builds also
typecheck Swift. XCTest reported **10 tests, 0 failures** for timing boundaries,
wrong-lane/duplicate input, expiration, combo, perfect phrases, scoring/coverage,
three escalating patterns, failure, Codable results and settings persistence.
The rules/state code did not change during subsequent presentation fixes.
Replace the recorded simulator UUID with an available device when reproducing.

## Three actual visual review passes

### 1. Composition and hierarchy

Reviewed the native home, three composition rows, held-target tutorial, playfield,
combo, pause and return home. The weakest details were small secondary text,
competing tutorial actions, distant judgement feedback and ambiguous progress.

Changed tutorial completion/skip hierarchy, increased secondary contrast, moved
judgements beside their lily, labelled note progress and bloom requirements,
strengthened target outlines, differentiated decorative lilies, and protected
the top HUD from moving pond artwork.

### 2. Play feel and performance presentation

Played First light using real scheduled mouse events against the Simulator:
12 Perfect, 100% accuracy and best combo 12. Reviewed celebration, results,
replay, persisted bloom progress and native image export.

The first cold-process share sheet was blank; the export rank crossed the koi,
and phrase text crossed the celebration. Replaced independent Boolean/image
share state with one complete item-backed payload, a PNG item provider and
native title/image metadata. Repositioned export art above the statistics,
added explicit Accuracy labels, protected celebration text, and made compact
results scroll to keep replay/share reachable.

### 3. Small/large screens, edge cases and final recording

Reviewed SE3 and Pro Max. SE3 verified settings across cold relaunch, automatic
background pause, resume, restart, untouched 0% / 12-missed results and replay.
The first cold-process share presentation was populated with the correct title
and card thumbnail. Save to Files produced the descriptive filename and
800×1440 artwork with separated rank/koi and the performance message.

The remaining 2–6pt tutorial target movement came from a 44pt Skip footer versus
52pt Play footer. Both now reserve 52pt; the final simulator review confirmed
stable target positions. A final native recording was captured with setup,
test-start and passed-assertion annotations plus computer-use actions.

## Evidence and limitations

The session contains the final native annotated recording, full-screen
screenshots, exported artwork and the detailed tester report:
https://app.devin.ai/sessions/43057c7b50474887a44b020493e5f15b

The video is a real Simulator interaction run, not a prerecorded game mode.
Timed mouse events provide genuine input; no saved result was injected to
produce success. Small-device edge checks also include unrecorded preflight
coverage, distinguished in the detailed report.

No physical iPhone was used. Audio/haptic feel, calls and device interruptions,
App Store signing, iPad and landscape are unverified or outside V1. Simulator
AVAudio route warnings appeared during XCTest but did not fail tests. This
visual rhythm game does not claim nonvisual VoiceOver gameplay or dynamic-type
layout scaling.
