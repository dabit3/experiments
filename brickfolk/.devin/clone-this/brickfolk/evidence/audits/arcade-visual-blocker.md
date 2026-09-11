# Arcade revision: remaining visual gate

Revision: `sha256:28de8de72b8097419ce8ce0a05d0498605ff2df98f7292cb1f802dc0dd02d4f8`.

The arcade implementation, clean builds and functional checks are verified.
The complete clone-this run is **blocked**, because two normalized web/macOS
comparisons still fail. This is not a passing visual suite.

## Observed evidence

The four-platform Obby run `multiplayer-2026-09-11T02-38-18` reports identical
final state, leaderboard and checksum (`05b96827`) on web, iOS, Android, macOS
and the authoritative server. Its only failures are the hub and social
visual comparisons.

Fresh Tycoon (`multiplayer-2026-09-11T03-41-18`, checksum `2f1d181c`) and
Tag (`multiplayer-2026-09-11T03-45-21`, checksum `323fbb0a`) runs likewise
agree between web, macOS and the server and fail only those same comparisons.

| Screen | Differing normalized cells | Maximum channel delta | Largest edge cluster |
|---|---:|---:|---:|
| Hub | 1 | 64 | 3 |
| Social | 1 | 49 | 2 |
| Place, avatar, chat, profile, daily | 0 each | see metrics | see metrics |

Each normalized image is 295×190. The raw captures remain available in
each run's `visual/` directory; they have not been replaced or edited.
The failing hub cell is at (80, 81), around the large headline's descender.
The social cell is at (76, 20), around the heading's ampersand.
Inspection of the paired glyphs and difference image shows edge intensity
differences. Font rasterization is the likely cause; layout and content
agreement does not make these pixels pass the configured gate.

The repeated web capture has zero differences with zero tolerance. The
independent 8px-shift control still fails strongly (2,042 differing cells
in the final Tycoon/Tag runs). No comparison thresholds, masks, inventory
items or test expectations were relaxed.

## Investigated alternatives

- macOS Skia via `FLTEnableImpeller=false`: did not resolve the discrepancy.
- Official Inter 4.1 static OpenType/CFF faces: social passed, but hub worsened
  to 23 cells. Adding the official display optical face left 8 hub cells.
- App-local `AppleFontSmoothing=0`, through registration and persisted
  defaults: did not change the two discrepancies.

All experimental source/font/settings changes were reverted. The app keeps
its original bundled TrueType faces and default macOS renderer. The
app-local font preference introduced by the experiment was removed.

Related upstream reports:
- https://github.com/flutter/flutter/issues/137834 documents CanvasKit/native
  macOS font weight differences.
- https://github.com/flutter/flutter/issues/185790 and
  https://github.com/flutter/flutter/pull/186074 describe CoreText and Impeller
  glyph-edge behavior. These are context, not proof that either exact issue
  is the cause here.

## Resume condition

Obtain approval to calibrate a documented, narrowly bounded normalization
for the remaining glyph-edge variance, retaining the raw images and
independent sensitivity control; or provide a rendering configuration that
matches without changing the current gate. Re-run affected comparisons,
refresh the revision/evidence and execute `verify_state.py` afterward.

The edited review intentionally retains the harness's **FAILED** verdict
and 5/7 visual result. Its multiplayer agreement is a separate, passing
assertion. The earlier macOS Debug virtual-Metal manual-test failure and
successful Release retest remain documented in `arcade-ui.md`.
