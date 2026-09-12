# Pocket Peloton — design and QA

## Native environment

- macOS Darwin 25.5.0, arm64 VM.
- Xcode 26.6 (17F113), Swift 6.3.3, iOS 26.5 runtime.
- Native SwiftUI/Canvas iPhone application, offline and dependency-free.
- PR: https://github.com/dabit3/experiments/pull/109
- Original V1 application revision tested: `3fc9afae13a6ccc8c60388f2990f7691bacf9116`.
- Latest redesigned application revision tested: `ddb8cf6aea3bd59680d9e6474e8fc65e8b289715`. The subsequent documentation commit changes only this report and README.

## Automated verification

Commands run from `native-games/ios/pocket-peloton`:

```sh
xcrun swift-format lint --strict --recursive PocketPeloton PocketPelotonTests Tools

xcodebuild -project PocketPeloton.xcodeproj -scheme PocketPeloton \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /Users/devin/pocket-peloton-evidence/DerivedData \
  CODE_SIGNING_ALLOWED=NO build

xcodebuild -project PocketPeloton.xcodeproj -scheme PocketPeloton \
  -configuration Release -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /Users/devin/pocket-peloton-evidence/DerivedData \
  CODE_SIGNING_ALLOWED=NO build

xcodebuild -project PocketPeloton.xcodeproj -scheme PocketPeloton \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=97EB512B-0C2B-41C5-BAA0-C9C96F1BCB9D' \
  -parallel-testing-enabled NO \
  -derivedDataPath /Users/devin/pocket-peloton-evidence/DerivedData \
  -resultBundlePath /Users/devin/pocket-peloton-evidence/RulesTests-serial.xcresult \
  CODE_SIGNING_ALLOWED=NO test
```

Strict formatting and both final simulator build configurations passed; builds typecheck all application code. Ten XCTest tests passed with zero failures on iPhone 17e. The tests ran at `11979e0`; the subsequent application changes affect Canvas presentation and native share metadata, with no changes to race rules or persistence.

The tests verify drafting lane/distance boundaries, recovery, sprint exhaustion, charged lane-change attacks, obstacle penalties, frame-rate tolerance and exact finish gaps, achievable wins across all three courses, immutable finished results, invalid/large frame handling, pause and local persistence.

The initial parallel test run was stopped because concurrent cold simulator boots saturated the VM. The serial retry passed. Simulator logs contain audio queue/device warnings; these do not establish physical audio behavior.

## Pass 1 — composition and identity

Actual rendered iPhone 17e home, tutorial, race, result and poster screenshots were inspected. A complete Riviera Run and winning result were observed. The celadon/cream coastline, vermilion player, navy editorial type and butter-yellow markings established a consistent magazine aesthetic.

Observed weaknesses and changes:

- Rotated home lettering wrapped into vertical fragments. Added fixed sizing before rotation.
- Riders approached the control panel too closely. Raised the player camera anchor and added lane interpolation.
- Tap mode still said “hold”; exhaustion still said “sprinting.” Corrected both contextual labels.
- The first share request opened a blank sheet. Replaced Boolean presentation state with a populated, identifiable image/text payload.

## Pass 2 — gameplay readability and controls

Native computer-use testing at `11979e0` verified charged drafting and visible slingshots (results recorded one and two attacks), arrow/swipe steering, hold/release sprint, tap sprint, exhaustion/recovery, obstacle collision, restart, pause/resume, background auto-pause, replay, non-winning results and first-tap native sharing. Results included fourth place at 45.52s (+0.69s) and second at 44.89s (+0.06s). Native Print preview showed the actual poster without sending it externally.

The first-pass fixes were verified. Close same-lane riders still overlapped, including the YOU label, and native sharing used a generic document thumbnail. Reduced rider scale to 78%, separated nearby rivals laterally, added a cream player halo and backed YOU label, and supplied native LinkPresentation image metadata. These changes were rebuilt in Debug and Release for the third pass.

## Pass 3 — final device fit and evidence

Final native computer-use testing used iPhone 17e (1170×2532) and, after shutting it down, iPhone 17 Pro Max (1320×2868). Both ran the rebuilt Debug app on iOS 26.5.

| Check | Observed outcome |
| --- | --- |
| Home, tutorial, gameplay and result fit | Passed on both sizes, including notch/Dynamic Island safe areas |
| Close drafting pack | Smaller riders, player halo and backed YOU label materially improve identification |
| Riviera Run | First place, 41.26s, 3.56s margin, one attack, zero blocks |
| Headland Club | First place, 52.14s, 3.41s margin, one attack, two blocks |
| Golden Hour | First place, 61.55s, 1.60s margin, one attack, two blocks |
| First native share | Immediately shows actions and actual poster thumbnail on both devices |
| Poster content | Full image verified through native Print preview; no external delivery attempted |
| Restart and replay | Fresh time/progress and 100% energy |
| Relaunch persistence | Finishes, wins, per-course bests and settings survived; abandoned replays did not overwrite results |
| Reduce Motion | Steering, charged attack and sprint work without speed streaks; setting restored afterward |
| Largest accessibility text | Tested controls remain reachable, but custom type stays fixed and native race-book values wrap |

The application remains installed and running on iPhone 17 Pro Max with normal text size and motion restored. The final pass verified the two presentation refinements; no further application edits followed it.

Final evidence consists of two original edited native recordings with setup, test-start and assertion annotations, full-screen simulator gameplay/home/result screenshots, and the testing agent's separate QA report. The original screencasts paths are attached directly so their action timelines remain associated with the video. Evidence is delivered as attachments rather than committed build/video assets.

Native Save to Files did not open a picker on iPhone 17e, so file export is unverified. The first share sheet, poster thumbnail and actual image rendering passed. Largest-text results/share, VoiceOver, external share delivery and running the Release configuration are untested. The earlier second-pass regression scenarios were not all repeated after the final presentation-only changes.

## Additional design pass — authored coastal club identity

The user accepted the original testing but requested a more polished, distinctive presentation. Race rules, persistence and controls were preserved. Three additional visual reviews used actual Simulator screenshots and native annotated recordings.

### Review 4 — composition and interface (`6ffe89d`)

Replaced the flat procedural home with an original illustrated Mediterranean diorama; refined the wordmark, club emblem and three-color signature; rebuilt route selection as an editorial ticket with route traces; introduced a dark bike-computer HUD, segmented power reserve and tactile sprint/steering controls. Tutorial/pause gained rounded paper surfaces, and results/sharing gained a matching medal poster.

On iPhone17e, routes, tutorial, gameplay, a first-place finish (40.86s), first-share/full poster and replay/pause passed without clipping. The tester identified a mismatch: the live race remained much flatter than the cover, and secondary labels were small. The Max review was intentionally stopped before scenarios to refine those observations.

### Review 5 — illustrated live gameplay (`d24ddc5`)

Added original textured rider, pine, villa, boat and rock sprites, generated from matching atlases and imported with a native Swift chroma-key tool. Added native silhouette shadows, a thin player ring, larger riders, stronger road perspective, 100m-to-go asphalt stencils and larger secondary labels.

Sequential iPhone17e and17ProMax testing verified close-pack identification, tap and hold/release sprint, charged attacks, replay/pause, device fit, two Riviera wins (41.64s and42.75s), first sharing and the complete poster in native Print preview. Reduce Motion preserved steering/attacks and removed speed streaks; the tiny rider-sway difference was visually inconclusive.

Personal screenshot review found two rendering details missed in the tester's first assessment: a later rival's slipstream washed out a rider already drawn, and a button's shadow duplicated its text inside the capsule. Repeated shoreline spacing also felt mechanical.

### Review 6 — final rendering (`ddb8cf6`)

Rendered all slipstreams before all rider sprites, composited button content before its shadow, softened trails and varied coastline contours, rock placement, tree positions and scale.

Final Max native testing verified opaque rider detail over draft cones, clean held/released sprint lettering, varied shoreline rhythm, a real Riviera win (44.33s,0.49s margin,17.6s draft,1 attack,1 block), first-share entry and replay/pause/home. The latest app remains running at Max home. Final home/gameplay/result screenshots were inspected directly.

### Checks and evidence for the redesign

- Strict `swift-format` passed after each application refinement, including `Tools/ImportSprites.swift`.
- Debug and Release simulator builds passed at `6ffe89d`, `d24ddc5` and `ddb8cf6`, using the commands above.
- All10 XCTest tests passed serially with zero failures at `6ffe89d`. Later refinements affect only presentation, geometry used for drawing, asset import and bundled art; simulation and persistence were unchanged.
- Atlas import commands in README were executed successfully for all8 sprites.
- Primary evidence is the original edited `peloton-final-rendering-max` native recording with setup/test-start/assertion annotations and full final home/gameplay/result screenshots. The prior illustrated17e/Max recordings and the combined testing-agent QA report provide supplemental coverage. Videos/build products are not committed.
- The final rendering-only revision did not repeat17e, tap mode, full poster expansion or Reduce Motion. The full original persistence/other-course/accessibility matrix was not rerun during the bounded redesign.

### Remaining visual and validation limits

Road blockers and slipstream trails remain deliberately simple for recognition. The upper road can be spacious when leading, and trailing rivals can pass under the bottom controls. Secondary typography remains compact, with the existing limited Dynamic Type support. Frame pacing has not been quantitatively benchmarked.

## Limits

Simulator results do not validate physical audio/haptics, device performance, signing or App Store submission. This visual reflex game is not fully playable through VoiceOver alone. Frame pacing is visually reviewed rather than quantitatively benchmarked. Unfinished races are intentionally discarded on relaunch; completed results and preferences persist locally.

No shared environment blueprint was modified because this task owns only the assigned game directory. Simulator setup and serialized test guidance are documented in README; a separate optional skill suggestion captures verified setup without changing sibling apps or root configuration. No third-party tools or dependencies were installed.
