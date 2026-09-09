# Audit: roles

Revision sha256:a9c3cf81c62fa9e83de74f535d25bce98c6c9b89422ddf6ef38f75f6855c134b, 2026-09-09T23:48:42Z

Roles: host/white, black, spectator, bot, reconnecting client. Server rejects spectator game actions, out-of-turn and illegal moves, non-host bot seating (HubError codes: badRequest, illegalMove, notAllowed, notInRoom, notPlaying, notYourTurn, roomNotFound). Harness verifies white/black/spectator seat assignment and swapped colours after rematch.
