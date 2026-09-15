# Approved font-edge normalization

On resuming this session, the user selected **“Approve scoped font-edge
normalization”** for the arcade glyph-edge blocker. This explicitly authorizes
the narrowly bounded normalization below. The prior blocked report, verifier,
raw images, metrics and edited review remain historical evidence.

## Method and bounds

The two known divergent text elements are the hub hero headline (content
rectangle `256,232,384,108`) and the social heading (`216,76,160,28`).
Rectangles cover the complete labels, not individual failing cells. The
1180×760 capture fixture pins their geometry. No other screen receives this
filter.

Apply the same 5×5 box filter independently to each image, inside that screen's
text rectangle, at native resolution before the existing 4× downscale.
The radius is two native pixels. The filter neither reads nor writes outside
the rectangle, cannot sample the other capture, and does not alter source PNGs.
It smooths rasterized edge intensity rather than replacing pixels with a
baseline or masking the text. Colour, content, and geometry remain compared.

The pre-existing tolerance 48, edge threshold 24, edge budget 56, cluster limit
8, one-cell matching neighbourhood, and platform/window masks are unchanged.
Raw captures and the pre-filter comparison (under `unfiltered/` for each
affected screen) remain separate from the normalized outputs and metrics.

## Calibration

The earlier four-platform run (`multiplayer-2026-09-11T02-38-18`) is a fixed
calibration pair, not fresh execution evidence. Its hub also exceeded the
56-cell edge budget (83 cells), in addition to its one differing cell;
the earlier summary did not call out that additional failed condition.

A 3×3 filter was insufficient: hub still had one differing cell, 66 edge cells,
and max delta 59. A 5×5 filter on the same original captures produced hub
0 differing / 41 edge / max delta 47 / cluster 2 and social 0 differing /
11 edge / max delta 34 / cluster 2. Both satisfy every existing bound.
Calibration output is stored under
`evidence/tests/font-normalization-calibration{,-5x5}/`.

## Independent controls

`test/e2e/test_visual_compare.py` exercises the real comparator CLI and proves:
identical captures pass; shifted (8px), missing, changed and recoloured glyphs
inside the filter bounds fail; changes outside the bounds fail; invalid bounds
are rejected; source captures remain byte-for-byte unchanged. Unit assertions
also check two-pixel support and no reads/writes across the text boundary.

Every fresh visual tour runs the 8px shift sensitivity control with the hub's
filter enabled. It must still fail. Repeated web captures remain compared
without the new filter and with zero tolerance.

The fresh execution results and revision are indexed by `state.json`; this
document alone does not assert completion. The commercial reference was not
run or purchased. The claim is normalized parity between Brickfolk clients.
