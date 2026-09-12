# Emberglass — native design and QA

## Build environment

macOS Darwin 25.5.0 arm64, Xcode 26.6 (17F113), iOS 26.5 Simulator.
The checked-in Xcode project has a shared `Emberglass` scheme. No signing
credentials, accounts, external APIs or third-party packages were used.

## Automated checks

Commands run from `native-games/ios/emberglass/`:

```sh
xcrun swift-format lint --strict --recursive Sources Tests Tools
xcodebuild -project Emberglass.xcodeproj -scheme Emberglass \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Emberglass.xcodeproj -scheme Emberglass \
  -configuration Release -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Emberglass.xcodeproj -scheme Emberglass \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=C11523C9-629A-4BDA-9CC3-694B54AE9F00' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO test
```

All passed on final tested code `aacd473`. Both builds typecheck the app.
Ten XCTest cases cover bounded/time-based heating, moving target reachability,
precision falloff, shape coverage and accuracy, weighted scoring, grade
boundaries, monotone contour tangents, archive limits and permanent best/unlocks,
pause/tutorial/retry state, and complete model progression with persistence.
No tests rely on network access.

## Actual design iterations

### Pass 1 — composition and identity

Reviewed the actual native iPhone 17 home, all three stage guides, gameplay and
result. Completed a 73-point Collectible firing (86 heat / 39 balance / 87 form).
The layered glass, obsidian studio and type hierarchy worked; the vessel was
off-center, its interpolated contour had scalloped shoulders, and it floated
above the plinth.

**Changes:** explicitly centered the entire artwork in its available width;
positioned the plinth at the vessel base with a contact shadow; replaced flat
tangents at every radius sample with monotone cubic tangents; added a subtle
caustic highlight; reduced oversized tutorial numerals and added visual gauge
and gesture hints. A contour regression test covers smooth shoulders and extrema.

### Pass 2 — readability and control feedback

The refreshed iPhone 17 build visibly fixed centering, contact and scalloping.
Moving highlights remained visible without observed rendering stalls (frame
rate was not measured). Heat hold/release, held slider dragging, pause/resume,
restart and trace reset worked. Reset changed 3/8 traced and 33% form to 0/8
and 0%, without resetting the shaping timer. An Orchid firing finished as a
61-point Collectible (36 heat / 50 balance / 85 form).

The relocated artwork exposed an orange temperature/RPM readout overlapping
its bright base. All touched dots were mint despite imperfect form, obscuring
which samples needed correction. The tall Orchid form was incorrectly called
a bowl.

**Changes:** moved the readout into the dark precision header above the gauge;
reserved filled mint dots for points within 0.04 radius of target, with hollow
amber points for inaccurate touches and hollow cream for untouched points;
added matched/traced counts and a refining hint; renamed Orchid to “vessel.”

### Pass 3 — final device fit and complete route

On iPhone SE3 at 375×667 points, home, all stage guides, gameplay and results fit
without clipping. A real firing achieved 77 Exquisite (45 heat / 77 balance /
98 form) with eight matched points. Background/resume showed the pause menu;
gallery, unlocks and haptics-off preference survived terminate/relaunch.

The first share presentation was blank; dismiss/reopen recovered and Save to
Files successfully exported the image and caption. Preview showed a complete
print but revealed a remaining vessel/plinth gap in its independent layout.

**Changes:** replaced separate presentation/image states with one identifiable
share payload so the sheet receives an image and caption together; positioned
the export plinth directly at the rendered base and added its contact shadow.
The changed sharing/print behavior was retested on SE3, followed by a complete
iPhone 17 Pro Max route at 440×956 points. First Share in each process opened
populated without reopening; PNG/caption export and corrected contact passed
in native Files/Preview. Pro Max guides, live controls and results fit, and a
73 Collectible (42 heat / 65 balance / 98 form) unlocked Orchid. Reset cleared
three points and accuracy without restarting time; an untraced firing produced
23 Study with advice. Retry, pause/leave, background pause, gallery/settings
persistence and guide reset all passed. No blocking defect recurred.

The Pro Max collectible automatically revealed before the intended Cool tap,
which then returned home. Its result was recovered from the recording and its
score independently verified in gallery. The gallery is a read-only collection;
sharing is available from the current result, so fresh firings exercised Share.
SE3 comprehensive layout coverage was on `b2d3b5c`; its changed sharing/print
behavior and another compact firing were retested on `aacd473`.

Latest Debug remains installed and running on the main iPhone 17, with home
visible and existing best 73 retained. Final recordings cover the compact share
retest and the complete large-screen success/study/replay route.

## Evidence and limits

The testing agent uses native Simulator computer interaction and Devin's native
recording tools, including structured setup, test-start and assertion annotations.
Final evidence links are attached to the PR and session; videos and build output
are intentionally excluded from source control.

A SpringBoard crash-reporter dialog appeared during pass 1 and was dismissed;
Emberglass continued without a visible restart. It did not recur during pass 2.
A MobileCal crash dialog appeared during the SE3 share interaction; dismissing
it allowed export to continue.
Fresh simulator boots and installation experienced long BackBoard/Metal startup
delays. These are reported separately from app behavior.

Physical-device haptics, VoiceOver gameplay, real-device performance and signed
distribution have not been validated. The app is intentionally silent. No App
Store submission, external share delivery or online functionality is claimed.
