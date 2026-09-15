# Fresh-session probe

This supplemental protocol probe runs real WebSocket connections against two
new server instances with seeds 73 and 97. It does not substitute for native
client testing.

The first draft incorrectly waited for a lobby after unanimous rematch votes
and timed out at that assertion. `PROTOCOL.md` line 64 explicitly specifies
that rematch returns to `playing` with colors swapped; `Room.voteRematch`
immediately invokes `startMatch`. The probe now checks that documented
contract, including a new game ID, empty move history, cleared result, and
swapped colors. No application code or existing regression test changed.
