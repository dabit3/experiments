# Audit: states

| Surface | Empty | Loading / busy | Error | Populated | Evidence |
| --- | --- | --- | --- | --- | --- |
| Home | offline chip before connect | connecting chip | failed chip + retry; join errors as toast, field keeps code | connected chip, feature chips | ui-smoke `02-home-light.png`, `05-join-error-toast.png`, `06-home-dark.png`; `home_screen.dart` `ConnState` switch |
| Auto-join | - | "Joining kitchen..." `StatePanel` | timeout -> home + toast | -> lobby | visual harness `painted` check (`visual-parity.log`) |
| Lobby | open seats rendered as dashed "Open seat" tiles | latency chip until first pong | server `error` -> toast | 1-4 seats, ready chips, level grid | E2E `*-lobby.png` (1 human + 3 open on visual runs, 4 humans on E2E), `lobby-*.png` |
| Game HUD | no tickets -> empty rail | 3 s countdown overlay | app-level "Reconnecting..." overlay (game and lobby) with Leave while the socket is down | tickets, score, combo, stars, timer, overtime banner | E2E `*-gameplay.png`, `*-gameplay-late.png`, `four-way-match.mov` |
| Results | zero-served path shows 0 with "no dishes" chip | score count-up animation | - | stat tiles, dish chips, star reveal | `*-results.png`, visual `results-*.png` |
| How to play | - | - | - | scrollable sheet, light + dark | ui-smoke `03`, `07` |
| Theme | light and dark verified on home, how-to-play, lobby | | | | ui-smoke `08-lobby-dark.png`, `07-how-to-play-dark.png` vs light captures; visual harness runs in light |

Error states exercised end-to-end: missing room code and full room (server
`error` -> `lastError` in `test.report` -> toast), covered by
`evidence/tests/ui-smoke/summary.json`. Reconnect state is covered by the
server test "reconnect with token resumes seat mid-match" and the app-level
overlay in `main.dart` (shown in the lobby as well as in-game, with a Leave
action; a non-resumed reconnect drops the stale room and returns Home with a
toast). The arcade UI pass screenshot-verifies the overlay and restoration
(`evidence/tests/arcade-ui/ss_063bcb6e.png`, `ss_91ee254a.png`). The same pass
exercises natural overtime, zero-star completion, and rematch `best 0/3`.
