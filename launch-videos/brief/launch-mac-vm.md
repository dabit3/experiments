# Test launch: Devin on Mac VMs

Every template renders this launch as its test video so the 20 directions can be
compared side by side. Use the copy below verbatim for the test render (it is the
default value of the template's `content` prop). Do not add claims that are not in
this document.

## Canonical script (default `content` prop)

- `featureName`: **Devin on Mac**
- `eyebrow`: New
- `headline`: Devin now runs in a Mac VM
- `subhead`: Build, run, and test Mac and iOS apps in a cloud Mac — with a live iPhone Simulator in your session.
- `cta.label`: Start a Mac session
- `cta.url`: app.devin.ai
- `outro.line`: The only coding agent with a cloud Mac.
- `speedBadge`: 3x (use only when footage is sped up)

Captions (in order; a template may use 4-6 of these, keep the order):

1. Pick macOS when you start a session — same price as Linux.
2. Devin builds the app in Xcode and runs the full test suite.
3. It taps, types, and scrolls through the app like a person.
4. Watch it live in the iPhone Simulator tab — and tap in yourself.
5. Reproduce a bug, fix it, and prove the fix on screen.
6. Check iPhone and iPad sizes, dark mode, and orientations.
7. Ship with a PR that shows the app working — not a 20-minute CI wait.

Use-case labels (for stations, tracks, exhibits, panels, chapters):

- Build & test a feature
- Reproduce & fix a bug
- QA before shipping
- Screens, sizes & dark mode
- Upgrade Swift & dependencies

Stage labels (for workflow diagrams): Request → Build → Run & test → Verify → PR

## Source facts (approved claims)

- Devin can now run in a Mac VM and write + test code for Mac and iOS apps.
- Before: iOS teams manually QA'd or waited 20+ minutes for CI. Now Devin builds, runs,
  and taps through the app and shows it in a live iPhone screen inside the session.
- Differentiation: the only coding agent with a cloud Mac agent. Competitors are
  Linux-only or run Mac/iOS locally. Same security model as Linux/Windows VMs.
- Cost: no price increase; same as cloud Linux VM sessions.
- vs Mac Outposts: Outposts = bring-your-own Mac hardware. Mac VMs are provided and
  secured by Devin, plus live iPhone Simulator tab, macOS child sessions, Declarative
  Repo Setup, and Devin API/automations.
- Supported: Xcode build + unit/UI tests; tap/type/scroll; React Native / Flutter /
  Expo; deep links; local push notifications; location; Apple Maps; permission dialogs;
  localization/RTL; screenshots/video/snapshot tests; any iPhone/iPad size.
- Do NOT show or claim: real devices, TestFlight/App Store, camera/AR, Bluetooth, NFC,
  Sign in with Apple, VoiceOver, multi-touch in the live tab.

## Footage mapping (which asset shows which caption)

| Beat                          | Asset                                                        |
|-------------------------------|--------------------------------------------------------------|
| Pick macOS                    | `screenshots/devin-web-1.png` (macOS pill under prompt), `devin-web-4.png` / `devin-web-5.png` (OS dropdown: Ubuntu / macOS / Windows), `recordings/agent-selector-cloud.mp4` |
| Devin working / Xcode build   | `recordings/devin-working-4.mp4`, `screenshots/devin-web-9.png`, `devin-web-11.png` (iOS PR with Simulator screenshots) |
| Taps through the app / live Simulator | `recordings/androidios.mp4` (iPhone Simulator on a Mac desktop; the Android window on the right may be cropped out), `screenshots/devin-web-10.png`, `devin-web-11.png`, `devin-web-13.png`, `devin-web-14.png`, `devin-web-18.png`, `devin-web-19.png` (test recordings with iPhone Simulator + pass list) |
| Verify / test results         | `recordings/devin-testing-2.mp4` (recording player with "6 passed / 0 failed" and It-should list), `recordings/pdf.mp4` |
| PR / outcome                  | `screenshots/devin-web-8.png` (merged PR diff), `devin-web-12.png` (Merged PR with iOS demo video), `devin-web-15.png` (PR ready to merge) |
| Desktop / CLI (optional)      | `screenshots/devin-desktop-*.png`, `devin-cli-*.png`                    |

The footage is real product UI. It is allowed to crop, hold, speed up (with a badge),
and mask it. It is not allowed to redraw, recolor, skew, or fabricate UI states.
