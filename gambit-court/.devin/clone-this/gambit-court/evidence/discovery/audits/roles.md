# Audit: roles

Revision sha256:c0981af2ad3b96f6b293518092fb514456651a2af7365bf678b41423ae6d43ca, 2026-09-10T01:26:51Z

Roles: host/white, black, spectator, bot, reconnecting client. Server rejects spectator game actions, out-of-turn and illegal moves, non-host bot seating (HubError codes: badRequest, illegalMove, notAllowed, notInRoom, notPlaying, notYourTurn, roomNotFound). Harness verifies white/black/spectator seat assignment and swapped colours after rematch.
