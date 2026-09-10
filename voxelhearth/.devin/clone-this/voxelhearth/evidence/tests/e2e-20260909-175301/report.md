# Voxelhearth four-platform multiplayer e2e — PASSED

Platforms: web, ios, macos · room HEARTH · seed 1234 · 2026-09-10T00:53:07.915Z → 2026-09-10T00:54:41.372Z

| check | result | detail |
|---|---|---|
| all players in one lobby | pass | `Bot Ashwick(bot), Web(web), iOS(ios), Mac(macos)` |
| found a flat row for the shared structure | pass | `[[41,34,45],[42,34,45],[40,34,45]]` |
| every client answered the hash request | pass | `missing=[]` |
| world hash identical on all clients + server | pass | `{"server":"5778c6b4","clients":{"Web":"5778c6b4","iOS":"5778c6b4","Mac":"5778c6b4"}}` |
| chat hash identical on all clients + server | pass | `{"server":"53f85e46","clients":{"Web":"53f85e46","iOS":"53f85e46","Mac":"53f85e46"}}` |
| structure region identical on all clients | pass | `"12e88ebe"` |
| server structure matches script (lower row placed, upper row broken) | pass | `[9,9,9,0,0,0]` |
| chat history identical on all clients | pass | `9 lines` |
| every player line present in chat | pass | `` |
| final scoreboard identical on all clients | pass | `[{"name":"Web","platform":"web","bot":false,"score":3,"placed":2,"broken":1,"crafted":0,"kills":0,"deaths":0},{"name":"iOS","platform":"ios","bot":false,"score":3,"placed":2,"broken":1,"crafted":0,"kills":0,"deaths":0},{"name":"Mac","platform":"macos","bot":false,"score":3,"placed":2,"broken":1,"cra` |
| final world/chat fingerprints identical on all clients | pass | `["5778c6b4","53f85e46"]` |
| final world/chat fingerprints match server | pass | `{"client":["5778c6b4","53f85e46"],"server":["5778c6b4","53f85e46"]}` |
| scoreboard credits 2 placed + 1 broken per player | pass | `[["Web","web",3,2,1],["iOS","ios",3,2,1],["Mac","macos",3,2,1]]` |
| visual layout parity web→macos (lobby) | pass | `{"nodes":"110/110","mismatched":0,"layoutPx":34,"rawPx":35801,"total":1024000}` |
| visual layout parity web→macos (results) | pass | `{"nodes":"158/158","mismatched":0,"layoutPx":203,"rawPx":954549,"total":1024000}` |

## Visual matrix (identical fixture data, web = baseline, 1280x800 logical)

| screen | platform | nodes matched (±2px) | layout-map px diff | raw px diff | asserted |
|---|---|---|---|---|---|
| lobby | ios | 0/110 | 1024000 | 1024000 | recorded only |
| lobby | macos | 110/110 | 34 | 35801 | yes |
| results | ios | 0/158 | 1024000 | 1024000 | recorded only |
| results | macos | 158/158 | 203 | 954549 | yes |
| home | ios | 0/69 | 1024000 | 1024000 | recorded only |
| home | macos | 62/69 | 3524 | 598323 | recorded only |

Screenshots: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/e2e-20260909-175301/screenshots`
Recording: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/e2e-20260909-175301/four-way-recording.mp4`
