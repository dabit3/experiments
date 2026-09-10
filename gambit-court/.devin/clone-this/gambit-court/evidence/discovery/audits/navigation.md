# Audit: navigation

Revision sha256:7d8373da7208aea444736b3790b15f7782f3fba3b3168148ee65125ce3a86a8b, 2026-09-10T00:17:24Z

Screens: game_screen.dart, lobby_screen.dart plus results and review overlays. Journeys covered by the harness: connect, room, play, reconnect, results, rematch, parity. Every navigation edge (lobby->waiting->game->results->rematch->lobby, game->history, import->review->close) is exercised in result.json.
