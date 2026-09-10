# Roles and permissions audit

Roles in Brickfolk are situational, not account tiers.

| Role | Capabilities | Enforced by |
|---|---|---|
| Guest (unsigned) | sign-in only | server rejects every message before `hello` with `unauthenticated` |
| Player | browse, edit avatar, buy, chat, friends, party, join rooms | session identity from `hello`/`resume` token |
| Party leader | launch the party into a room, kick members | `notLeader` error for non-leaders (server-test.log) |
| Room host | none beyond player; rooms are server driven | countdown starts when >= 2 ready seats or party launch |
| Bot | fills seats, plays deterministically, appears on leaderboards, never persists | `Player.isBot`, excluded from persistence and badges |
| Test controller | `/test/state`, `/test/control` | only when the server runs with `--test-mode`; endpoints are 404 otherwise |

Evidence: `server-state.json` (party leader, room members with `isBot`),
`report.json` (leaderboard includes bots), server tests for `notLeader`,
`nameTaken`, `unauthenticated`.
