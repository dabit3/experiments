# Visual normalization disclosure — run e2e-20260910T152718Z

Comparison mode: **normalized** (not exact). Reference = Swapmate's own web
build (CanvasKit, Playwright Chromium) rendered at each native client's
device geometry; actual = the native client's device screenshot (iOS
Simulator `simctl io screenshot`, Android `adb exec-out screencap`, macOS
`screencapture -l <window>`). No comparison against the commercial source
title is made or claimed (it is inaccessible; see audit-source.md).

## Reason
Native targets rasterize with Impeller (Metal / Vulkan-on-SwiftShader) and
the web baseline with CanvasKit. Glyph and curve coverage differs by a few
levels along every edge and gradients dither differently, so an exact
compare reports hundreds of thousands of differing pixels for images that
are the same layout, colours and content.

## Bounds (identical for every comparison, recorded in each metrics JSON)
* flat regions: per-channel tolerance 16/255 (`VISUAL_TOLERANCE`)
* edge bands: pixels within 2 px (`VISUAL_EDGE_RADIUS`) of a reference
  colour step > 16 (`VISUAL_EDGE_THRESHOLD`) are excluded; the excluded
  fraction is reported per image ("edge band")
* pixelmatch-style anti-aliasing detection, 1 px jitter (`VISUAL_SHIFT`)
* crops: iOS actual is cropped to the safe area below the status bar
  (0,186,1206,2334); macOS actual is cropped below the window title bar
  (0,TITLE,1180,800); Android uses the full 540x1200 frame. Web references
  are rendered at those exact geometries (see visual/geometry.txt).
* masks: only the two 14x14 px rounded bottom corners of the macOS window
  chrome ([0,786,14,14] and [1166,786,14,14]); iOS and Android use no masks
  (`masks` column below)

Method: `test/compare_png.py` decodes both PNGs fully (zlib/stdlib), applies
the rules above, writes reference/actual/diff/overlay PNGs and the metrics
JSON. Harness: `test/multiplayer-e2e.sh` (visual parity phase).

## Results
| comparison | size | exact diff px | edge band | aa px | jitter px | normalized diff px | masks | crop_actual |
|---|---|---|---|---|---|---|---|---|
| android-spec-home-dark | 540x1200 | 163173 | 17.1% | 0 | 0 | 0 | [] | [0, 0, 540, 1200] |
| android-spec-home-light | 540x1200 | 183466 | 17.6% | 0 | 0 | 0 | [] | [0, 0, 540, 1200] |
| android-spec-results | 540x1200 | 45834 | 27.0% | 0 | 0 | 0 | [] | [0, 0, 540, 1200] |
| ios-spec-home-dark | 1206x2334 | 1192489 | 9.8% | 0 | 0 | 0 | [] | [0, 186, 1206, 2334] |
| ios-spec-home-light | 1206x2334 | 1206627 | 10.3% | 0 | 0 | 0 | [] | [0, 186, 1206, 2334] |
| ios-spec-results | 1206x2334 | 113666 | 17.5% | 0 | 0 | 0 | [] | [0, 186, 1206, 2334] |
| macos-spec-home-dark | 1180x800 | 666477 | 7.8% | 0 | 0 | 0 | [[0, 786, 14, 14], [1166, 786, 14, 14]] | [0, 32, 1180, 800] |
| macos-spec-home-light | 1180x800 | 662819 | 8.8% | 0 | 0 | 0 | [[0, 786, 14, 14], [1166, 786, 14, 14]] | [0, 32, 1180, 800] |
| macos-spec-lobby | 1180x800 | 44618 | 14.8% | 0 | 0 | 0 | [[0, 786, 14, 14], [1166, 786, 14, 14]] | [0, 32, 1180, 800] |
| macos-spec-results | 1180x800 | 74224 | 25.2% | 0 | 0 | 0 | [[0, 786, 14, 14], [1166, 786, 14, 14]] | [0, 32, 1180, 800] |

## Independent behaviour (negative controls, same normalization)
The controls must report differences, proving the bounds still detect a
4 px layout shift, a different screen and a theme change.

| control | normalized diff px | expectation | result |
|---|---|---|---|
| screen-swap | 230428 | must be > 0 | ok |
| shift-4px | 4148 | must be > 0 | ok |
| theme-swap | 868599 | must be > 0 | ok |

Log: `e2e.log` in this directory (lines "visual parity phase" onward).
