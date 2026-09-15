# Audit: navigation

Revision sha256:221b49e453f4998c69eedc8c6d1975f491980834545aca020fdf8e334d2b8f87, 2026-09-10T13:48:49Z

Screens: game_screen.dart, lobby_screen.dart plus results and review overlays. Journeys covered by the harness: connect, room, play, reconnect, results, rematch, parity. Every navigation edge (lobby->waiting->game->results->rematch->lobby, game->history, import->review->close) is exercised in result.json.
