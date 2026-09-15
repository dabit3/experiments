# Voxelhearth four-platform multiplayer e2e — FAILED

Platforms: web, ios, macos · room HEARTH · seed 1234 · 2026-09-10T01:21:52.795Z → 2026-09-10T01:23:51.534Z

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

Screenshots: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/e2e-20260909-182050/screenshots`
Recording: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/e2e-20260909-182050/four-way-recording.mp4`

Failures:
- exception: iOS wait_screen failed: {"ok":false,"screen":"playing","t":"drive_done","id":"d75","player":"iOS","playerId":"p-7bddcc6c"}