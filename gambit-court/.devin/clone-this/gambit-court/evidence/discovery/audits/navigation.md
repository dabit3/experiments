# Audit: navigation

Revision sha256:a9c3cf81c62fa9e83de74f535d25bce98c6c9b89422ddf6ef38f75f6855c134b, 2026-09-09T23:48:42Z

Screens: game_screen.dart, lobby_screen.dart plus results and review overlays. Journeys covered by the harness: connect, room, play, reconnect, results, rematch, parity. Every navigation edge (lobby->waiting->game->results->rematch->lobby, game->history, import->review->close) is exercised in result.json.
