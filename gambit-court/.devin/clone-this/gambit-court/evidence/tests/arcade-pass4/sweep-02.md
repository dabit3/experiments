# Final discovery sweep 2 — reverse review and adverse-state checks

Revision: `sha256:c4ab07ded4212875064fd8201f8a3fbd9584f47279a1d315c029b2c61e654bbc`

Repeated the inventory review starting from finished/rematch state and tracing
back through data, permissions and implementation. This pass checked the final
testing-agent findings against the actual artifacts, not just its pass count.

| Audit | Independent repeat inspection |
| --- | --- |
| source | Re-read the skill's full completion contract and compared current source boundaries with the public-reference/arcade-redesign authorization. |
| navigation | Traced imported final/initial positions to PGN export, result actions and lobby; inspected side effects behind the controls in controller/server source. |
| roles | Re-read server tests for wrong-turn, illegal and spectator moves plus bot takeback/resignation; synthetic platform labels in unit tests are not native Android runtime proof. |
| states | Rechecked finished and rematch platform images, manual bot/resignation and invite/checkmate outcomes, and current keyboard history results. Prior promotion/premove/offer checks remain explicitly supplemental. |
| responsive | Re-read normalized dimensions and unchanged tolerances for all four pairs; inspected native result cards and iOS active-turn/rematch cards separately from the desktop images. |
| data | Rechecked 33 plies, final FEN, score, PGN and 212000/210000 clock snapshots; checked widget tests for orientation mapping and running/stopped clock formatting. |
| assets | Re-read sound playback/failure handling and licensing/provenance. Simulator CoreAudio output is unavailable; the existing audio requirement remains unverified for iOS. |
| accessibility | Rechecked explicit token contrast results and focus/keyboard coverage; no complete screen-reader or reduced-motion certification is claimed. |
| reliability | Matched clean builds to source703c987; read current exit0/result.json; distinguished native debug runtime from release compile. Audited recorder fallback, screenshot misnaming correction and missing harness browser-console retention. |
| rebrand | Rechecked Gambit Court names in native windows, web header and shared asset/code layout; merge-base diff is confined to gambit-court/. |

New requirements: **0**. Discovery frontier: **empty**. The existing Android
runtime and audible-feedback requirements have external host limitations. The
audio finding updates the status of the existing audio inventory item; it is
not deleted or inferred to work. No application source, fixtures, test
assertions, normalization tolerances or thresholds changed during either sweep.
