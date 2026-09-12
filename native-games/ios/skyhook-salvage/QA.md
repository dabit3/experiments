# Skyhook Salvage — native QA and design report

**Verdict:** V1 implementation and focused final native UI retest passed.
No unresolved defect was observed in the tested scope.

- Tested source: `a11a78d40df7433d59c7bd2beab73f1437385c34`.
- Branch: `devin/1789187581-ios-skyhook-salvage`.
- PR: https://github.com/dabit3/experiments/pull/106
- Platform: macOS Darwin 25.5.0 arm64, Xcode 26.6 (17F113), iOS 26.5.
- Devices: iPhone 17 Pro Max and iPhone SE (3rd generation), native Simulator.
- Native SwiftUI/Canvas application; no web runtime, backend or external account.
- Final app left installed and running at home on Max; SE shut down.

## Three design passes and corrective retests

| Pass | Observed issue | Change and verification |
|---|---|---|
| 1 — Composition and identity | Home's cream/blue/brass illustration worked; onboarding was text-heavy and initial CTA displayed “Got it.” | Added illustrated catch/hoist/land strip and item-bound tutorial request. First-start “Let's salvage” verified on Max and SE. |
| 2 — Gameplay readability and feel | Landing projection, balance bubble and rewards were subordinate; result engine clipped. | Stronger bracket/guide, stage captions, enlarged balance gauge, score burst and lower suspension on tall screens. Aspect-ratio manifest preserves the complete engine. Real four-cargo win and failure/retry verified. |
| 3 — Fit, edges and sharing | First diagram retest clipped labels. Compact final-piano release obscured status text. | Fixed diagram aspect ratio; fit scene height to contract size; moved live guidance into the fixed control area. Final retest shows both safe/unsafe guidance fully readable with 5/6 aboard. Six-cargo tower, crane and reward remain separate. |

These were rendered Simulator reviews with real controls, followed by rebuilds
and retests. No screenshots were substituted for playable flows.

## Native runtime coverage

**Comprehensive revision `1fd43a6`:**
- Fresh onboarding, compact home, scrollable tutorial/results and usable controls.
- Max four-cargo win including grand piano: 962 points, 11 tonnes.
- SE all three contracts: 998, 1,411 and 1,517 points; final route six cargo/18t.
- Native share sheet exported actual PNGs; opened four- and six-cargo images in Files and inspected full composition.
- Three-miss failure and immediate retry reset score, cargo, lifts and timer.
- Best score, cleared routes, unlocks and audio/haptic settings survived process relaunch.
- Explicit pause/resume, background auto-pause and practice without time/miss limits.

**Focused final source `a11a78d`:**
- SE and Max pickup/release guidance states remained complete and unobscured.
- SE final suspended piano at 5/6 aboard; valid and invalid placement tested.
- Contract 03 won with 1,682 points, six treasures and 18 tonnes.
- Complete result tower/engine, native share sheet with correct score, and retry to 0 points, 0/6 cargo, three lifts and 110 seconds.
- Unchanged persistence/settings/practice/onboarding flows were not all repeated.

All recordings used Devin's native recording tools with structured setup,
test_start and passed/failed/untested assertions. The completion attachment uses
the original edited MP4 path to retain the native action timeline.

## Automated checks

Run from `native-games/ios/skyhook-salvage`. All commands passed on final source.

```sh
swift format lint --strict --recursive Sources Tests scripts
xcodebuild -project SkyhookSalvage.xcodeproj -scheme SkyhookSalvage \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/Debug CODE_SIGNING_ALLOWED=NO build
xcodebuild -project SkyhookSalvage.xcodeproj -scheme SkyhookSalvage \
  -configuration Release -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/Release CODE_SIGNING_ALLOWED=NO build
xcodebuild -project SkyhookSalvage.xcodeproj -scheme SkyhookSalvage \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=63A5C180-1545-42B3-B661-99891A05D99F' \
  -parallel-testing-enabled NO -derivedDataPath build/Tests \
  CODE_SIGNING_ALLOWED=NO test
```

**11 XCTest tests, zero failures.** Coverage includes catch/support boundaries,
weighted balance and counterweights, precision scoring, contract completion and
persistence, misses/retry, pause/timeout, practice, bounded trim, repeated input
and agreement between projected and actual landing drift. Builds also typecheck.
Discover a current Simulator UUID rather than reusing this session's UUID.

## Evidence downloads

- [Final compact gameplay/result/share/retry recording](https://app.devin.ai/attachments/d5f109e6-a76a-4a4d-a704-b6ea229e744d/skyhook-a11a78d-se-edited.mp4)
- [Final Max guidance regression recording](https://app.devin.ai/attachments/bc5dde7f-2bfe-4df4-b7d0-3dd6796f84e5/skyhook-a11a78d-max-edited.mp4)
- [Comprehensive Max core-flow recording, preceding source](https://app.devin.ai/attachments/7a983521-0421-419b-a269-e07047f7bc85/skyhook-final-max-edited.mp4)
- [Final piano gameplay](https://app.devin.ai/attachments/c5db4fb5-2a8a-468d-9b3f-d4b609cd384a/skyhook-a11a78d-se-valid-release.png)
- [Six-cargo result](https://app.devin.ai/attachments/0a447145-bc08-45f2-b55b-0fffebeb3fec/skyhook-a11a78d-se-result.png)
- [Home](https://app.devin.ai/attachments/35e489d8-b3f2-46df-beee-89fb0a93f28f/skyhook-a11a78d-max-home.png)

## Limits

Physical-device sound/haptic feel, external recipient delivery, accessibility
text-size variants and dedicated UI timeout/tipping outcomes were not tested.
Timeout and weighted-balance rules passed automated tests. Reduced-motion behavior
is implemented but was not separately visually exercised. No signing or App Store
upload was attempted. Active runs pause in background but are not restored after
process termination; local best/progress persists. The timing game is visually
driven and does not claim equivalent nonvisual play.

Initial concurrent Simulator boots caused resource contention; sequential device
boot/testing resolved it. Future testing should keep one Simulator booted at a time.
