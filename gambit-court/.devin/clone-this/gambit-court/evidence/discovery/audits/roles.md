# Audit: roles

Revision sha256:221b49e453f4998c69eedc8c6d1975f491980834545aca020fdf8e334d2b8f87, 2026-09-10T13:48:49Z

Roles: host/white, black, spectator, bot, reconnecting client. Server rejects spectator game actions, out-of-turn and illegal moves, non-host bot seating (HubError codes: badRequest, illegalMove, notAllowed, notInRoom, notPlaying, notYourTurn, roomNotFound). Harness verifies white/black/spectator seat assignment and swapped colours after rematch.
