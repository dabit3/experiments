# Audit: data

Only test/deterministic data is used; nothing is persisted between runs.

| Concern | Implementation | Evidence |
| --- | --- | --- |
| Authoritative state | `server/lib/src/room.dart` owns the `KitchenState`; clients only send `input` | `PROTOCOL.md`; server tests |
| Determinism | fixed seed per room, 20 Hz fixed step, deterministic bot planner (`server/bin/plan.dart`) | core test "bot rounds are deterministic and score" (two runs identical); E2E: offline plan == server == four clients (`summary.json` `results` equality for score/stars/served/tips/expired/bestCombo/wrongServes/burnt) |
| Snapshot integrity | full `game.snapshot` each tick; `tick`, `score`, `phase` echoed in `test.report` | E2E mid-match reports agree on tick/score (`e2e.log`) |
| Reconnect data | resume token restores seat, score and inventory | server test "reconnect with token resumes seat mid-match" |
| Room cleanup | empty rooms removed on last leave | ui-smoke "empty room is closed on leave" (0 rooms left) |
| Config inputs | web query string, `--dart-define`/env on native, validated 4-letter codes | README; ui-smoke join-error cases |
| No secrets / no PII | no accounts, chef names are free text and only kept in memory | `git grep` for tokens in `evidence/tests/quality.log` security section |

Seed/level/room fixtures for the final evidence: room `E2E4`, seed 23,
level `corner-cafe`, 4 humans, 0 bots (E2E); rooms `VIS1`/`XUQL`-style random
codes for visual / smoke runs.
