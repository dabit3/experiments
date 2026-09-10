# Voxelhearth four-platform multiplayer e2e — PASSED

Platforms: web, ios, macos · room HEARTH · seed 1234 · 2026-09-10T01:27:02.102Z → 2026-09-10T01:28:32.259Z

| check | result | detail |
|---|---|---|
| all players in one lobby | pass | `Bot Ashwick(bot), Web(web), iOS(ios), Mac(macos)` |
| found a flat row for the shared structure | pass | `[[41,34,45],[42,34,45],[40,34,45]]` |
| dropped client rejoined the same room | pass | `{"ok":true,"dropped":true,"rejoined":true,"room":"HEARTH","phase":"playing","phaseBefore":"playing","state":"connected","error":null,"t":"drive_done","id":"d65","player":"Web","playerId":"p-000f6823"}` |
| every client answered the hash request | pass | `missing=[]` |
| world hash identical on all clients + server | pass | `{"server":"5778c6b4","clients":{"Web":"5778c6b4","iOS":"5778c6b4","Mac":"5778c6b4"}}` |
| chat hash identical on all clients + server | pass | `{"server":"65d71bfe","clients":{"Web":"65d71bfe","iOS":"65d71bfe","Mac":"65d71bfe"}}` |
| structure region identical on all clients | pass | `"12e88ebe"` |
| server structure matches script (lower row placed, upper row broken) | pass | `[9,9,9,0,0,0]` |
| chat history identical on all clients | pass | `11 lines` |
| every player line present in chat | pass | `` |
| final scoreboard identical on all clients | pass | `[{"name":"Web","platform":"web","bot":false,"score":3,"placed":2,"broken":1,"crafted":0,"kills":0,"deaths":0},{"name":"iOS","platform":"ios","bot":false,"score":3,"placed":2,"broken":1,"crafted":0,"kills":0,"deaths":0},{"name":"Mac","platform":"macos","bot":false,"score":3,"placed":2,"broken":1,"cra` |
| final world/chat fingerprints identical on all clients | pass | `["5778c6b4","65d71bfe"]` |
| final world/chat fingerprints match server | pass | `{"client":["5778c6b4","65d71bfe"],"server":["5778c6b4","65d71bfe"]}` |
| scoreboard credits 2 placed + 1 broken per player | pass | `[["Web","web",3,2,1],["iOS","ios",3,2,1],["Mac","macos",3,2,1]]` |
| visual layout parity web→macos (lobby) | pass | `{"nodes":"110/110","exact":108,"mismatched":0,"normalizedPx":0,"layoutPx":34,"rawPx":35801,"total":1024000}` |
| visual layout parity web→macos (results) | pass | `{"nodes":"158/158","exact":142,"mismatched":0,"normalizedPx":0,"layoutPx":203,"rawPx":966315,"total":1024000}` |

## Visual matrix (identical fixture data, web = baseline, 1280x800 logical)

| screen | platform | nodes matched (±2px) | exact nodes | normalized layout px diff | raw layout px diff | raw screenshot px diff | asserted |
|---|---|---|---|---|---|---|---|
| lobby | ios | n/a | n/a | n/a | n/a | n/a | phone layout 402x874 — different layout family, not compared |
| lobby | macos | 110/110 | 108 | 0 | 34 | 35801 | yes |
| results | ios | n/a | n/a | n/a | n/a | n/a | phone layout 402x874 — different layout family, not compared |
| results | macos | 158/158 | 142 | 0 | 203 | 966315 | yes |
| home | ios | n/a | n/a | n/a | n/a | n/a | phone layout 402x874 — different layout family, not compared |
| home | macos | 62/69 | 60 | 3444 | 3492 | 598513 | recorded only |

Screenshots: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/e2e-20260909-182614/screenshots`
Recording: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/e2e-20260909-182614/four-way-recording.mp4`
