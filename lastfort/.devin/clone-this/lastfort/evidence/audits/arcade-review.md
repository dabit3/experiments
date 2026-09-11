# Arcade revision audit

Source: `bf6d75c`, fingerprint
`sha256:12c38dceff1887918e4cec2451a13daedef1aa29605ac2c36adf1cdd3a8c82a1`.
The client implementation is unchanged from `921cef2`; the later commit fixes
automation capture sequencing and documents it.

This audit supersedes old layout descriptions in the historical category
reports. It does not promote prior screenshots to the current visual revision.
Current manual observations and their scope limits are recorded in
`evidence/tests/manual-arcade/report.md`.

## Source and reference boundary

The source remains the public documentation recorded in
`evidence/discovery/source-reference.md`. No running commercial game, source
code, design file or licensed asset was available. Requirements remain inferred
from public descriptions. Literal original-game pixel parity is inaccessible.
The current visual reference is Lastfort's own web build.

## Navigation and roles

The hub now has a top navigation bar: Play, Locker, Pass, Settings. Desktop
Play uses a headline, central scout, party row and action panel; short/narrow
viewports use a scrollable column. Create/join → ready → bus/drop → gameplay →
spectate/match-over → results → same-room return was exercised on web and iOS.
The manual Solo game and automated squad game exercise distinct modes.

Roles remain local identity, host/member, human/bot and alive/spectating.
Authoritative room ownership and reconnection remain covered by the unchanged
server tests, rerun from the clean source checkout.

## States and real effects

The manual report records actual inventory, ammunition and material changes,
structure creation, shared storm progression and final scoreboard results.
It also records untested PvP, Duos and animation cases. Earlier reconnect/error
screens are historical evidence; this redesign did not re-exercise every error
state. The clean server regression suite covers takeover, timeout, reconnect
and consecutive matches.

## Responsive layout and visual comparisons

Current evidence covers desktop/phone web and native iPhone layouts, light and
dark themes, narrow HUD panels and safe-area-aware touch controls. The final
native touch fix was checked after rebuilding. No Android screenshot exists.
macOS receives a clean native build; earlier macOS screenshots are historical.

Zero-difference cross-renderer parity remains unresolved. Old web/macOS pixel
counts describe the older revision only. They are retained as historical
measurements, not claimed as measurements of the arcade revision.

## Data and integrations

The redesign does not change the deterministic simulation, protocol, room
state, prediction, interest management or persistence. The current core and
server suites exercise those paths from a clean checkout. VM/dart2js
determinism is rerun in `evidence/checks/arcade-determinism-sweep.txt`.
The final automated match supplies current independent client/server reports.
There is no external account, payment or asset-upload integration.

## Assets and identity

The island key art is an original generated Lastfort asset. Procedural scout
outfits, player silhouettes, foliage and structures use the existing original
cosmetic palettes. Rajdhani retains its OFL license. App IDs, titles and
wordmarks remain Lastfort. No source-game names/assets were introduced into
the shipped client. Native entrypoints remain native Flutter applications.

## Accessibility and input

The common readable-accent helper improves light-theme labels. Empty party
cards and JOIN controls use strong surfaces. Selected native touch controls
use opaque accent fills and dark labels. The agent verified selected and
unselected Sprint/Build states in a fresh build. Lobby reduced motion was
measured; native motion timing remains a coverage limit. Existing Semantics
labels, keyboard controls and touch targets were retained. This is not a
full screen-reader or WCAG audit.

## Reliability and release

Three-color native `ui.Gradient` calls now specify stops. A native Canvas
regression test failed before the fix and passes afterward; it renders every
scout outfit plus a gameplay frame with resource nodes and a player, checking
balanced Canvas state. Reviewed native logs show no painting exception.

Final checks are recorded separately: client format/analyze/tests in
`evidence/checks/arcade-final-client.txt`; all four clean builds, core/server/
client tests and real native artifact inspection in
`evidence/checks/arcade-clean-builds.txt`. Android runtime remains externally
blocked by unavailable nested virtualization. This audit does not waive either
the Android runtime requirement or the visual parity requirement.

The first final automation attempt (`e2e-20260910-194205`) passed multiplayer
assertions but its native window setup outlasted the automatic countdown.
Inspection found gameplay in the files labelled lobby and bus. Those captures
and that video are superseded. The driver now holds the host start until after
lobby capture, requires the bus phase, records server phase per capture, and
fails on missing screenshots or failed video generation. It forwards the
client's WebSocket traffic to the real server without altering responses.

The corrected run is `evidence/tests/e2e-20260910-194927`. Both clients report
digest `5B0FF7B1` and 2331 snapshots. Web and iOS each harvested, built, dealt
damage and survived 108 seconds; the shared summary includes all sixteen
players. Clean-checkout builds passed at `bf6d75c` for all four targets.

Visual inspection confirmed the actual two-client lobby, game and results.
The bus still is captured at the start of the transition (iOS still shows the
lobby); the edited Drop chapter shows both bus UIs. Server phase files record
the capture-request phase, not a synchronized per-client render acknowledgement.
`phase-lobby.json` has `phase:null`, the server's pre-match representation.
This distinction is retained rather than describing every still as settled.

The review contains ten edited chapters, captions, platform labels, two
comparison cards and a digest verdict. Its chapter plan totals 49 seconds;
ffprobe reports 50.13 seconds after encoding. A complete animated WebP preview
was generated through Pillow because this FFmpeg build has no WebP encoder.
