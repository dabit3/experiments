# Frame-rate measurement (open item `feature-60fps`)

Measured by `director stats` during the live match in
`../e2e-20260909-193133/report.json` (`fps` field):

| Client | FPS | Renderer |
| --- | --- | --- |
| Web (Chromium, CanvasKit) | 21 | software WebGL on the VM |
| iOS Simulator (iPhone 17) | 22 | SimMetalHost software Metal |
| macOS native | 38 | Metal via the VM's paravirtual GPU |

Host: `Apple M4 (Virtual)`, macOS 26.5.2 guest, `kern.hv_support: 0`, no
hardware GPU pass-through. The render-quality setting auto-scales the internal
resolution but cannot reach 60 fps on a software rasterizer.

Earlier runs on the same host measured 20 / 21–23 / 31–48 fps (`../e2e-20260909-180425`,
`../e2e-20260909-182954`, `../e2e-20260909-191112`); the numbers move with host load, never near 60.

Status: **not demonstrated** on this host. The 60 fps requirement stays open
until the same harness is run on a machine with a hardware GPU. It is *not*
marked verified.
