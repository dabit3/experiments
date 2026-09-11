# Arcade verification checkpoint

Production source: `af9795d`
Fingerprint: `sha256:3b6df07fc2b5f62efab566427037ee8c37e88f116eb167e2e9710e86e1bfdc6d`

The cinematic arcade redesign, compact phone keyboard fixes and corrected
camera-relative joystick have completed their locally actionable verification.
The full clone-this run remains **blocked**, not complete.

## Current evidence

| Check | Result | Evidence |
|---|---|---|
| Web + iOS live shared match | 15/15 passed | `evidence/tests/e2e-arcade-pair-af9795d-isolated/report.json` |
| Web + iOS + native macOS | 17/17 passed | `evidence/tests/e2e-arcade-trio-af9795d-isolated/report.json` |
| Real UI Chrome + iPhone 17 | Passed tested workflows; see report exclusions | `evidence/tests/arcade-manual-af9795d/REPORT.md` |
| Clean checkout | Core/server/app checks and all four builds pass | `evidence/tests/checks/arcade-joystick-clean-build.txt` |
| Core acceptance probe | Sleep, chests, kilns, persistence, vitals, creative and results | `evidence/tests/checks/arcade-core-probe-final.txt` |
| Security review | Scoped source review and zero npm audit findings | `evidence/tests/checks/arcade-joystick-security.md` |
| Discovery | Two current full sweeps; zero new inventory items | `evidence/discovery/sweep-007.json`, `evidence/discovery/sweep-008.json` |

The real UI review is 123.83 seconds with title, 11 chapters, captions, platform
labels, timeline and result summary. It was fully decoded and sampled at each
chapter, not watched end-to-end. Its source/edited timing and markers are retained.
The separate scripted match review is `evidence/tests/e2e-arcade-pair-af9795d-isolated/review-video.mp4`; the real UI
review is `evidence/tests/arcade-manual-af9795d/review-video.mp4`. PNG/video evidence is attached rather
than stored as large Git objects.
The automated review is 61.83 seconds at 1920x1080; full decode and sampled
chapter/contact-sheet inspection passed.

The first final harness attempt on reused port 8787 failed with
`no such player Web` after room creation. A normal Chrome client remained open
on port 8790 and could reconnect to that server. Client interference is the
suspected cause, not proven from that log. Both accepted final runs use the
existing `VH_PORT=8788` isolation option with fresh saves. The failed run remains
historical in `evidence/tests/e2e-arcade-pair-af9795d/`; it is not counted as a pass.
No source or test assertion was changed to obtain the passing runs.

## Coverage and boundaries

Automated clients place and break the shared structure, send chat, reconnect and
reach results with identical client/server world and chat fingerprints and
identical scoreboards. The real UI pass separately checks visible shared edits,
phone four-way joystick/release, keyboard focus/drafts, crafting, options,
reload retention, results and return to lobby.

Native macOS lobby/results match the Web structural baseline at 1280x800 after
the documented normalization. Raw raster differences remain recorded. iOS is a
separate 874x402 logical phone layout; no desktop-to-phone pixel identity is claimed.
Home captures retain platform/name/status differences and are recorded only;
the zero-difference claims apply specifically to the lobby/results fixtures.
Accessibility evidence covers the implemented semantics and tested input paths;
it is not an exhaustive assistive-technology certification.

Android's APK builds, but no live Android match or screenshot exists because the
emulator cannot boot (`kern.hv_support=0`, `HV_UNSUPPORTED`; documented safe
alternatives failed). Pair FPS: `{'Web': 20, 'iOS': 50}`. Trio FPS:
`{'Web': 20, 'iOS': 31, 'Mac': 48}`. Universal 60 FPS is unverified; resume on a hardware GPU
and virtualization-capable host. Physical-device performance, isolated Jump,
audible sound, exhaustive keyboard/viewport matrices and an independent
server-process restart are not covered by the final manual pass. JSON save/load
and normal reload/reconnect are covered separately.

The commercial original was never run or purchased. Public documentation is the
reference; branding, art, creatures and audio are original Voxelhearth work.
Visual claims are normalized comparisons among Voxelhearth clients, never
literal pixel parity with the commercial source. The documented shader renderer,
64-block world height and optional scored-match model remain intentional differences.

## Start and repeat

From the repository root:

```sh
(cd voxelhearth/server && dart run bin/server.dart --port 8787 --save-dir saves --web-root ../app/build/web)
(cd voxelhearth/app && flutter run -d chrome)
(cd voxelhearth/app && flutter run -d "iPhone 17")
(cd voxelhearth/app && flutter run -d emulator-5554)
(cd voxelhearth/app && flutter run -d macos)
```

Android needs a booted emulator on a supported host. iOS needs a booted Simulator.
Run clients in separate terminals against the same server.

```sh
cd voxelhearth
VH_PORT=8788 VH_PLATFORMS=web,ios ./test/multiplayer-e2e.sh
VH_PORT=8788 VH_PLATFORMS=web,ios,macos ./test/multiplayer-e2e.sh
# On a virtualization-capable host:
VH_PORT=8788 VH_PLATFORMS=web,ios,android,macos ./test/multiplayer-e2e.sh
```

`README.md` and `PROTOCOL.md` contain full setup, controls, architecture and
protocol details. The durable evidence root is `.devin/clone-this/voxelhearth/`.
The final `verify_state.py` result is saved as
`evidence/tests/checks/arcade-final-verify-state.txt`.
