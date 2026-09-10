# Audit: roles

Revision sha256:7d8373da7208aea444736b3790b15f7782f3fba3b3168148ee65125ce3a86a8b, 2026-09-10T00:17:24Z

Roles: host/white, black, spectator, bot, reconnecting client. Server rejects spectator game actions, out-of-turn and illegal moves, non-host bot seating (HubError codes: badRequest, illegalMove, notAllowed, notInRoom, notPlaying, notYourTurn, roomNotFound). Harness verifies white/black/spectator seat assignment and swapped colours after rematch.
