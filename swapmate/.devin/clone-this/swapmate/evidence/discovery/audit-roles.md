# Audit: roles — authentication and access

Swapmate has no accounts, sign-in, registration, recovery or plans (searched
`app/lib`, `server/lib`, `PROTOCOL.md`; the public reference describes no
account system either — accounts on commercial servers are out of scope by the
user's reference boundary). The roles that do exist are enforced by the
server (`server/lib/src/room.dart`, `server/lib/src/hub.dart`):

| Role | How it is obtained | What it may do | Enforcement |
| --- | --- | --- | --- |
| Host | Creates the room (`room.create`); passes to the next human when the host leaves | Start the match, change time control, add / remove bots | `ErrorCode.notHost` for anyone else (`Room.start`, `setTimeControl`, `setBot`) |
| Seated player | Takes a free seat in the lobby (`room.seat`); auto-seated on join while seats are free | Ready, move, premove, drop, resign, offer / accept draw, team quick chat | `ErrorCode.notSeated`, `notYourTurn`, `illegalMove`, `seatTaken`, `roomFull` |
| Spectator | Joins with `spectate: true`, joins a room already playing, or gives up a seat | Watch both boards, room chat, rematch vote is ignored | Team-scoped chat is not delivered to spectators |
| Bot | Host adds it to a seat | Plays deterministic moves server-side | Never receives messages; cannot be host |
| Reconnecting player | Presents the `resumeToken` from `hello.ack` | Reclaims the same seat within `reconnectGraceMs` | Unknown / expired token yields a fresh identity |

Session identity is a server-generated player id plus an opaque resume token
sent only to that socket; no secret is persisted in evidence. Direct API
access is limited to `GET /healthz`, `GET /rooms/<code>` (room snapshot
without tokens) and — only when the server runs with `--test` — the
`/test/*` channel, which is documented as a development-only surface.

Verified by `server/test/server_test.dart` (reconnection with resume token,
illegal move / wrong turn errors, chat flood guard, bots filling seats), by
code inspection of the `notHost` / `notSeated` guards listed above, and by the
four-platform run where the web host starts the match and iOS and Android
relaunch as spectators.
