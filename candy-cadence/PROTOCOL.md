# Candy Cadence protocol v1

JSON UTF-8 over a persistent WebSocket on port 8789. Maximum frame payload 4096
bytes and 90 incoming commands/second/connection. All input is processed in arrival
order in Node's event loop; sequence numbers suppress replays per player.

## Client commands

| type | Fields | Behavior |
|---|---|---|
| `hello` | `create`, `room`, `name`, `automated` | Create a random six-character room or join one; 2-seat cap |
| `hello` | `room`, `playerID`, `token` | Rejoin a disconnected reserved seat; token must match |
| `ping` | `sent` (Unix milliseconds) | Clock sample |
| `select` | `songID`: `sugar` or `soda` | Host-only lobby action; clears readiness |
| `ready` | — | Toggle readiness; two connected ready peers start together |
| `hit` | `lane` 0…8, `sequence`, `time` | Timestamp must be within 220 ms of server receipt; nearest unjudged note in that lane within 180 ms |
| `rematch` | — | Only after results; resets both players and returns to lobby |

Names are trimmed, sanitized and limited to 16 characters. IDs/tokens use random
UUIDs. An already connected seat cannot be hijacked, even with a valid token.
No player can post a score, judgment, note ID, outcome or arbitrary chart.

## Server messages

- `welcome`: `playerID`, private `token`, `room`. Token is never broadcast/logged.
- `pong`: echoes `sent`, includes `serverTime`.
- `error`: human-readable `error`.
- `state`: `room`, `phase` (`lobby`, `playing`, `results`), `songID`,
  `startAt`, `serverTime`, `match`, `hostID`, `players`.
- Each peer includes ID, name, connection/readiness, score, combo, maxCombo, groove,
  judgment counts, judged note IDs, last verdict/lane/delta/event, and automation
  disclosure. Neither private token nor socket is included.

The server broadcasts state immediately after commands and every 50 ms while
playing. It advances overdue notes to MISS regardless of connection or input and
ends the match at the authored song duration. Both receive the identical final
player array. Disconnection never freezes the opponent's song.

## Clock and audio

Clients collect 12 rapid ping samples, then maintain a 1.5 s ping. The lowest RTT
sample estimates `offset = serverTime - (sent + received)/2`. Gameplay uses
`Date.now + offset`; start is scheduled four seconds in the future. AVAudioPlayer
uses its device clock to schedule audio at the same epoch; on reconnect it seeks
to elapsed song time. Note travel is derived from absolute song time, not frame
counts, so dropped frames do not drift the chart. A two-second count-in is part of
the 120-BPM WAV. User calibration shifts input timestamps only.

The labeled driver uses this same clock, the same `hit` function, the same ordered
input messages and server validation. It does not introduce a server-side bot.

## Lifecycle

Rooms cap at 100. Once two players are present, a third cannot join. Rejoin requires
the seat's token. All-disconnected rooms expire after 120 s; active matches finish
normally. State is ephemeral, and a server restart invalidates room codes. Rematch
is accepted only in results and clears scores, judgments and ready flags for both
peers. The host continues to select songs. Clients can leave and create a new room
when a partner permanently departs.
