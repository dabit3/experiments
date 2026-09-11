# Frame-rate measurement (open item `feature-60fps`)

Measured by `director stats` during the live match (`fps` field of each run's
`report.json`).

Final web + iOS parallel run, `../e2e-20260910-082636`:

| Client | FPS | Renderer |
| --- | --- | --- |
| Web (Chromium, CanvasKit) | 25 | software WebGL on the VM |
| iOS Simulator (iPhone 17, landscape) | 56 | SimMetalHost software Metal |

Final web + iOS + macOS run, `../e2e-20260910-082851`:

| Client | FPS | Renderer |
| --- | --- | --- |
| Web (Chromium, CanvasKit) | 20 | software WebGL on the VM |
| iOS Simulator (iPhone 17, landscape) | 48 | SimMetalHost software Metal |
| macOS native | 60 | Metal via the VM's paravirtual GPU |

Design-pass runs on 2026-09-10 (web / iOS, plus macOS where run):
`-072822` 25/60, `-073515` 27/58, `-074319` 21/54, `-075633` 32/60,
`-080328` 21/60/58, `-081036` 33/60, `-081755` 20/52/60, `-082111` 54/60,
`-082328` 20/46/60 (intermediate runs kept locally; only the two final runs
above are committed). Numbers move with host load (two or three clients plus
Chromium and the Simulator share the same software rasterizer). Since the pixel
HUD replaced the blurred glass overlays the iOS Simulator and native macOS
reach 60 in some runs; the web client on the software rasterizer never does,
and no run has shown 60 on every client at once.

Earlier three-platform run, `../e2e-20260909-193133`: web 21, iOS 22, macOS 38.

Host: `Apple M4 (Virtual)`, macOS 26.5.2 guest, `kern.hv_support: 0`, no
hardware GPU pass-through. The render-quality setting auto-scales the internal
resolution but the web client cannot reach 60 fps on a software rasterizer.

Status: **not demonstrated on every platform** on this host (web 20–54 across
runs; Android never ran). The 60 fps requirement stays open until the same
harness is run on a machine with a hardware GPU. It is *not* marked verified.

Iteration 7 (after the computer-use fixes): web 30 / iOS 60 in the web+iOS pair
run `e2e-20260910-092503`; web 21 / iOS 26 / macOS 59 in the three-way run
`e2e-20260910-093258` (recorded while a clean-checkout build was running on the
same host). Same conclusion: host-dependent, not demonstrated universally.
