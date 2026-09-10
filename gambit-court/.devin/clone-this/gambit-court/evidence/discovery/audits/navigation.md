# Audit: navigation

Revision sha256:c0981af2ad3b96f6b293518092fb514456651a2af7365bf678b41423ae6d43ca, 2026-09-10T01:26:51Z

Screens: game_screen.dart, lobby_screen.dart plus results and review overlays. Journeys covered by the harness: connect, room, play, reconnect, results, rematch, parity. Every navigation edge (lobby->waiting->game->results->rematch->lobby, game->history, import->review->close) is exercised in result.json.
