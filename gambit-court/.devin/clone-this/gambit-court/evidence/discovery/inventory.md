# Inventory

Revision sha256:7d8373da7208aea444736b3790b15f7782f3fba3b3168148ee65125ce3a86a8b (git 53810c2c982a68119fc9dd8300cfed34a4893bd8), 2026-09-10T00:17:24Z

- `route-lobby` [route] verified: Lobby screen: identity, theme, quick-pair, create/join by invite code, open tables, bot level
- `route-game` [route] verified: Game screen: board, player cards, clocks, move list, offers, history browsing
- `route-results` [route] verified: Results overlay: outcome, reason, score, PGN export, rematch, back to lobby
- `route-review` [route] verified: PGN review mode reached from import (read-only board + move list)
- `feature-rules-fide` [feature] verified: Legal move generation incl. castling, en passant, promotion, check, checkmate, stalemate (perft + rule unit tests)
- `feature-rules-draws` [feature] verified: Threefold repetition, fifty-move rule, insufficient material, stalemate detection
- `feature-promotion-picker` [feature] verified: Promotion requires an explicit piece choice (picker in UI, `Promotion piece required` from server)
- `feature-san-pgn` [feature] verified: SAN move list; PGN export/import round trip
- `feature-clocks` [feature] verified: Server-owned clocks with bullet/blitz/rapid/classical presets and custom increment; first move per side untimed; frozen-clock determinism
- `feature-resign-draw-takeback` [feature] verified: Resign, draw offers/accept/decline, takeback by agreement, rematch with colour swap
- `feature-board-input` [feature] verified: Drag and tap-tap input, last-move/legal-move/check highlights, premove, board flip, keyboard history browsing
- `feature-lobby-multiplayer` [feature] verified: Quick-pair, six-character invite codes, open tables, spectators, seat retention across reconnect
- `feature-bot` [feature] verified: Server-side alpha-beta engine bot with four strengths, deterministic under --seed
- `feature-themes` [feature] verified: Dark and light themes on every platform
- `feature-automation-bridge` [feature] verified: Deterministic test-input channel (ui_command/ui_report) and /control endpoints, opt-in via --control
- `journey-four-way-match` [journey] verified: Two platforms play, others spectate the same room: lobby -> match -> checkmate -> identical FEN/SAN/score/clocks -> results -> PGN -> rematch -> lobby (verified web/iOS/macOS; Android runtime blocked, see blocker)
- `journey-reconnect` [journey] verified: Spectator drops its socket mid-game and resumes the same room/game
- `journey-history-review` [journey] verified: Browse earlier plies while the live move list stays intact; PGN import opens review mode
- `visual-lobby-ios` [visual] verified: lobby screen: ios matches the web baseline at 402x812 logical px (normalized)
- `visual-review-ios` [visual] verified: review screen: ios matches the web baseline at 402x812 logical px (normalized)
- `visual-lobby-macos` [visual] verified: lobby screen: macos matches the web baseline at 1000x488 logical px (normalized)
- `visual-review-macos` [visual] verified: review screen: macos matches the web baseline at 1000x488 logical px (normalized)
- `asset-original-art` [asset] verified: Original vector piece set, brand mark, app icons; no third-party or trademarked artwork
- `asset-original-audio` [asset] verified: Original generated sound effects (app/tool/make_sfx.py)
- `integration-websocket-server` [integration] verified: Authoritative Dart WebSocket server; JSON protocol documented in PROTOCOL.md
- `journey-android-runtime` [journey] blocked: Android emulator client joins the four-way match (build verified; runtime blocked on this host)
