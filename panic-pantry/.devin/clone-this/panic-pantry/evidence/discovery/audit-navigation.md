# Audit: navigation

Panic Pantry is a single-window state machine (`app/lib/main.dart:_screen`):
there are no URL routes, deep links or auth walls; the web build takes its
configuration from the query string (`server`, `room`, `name`, `level`,
`auto`).

Edges verified by executable tests (each row names the artefact that proves it):

| Edge | Verified by |
| --- | --- |
| home -> Host -> lobby | `evidence/tests/ui-smoke/summary.json` "host from home opens a lobby on the requested level" (+ `08-lobby-dark.png`) |
| home -> Join code -> lobby | `evidence/e2e/<run>/e2e.log` (four clients join `E2E4`), `*-lobby.png` |
| home -> Join bad code -> stays home + toast | ui-smoke "joining a missing room stays on home with an error" (`05-join-error-toast.png`) |
| home -> Join full room -> stays home + toast | ui-smoke "joining a full room is rejected" |
| home / lobby -> help -> how-to-play -> Got it / back -> previous | ui-smoke "how-to-play sheet keeps the home route underneath" (`03-how-to-play.png`, `04-home-after-dismiss.png`, `07-how-to-play-dark.png`) |
| lobby -> Start -> countdown -> game | E2E `e2e.log` "match started", `*-gameplay.png` |
| game -> timer + overtime -> results | E2E `summary.json` (`resultsMatch`, phase finished), `*-results.png` |
| results -> Rematch -> lobby -> second match | `evidence/tests/unit-tests.log` server test "hello, create, join, ready, start, results and rematch" |
| any -> Leave -> home (room closed when empty) | ui-smoke "leave returns to home", "empty room is closed on leave", "second leave returns to home" |
| game -> Esc / menu -> pause overlay | `app/lib/screens/game_screen.dart` (`_menu`), keyboard table in README; not covered by an automated harness (recorded gap, non-blocking; the overlay is plain Material widgets analysed by `flutter analyze`) |
| PP_AUTO joining panel -> lobby | visual harness `painted` check (`evidence/diffs/visual-parity.log`: every lobby capture shows the lobby, never the joining panel) |

Transitions are animated with `AnimatedSwitcher`; the outgoing screen holds
its own `RoomInfo` / results snapshot, so a viewport or theme change during
the fade cannot dereference a room that the client already cleared. This was
a real defect found by the smoke test's console-error check and fixed before
the current revision (`ui-smoke/web-console.log` is empty of errors).

Sitemap (from `inventory.md`): home, joining, how-to-play, lobby, game
(+ pause overlay, emote sheet, reconnect banner, overtime banner, countdown),
results. Each route has its own inventory record with current evidence.
