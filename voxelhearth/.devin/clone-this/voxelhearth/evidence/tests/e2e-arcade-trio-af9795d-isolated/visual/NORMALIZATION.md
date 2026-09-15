# Current arcade visual normalization

Source `af9795d`, fingerprint
`sha256:3b6df07fc2b5f62efab566427037ee8c37e88f116eb167e2e9710e86e1bfdc6d`.
The commercial original was not run or purchased. Web is the baseline for
Voxelhearth's own shared desktop UI, never a substitute source-game capture.

## Capture conditions

The director installs the same synthetic lobby/results fixture in the clients:
fixed room, roster, scores and clock. Chromium uses a 1280x800 viewport at DPR 1.
The native macOS window uses `VH_WINDOW=1280x800`; original CGWindow captures
are retained as `macos-<screen>.window.png` and logical-size captures as
`macos-<screen>.png`. Each client exports its paragraph/icon render nodes with
text and logical x/y/width/height to `<platform>-<screen>.layout.json`.

## Comparison and bounded normalization

Raw captures and `*.raw.diff.png` remain available. Raw artwork, particles,
shader output, shadows, antialiasing and font rasterization are not asserted
pixel-identical. Structural parity does not prove raw screenshot equality.

The existing `test/tools/pngcompare.py` matches every text/icon node by
normalized text and a maximum two-logical-pixel box delta. Unmatched nodes and
larger differences fail the node comparison. It renders colored rectangular
layout maps, snapping only matched native boxes within that pre-existing
tolerance to the Web box. The independent node check must also pass: snapping
is not a substitute for checking node counts and text.

| Fixture | Matched nodes | Exact boxes | Raw map differing pixels | Normalized differing pixels |
|---|---:|---:|---:|---:|
| Lobby | 120/120 | 118 | 30 | 0/1,024,000 |
| Results | 196/196 | 196 | 0 | 0/1,024,000 |

The layout JSON, `*.nodes.json`, raw maps, normalized maps and diff images
are separate retained files. Current screenshots and the lobby normalized diff
were inspected, and actual multiplayer behavior passed the 17-check trio run.

Home is recorded only: the platform, player name and local connection state
vary (19/28 nodes match). iOS is a separate 874x402 logical landscape phone
layout and is recorded rather than compared to the desktop baseline; its
actual controls and shared-world behavior were also exercised in the real UI
pass. Android has no live capture because the emulator cannot boot here.
