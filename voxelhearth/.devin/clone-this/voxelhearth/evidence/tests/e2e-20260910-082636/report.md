# Voxelhearth four-platform multiplayer e2e — PASSED

Platforms: web, ios · room HEARTH · seed 1234 · 2026-09-10T15:27:15.092Z → 2026-09-10T15:28:50.462Z

| check | result | detail |
|---|---|---|
| all players in one lobby | pass | `Bot Ashwick(bot), Web(web), iOS(ios)` |
| found a flat row for the shared structure | pass | `[[41,34,45],[42,34,45]]` |
| dropped client rejoined the same room | pass | `{"ok":true,"dropped":true,"rejoined":true,"room":"HEARTH","phase":"playing","phaseBefore":"playing","state":"connected","error":null,"t":"drive_done","id":"d45","player":"Web","playerId":"p-000f6823"}` |
| every client answered the hash request | pass | `missing=[]` |
| world hash identical on all clients + server | pass | `{"server":"d8ee49a6","clients":{"Web":"d8ee49a6","iOS":"d8ee49a6"}}` |
| chat hash identical on all clients + server | pass | `{"server":"37dbdaa7","clients":{"Web":"37dbdaa7","iOS":"37dbdaa7"}}` |
| structure region identical on all clients | pass | `"b2e7fc2f"` |
| server structure matches script (lower row placed, upper row broken) | pass | `[9,9,0,0]` |
| chat history identical on all clients | pass | `9 lines` |
| every player line present in chat | pass | `` |
| final scoreboard identical on all clients | pass | `[{"name":"Web","platform":"web","bot":false,"score":3,"placed":2,"broken":1,"crafted":0,"kills":0,"deaths":0},{"name":"iOS","platform":"ios","bot":false,"score":3,"placed":2,"broken":1,"crafted":0,"kills":0,"deaths":0},{"name":"Bot Ashwick","platform":"bot","bot":true,"score":1,"placed":0,"broken":1` |
| final world/chat fingerprints identical on all clients | pass | `["d8ee49a6","37dbdaa7"]` |
| final world/chat fingerprints match server | pass | `{"client":["d8ee49a6","37dbdaa7"],"server":["d8ee49a6","37dbdaa7"]}` |
| scoreboard credits 2 placed + 1 broken per player | pass | `[["Web","web",3,2,1],["iOS","ios",3,2,1]]` |

## Visual matrix (identical fixture data, web = baseline, 1280x800 logical)

| screen | platform | nodes matched (±2px) | exact nodes | normalized layout px diff | raw layout px diff | raw screenshot px diff | asserted |
|---|---|---|---|---|---|---|---|
| lobby | ios | n/a | n/a | n/a | n/a | n/a | phone layout 874x402 — different layout family, not compared |
| results | ios | n/a | n/a | n/a | n/a | n/a | phone layout 874x402 — different layout family, not compared |
| home | ios | n/a | n/a | n/a | n/a | n/a | phone layout 874x402 — different layout family, not compared |

Screenshots: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/e2e-20260910-082636/screenshots`
Recording: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/e2e-20260910-082636/four-way-recording.mp4`
Edited review video: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/e2e-20260910-082636/review-video.mp4` (chapters in `review-script.json`)
