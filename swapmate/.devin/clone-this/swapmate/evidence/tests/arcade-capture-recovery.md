# Arcade capture recovery

The redesign run `e2e-20260911T015803Z` is **failed**, not final evidence.
Four clients registered and played nine moves, but Android's three-frame wait
did not answer within 600 seconds. The final checkmate and visual comparisons
were not reached.

Inspection found two capture defects:

- Android's lobby device capture contained only the first background frame
  of the entrance animation. Lobby capture had no explicit frame readiness.
- The cached `test/tools/winid` executable was built at September 9 14:50,
  before the PID-filtering source at 15:39. It returned window 66 for both
  macOS process IDs. Recompiling the existing Swift source returned window 38
  for the player process, so the stale cache caused the spectator window to
  be captured twice.

The harness now recompiles a stale window helper and requests three frames
before every screenshot. The test channel reports lifecycle/frame scheduling
state and bounds each frame wait; it does not synthesize frames or relax
visual comparisons.

Android also suffered an ART thread-suspension timeout during its cold boot.
The verified rootable-ATD recovery in `arcade-android-boot.md` is now in the
harness. A separate headless diagnostic run is evaluating the emulator's
documented `-gpu swiftshader` mode with both timeout properties configured
before boot. This is an investigation, not yet a successful replacement run.

No old screenshot, recording, or result is relabeled as current verification.

## Phone Home interaction regression

Fresh manual testing exposed the narrow Home scroll view intercepting the
theme button and scrolling hero text across the status header. The regression
in `home_screen_test.dart` failed on the old layout (`Expected: 1, Actual: 0`
theme callbacks, with a missed-hit warning). Home now has a dedicated header
row and a scrolling viewport below it. The regression passes before and after
scrolling, and all 11 Home/layout tests plus `flutter analyze` pass. The
testing agent's fresh iOS pass also confirms both theme changes and no overlap.

The diagnostic emulator reached `system_server` with
`dalvik.vm.thread-suspend-timeout-ms=60000` and `ro.hw_timeout_multiplier=10`;
its system log shows boot services advancing. It has not yet registered an
app client. The initial `adb root` command returned a transport timeout while
restarting adbd, although the daemon subsequently reported it was root.
The harness tolerates that restart status, then verifies the property values.
