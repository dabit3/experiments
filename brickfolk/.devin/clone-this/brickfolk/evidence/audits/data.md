# Data audit

## Storage
SQLite via `sqlite3` on the server (`brickfolk-test.db` in the evidence run;
`brickfolk.sqlite` by default). Two tables (`server/lib/src/db.dart`):
- `players` — id, unique case-insensitive name, resume token, avatar (JSON),
  pips, owned items (JSON), badges (JSON), created_at, daily_streak,
  last_daily_claim, stats (JSON), plot (JSON).
- `friends` — from_id, to_id, accepted (requests are rows with accepted = 0).

Clients persist only the resume token, player name, theme, sound and haptics
preferences via `shared_preferences` (localStorage on web).

## Ownership and consistency
- All game state is server-authoritative; clients send `input` intents only.
- Rooms simulate at 30 ticks/s from a seeded RNG; results carry a checksum that
  every client and the server compute independently (`report.json`
  `checksum` == `serverChecksum`).
- Currency changes (buy, daily claim, match rewards) are applied on the server
  and echoed to the client in the `profile` message.
- Match results, badges and the tycoon plot are written back to `players`
  when a match ends; bots are never persisted.

## Protocol
`PROTOCOL.md` documents every message, error code and lifecycle. Version 1.

## Validation
Names: `^[A-Za-z][A-Za-z0-9_]{2,15}$`. Chat: max 140 chars, filtered, rate
limited. Party codes: 4 letters from the code alphabet. Inputs are clamped by
the simulation.

Evidence: `brickfolk-test.db` (players persisted by the four-platform run),
`server-test.log` (persistence, duplicate names, daily cooldown, plot persists).
