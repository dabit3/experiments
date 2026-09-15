# Voxelhearth four-platform multiplayer e2e — PASSED

Platforms: web, ios, macos · room HEARTH · seed 1234 · 2026-09-11T04:15:52.389Z → 2026-09-11T04:19:54.369Z

| check | result | detail |
|---|---|---|
| all players in one lobby | pass | `Bot Ashwick(bot), Web(web), iOS(ios), Mac(macos)` |
| found a flat row for the shared structure | pass | `[[41,34,45],[42,34,45],[40,34,45]]` |
| dropped client rejoined the same room | pass | `{"ok":true,"dropped":true,"rejoined":true,"room":"HEARTH","phase":"playing","phaseBefore":"playing","state":"connected","error":null,"t":"drive_done","id":"d65","player":"Web","playerId":"p-000f6823"}` |
| every client answered the hash request | pass | `missing=[]` |
| world hash identical on all clients + server | pass | `{"server":"eaaa9c81","clients":{"Web":"eaaa9c81","iOS":"eaaa9c81","Mac":"eaaa9c81"}}` |
| chat hash identical on all clients + server | pass | `{"server":"65d71bfe","clients":{"Web":"65d71bfe","iOS":"65d71bfe","Mac":"65d71bfe"}}` |
| structure region identical on all clients | pass | `"12e88ebe"` |
| server structure matches script (lower row placed, upper row broken) | pass | `[9,9,9,0,0,0]` |
| chat history identical on all clients | pass | `11 lines` |
| every player line present in chat | pass | `` |
| server is in results phase | pass | `results` |
| final scoreboard identical on all clients | pass | `[{"name":"Bot Ashwick","platform":"bot","bot":true,"score":6,"placed":3,"broken":3,"crafted":0,"kills":0,"deaths":0},{"name":"Web","platform":"web","bot":false,"score":3,"placed":2,"broken":1,"crafted":0,"kills":0,"deaths":0},{"name":"iOS","platform":"ios","bot":false,"score":3,"placed":2,"broken":1` |
| final world/chat fingerprints identical on all clients | pass | `["eaaa9c81","aafaf3a7"]` |
| final world/chat fingerprints match server | pass | `{"client":["eaaa9c81","aafaf3a7"],"server":["eaaa9c81","aafaf3a7"]}` |
| scoreboard credits 2 placed + 1 broken per player | pass | `[["Web","web",3,2,1],["iOS","ios",3,2,1],["Mac","macos",3,2,1]]` |
| visual layout parity web→macos (lobby) | pass | `{"nodes":"120/120","exact":118,"mismatched":0,"normalizedPx":0,"layoutPx":30,"rawPx":799588,"total":1024000}` |
| visual layout parity web→macos (results) | pass | `{"nodes":"196/196","exact":196,"mismatched":0,"normalizedPx":0,"layoutPx":0,"rawPx":941416,"total":1024000}` |

## Visual matrix (identical fixture data, web = baseline, 1280x800 logical)

| screen | platform | nodes matched (±2px) | exact nodes | normalized layout px diff | raw layout px diff | raw screenshot px diff | asserted |
|---|---|---|---|---|---|---|---|
| lobby | ios | n/a | n/a | n/a | n/a | n/a | phone layout 874x402 — different layout family, not compared |
| lobby | macos | 120/120 | 118 | 0 | 30 | 799588 | yes |
| results | ios | n/a | n/a | n/a | n/a | n/a | phone layout 874x402 — different layout family, not compared |
| results | macos | 196/196 | 196 | 0 | 0 | 941416 | yes |
| home | ios | n/a | n/a | n/a | n/a | n/a | phone layout 874x402 — different layout family, not compared |
| home | macos | 19/28 | 17 | 758 | 818 | 951938 | recorded only |

Screenshots: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/e2e-arcade-trio-af9795d-isolated/screenshots`
Recording: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/e2e-arcade-trio-af9795d-isolated/four-way-recording.mp4`
Edited review video: (not produced)
