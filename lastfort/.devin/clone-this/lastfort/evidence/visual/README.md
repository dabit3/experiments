# Visual comparison: web baseline vs macOS (normalized cross-platform parity)

Historical captures from `evidence/tests/e2e-20260910-071751`, before the arcade
redesign. These counts do not measure the current revision. Current web/iOS
responsive comparisons and their limits are in `evidence/audits/arcade-review.md`
and `evidence/tests/manual-arcade/report.md`.

Reference-access boundary: the original game cannot be run here, so no comparison
against the original is possible or claimed. The visual items in `state.json` compare the
clone's own clients with each other: the **web build is the baseline**, and the macOS
window content area (the same 770x473 logical region; the 28 px macOS title bar is
cropped away by `tools/crop_png.py`) is the actual. iOS renders at a phone aspect ratio
(1206x2622) and Android could not be executed, so neither has a same-size pair to compare.

| screen | reference | actual | diff | differing px | total px |
| --- | --- | --- | --- | --- | --- |
| lobby | `web-lobby-ref.png` | `macos-lobby-act.png` | `diff-web-macos-lobby.png` | 358576 | 364210 |
| match-over HUD | `web-matchover-ref.png` | `macos-matchover-act.png` | `diff-web-macos-matchover.png` | 361367 | 364210 |
| results | `web-results-ref.png` | `macos-results-act.png` | `diff-web-macos-results.png` | 290835 | 364210 |

Raw counts are in `web-vs-macos.jsonl` (tolerance 0). Test builds pin the light theme and load an isolated profile namespace so a persisted theme or stats on one client can no longer skew the comparison. A second results comparison in the
run directory (`diff-web-macos-results-tol32.png`, tolerance 32/255 per channel) leaves
30835 differing pixels — those are the per-player numbers (each client shows its *own*
stats card: Web harvested 250, Mac harvested 271) and glyph edges.

## Why the pixel counts are not zero (unresolved, recorded honestly)

1. **Rendering backend.** Flutter web renders through CanvasKit (Skia/WebGL) while the macOS
   app renders through Impeller (Metal). Text anti-aliasing, sub-pixel glyph positioning and
   gradient dithering differ between the two, so nearly every pixel of the background
   gradient and every glyph edge differs by a small amount. The `--tolerance 32` run
   removes ~89% of the differing pixels, which is consistent with backend rasterisation
   noise rather than layout drift.
2. **Per-client content.** Each client shows its own player's numbers on the results card
   and its own camera position in the match-over HUD, so those regions legitimately differ.
3. **Layout geometry is identical.** The diff images show every card, chip, label and bar at
   the same position and size on both platforms (the diff is an outline, not a displaced
   shape), and the identical final digest `CA0FF4A2` proves the underlying match state is
   the same.

The visual items therefore stay `pending` with these measured counts; they are **not**
marked verified, and the `visual` check is recorded as `failed` at the final revision.
Closing this gap would require a renderer-independent capture (for example rasterising the
Flutter widget tree with the same engine on every platform) which is out of scope for
this run.
