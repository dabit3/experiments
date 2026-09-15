# Visual normalization (web baseline → native macOS)

Reference-access boundary: the original title cannot be run here, so no capture
of it exists. "Visual parity" in this run means the clone's own clients render
the shared UI identically; the web build is the baseline.

## Capture conditions

* Both clients render the same synthetic fixture (`director fixture <screen>`):
  room `FIXTR`, five fixed roster entries, fixed time/tick/scores, frozen clock.
* Web: Chromium 1280×800 viewport, DPR 1 (`web-<screen>.png`).
* macOS: native window pinned to a 1280×800 logical content size via
  `VH_WINDOW=1280x800` (`macos-<screen>.window.png` is the CGWindow capture,
  `macos-<screen>.png` the same image scaled to 1280×800 logical px).
* Every client also dumps its render tree (`director layout`) as
  `<platform>-<screen>.layout.json`: one node per `RenderParagraph` / icon with
  text, x, y, w, h in logical pixels.

## What is compared and why

Raw screenshots are **recorded, not asserted**: Chromium (Skia, CanvasKit) and
Impeller-on-Metal rasterize glyphs differently, so identical layouts still differ
in anti-aliasing (see `*.raw.diff.png`).

The asserted comparison is structural (run `e2e-20260910-093258`, iteration 7 revision):

1. `nodes.json` — every baseline node must have a counterpart on the other
   platform with the same text and a position/size within **2 logical px**
   (`matched == nodes`, `mismatched_count == 0`).
2. Layout maps — each `layout.json` is rasterized to a 1280×800 wireframe PNG
   (`*.layout.png`: one filled rectangle per node). The macOS map is re-drawn
   with each node **snapped to its matched web node** when within tolerance
   (`*.layout.normalized.png`), then diffed against `web-<screen>.layout.png`
   (`*.layout.diff.png`). The gate requires `different_pixels == 0`.
3. `*.layout.raw.diff.png` records the pre-snap wireframe diff. With every
   node on the integer GUI-pixel grid this run is 0 px for lobby and results
   even before snapping (137/137 and 198/198 nodes exact).

Items using this evidence: `visual-lobby-macos`, `visual-results-macos`.
The `home` screen is recorded only: it intentionally shows a platform badge and
the local player name, which differ per client (28/34 nodes matched; 25 exact).
iOS (874×402 logical, landscape) renders the phone layout family and is recorded, not compared.
