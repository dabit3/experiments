# Native iPad keyboard regression and three-device rerun

PR: https://github.com/dabit3/experiments/pull/229

Tested source: `8400c43627b0737b55ba09a45837154b3f8c0337`

Fingerprint: `sha256:7ec652fe574f161e14dc3f9e1d45202ea07663a05e02ce70b8f8ffdae4532c2c`

## Failure and correction

The first recorded Web+iPhone+iPad run on `414c03f` reached a shared lobby,
then stopped when the native iPad software keyboard hid the composer and
controls with a 23px RenderFlex overflow. It did not complete gameplay.
Evidence is retained in `../three-device-414c03f-20260915/`.

A widget regression reproduced the same overflow using a 1210×834 surface,
safe-area padding, and a 340px keyboard inset. `PxScreen` now preserves its
layout height and supplies keyboard-sized scroll padding; its containing
scaffolds leave keyboard handling to that scroll view.

Formatting, Flutter analysis, and all five widget tests pass; see
`ipad-quality.txt`. Web release and iOS Simulator debug builds also passed
before the UI handoff.

## Real UI verification

Chrome, native iPhone 17, and native iPad Pro 11-inch (M5), with both
Simulators running iOS 26.5, completed one shared room (`54ZSP`) on a normal
server with test mode disabled. The testing agent used actual controls and
captured a full-desktop recording with structured annotations.

- Native tablet and phone draft retention, keyboard hide/show, Send, and
  scroll access to lobby controls passed.
- Both native joysticks moved and released correctly. Block removal and
  torch placement synchronized visually across all three clients.
- Web removed the tablet torch and placed a nearby synchronized replacement;
  exact-coordinate replacement was not established.
- Three-way gameplay chat and native tablet Options/Done/Back to Game passed.
- All three results showed each player with 2 points, 1 placed and 1 broken,
  and identical client world/chat fingerprints.
- All clients returned to the shared lobby.

Simulator Cmd+K left a lower strip while iPad game chat remained focused.
Using the normal on-screen Hide Keyboard button restored full height
immediately. Normal chat controls remained usable, and closing chat restored
the complete HUD. The Cmd+K behavior is retained as a Simulator observation.

Detailed results are in `../three-device-8400c436/REPORT.md`; its neighboring
directory contains the markers, screenshots, recordings and validation
samples.

## Scope

This is a focused Web+iPhone+iPad UI regression run. It does not refresh the
original Android/macOS/FPS or full visual-parity matrix. Earlier broad-suite
records retain their original fingerprints and remain historical evidence.
The original clone-this completion gate remains incomplete; its Android
virtualization and hardware-graphics blockers are unchanged.
