# Hollow Afterdark wire protocol v1

Transport: UTF-8 JSON in WebSocket text frames. Default port 8787. `ws` is pinned
to **8.21.3** (published 7 August 2026; lockfile checked in). Server limits:
4096-byte messages, 150 packets per second per connection, 16 rooms, two identities
per room. WebSocket ping/pong detects dead connections every 10 seconds.

## Client → server

```json
{"type":"join","room":"NIGHT","name":"Ren","id":"","token":""}
{"type":"ready"}
{"type":"input","seq":41,"held":{"left":false,"right":true,"guard":false,"shield":false},"press":"light"}
```

Room codes are 4–8 ASCII letters/digits, normalized uppercase. Names are trimmed,
limited to 16 characters and rendered as text. Only the server creates peer IDs.
For reconnect send the prior welcome's ID and private token, using the same room.
An occupied room rejects an invalid token instead of granting the existing slot.
Rejoining replaces an old socket for that identity.

`ready` only applies in lobby/result, setting the caller's consent flag. Both
connected identities must consent. `input.seq` must be a safe integer strictly
greater than the last accepted sequence for that identity. Duplicate/older
messages are ignored. All held flags are explicit booleans. Missing/false flags
release controls. Server expires held input after 90 ticks without another
input packet. Client resends held state at 10 Hz, sends touch changes immediately.

`press`: `jump`, `light`, `heavy`, `special`, `ex`, `throw`, `shift`, or empty string.
Cost, state, range and frame legality are checked server-side. No position,
health, winner or meter update message exists. Input drives only its own socket's
identity. Disconnect freezes combat; a disconnected input cannot run combat.

## Server → client

```json
{"type":"welcome","id":"server UUID","token":"private resume token","room":"NIGHT","seq":40}
{"type":"error","message":"This room already has two duelists."}
```

`welcome.seq` lets a relaunch continue ordered inputs. Tokens are 24 random bytes,
retained only in server memory and per-simulator UserDefaults, not broadcast/logged.

`state` snapshots contain:

- `room`, monotonically increasing server `tick`, `phase` (`lobby`, `countdown`,
  `fight`, `roundEnd`, `result`), `round`, `remaining`, `countdown`.
- `cycle` ticks until next Undertow reward, `cycleNumber`, `matchNumber`.
- `winner`, `roundWinner` server identity or empty for ties; `message`.
- Two `players`: `id`, `name`, `slot`, `connected`, `ready`, `wins`, position,
  velocity/facing, hp, meter, grd, ascend, broken, animation/action/frame,
  stun, combo, last sequence, and cumulative `stats`.
- `projectiles`: ID, owner, x/y, velocity, lifetime.
- Most recent 30 `events`: unique monotonic event ID, tick, type, owner, x/y, text.
  Clients deduplicate IDs and only animate recent events.

The server advances one deterministic simulation step every ~16.67ms; snapshots
go to both peers every second step. Tick-relative frame timing is deterministic,
but Node scheduling is not a hard realtime clock. No network prediction/rollback.
All gameplay uses simulation time, which pauses while a peer is disconnected.

Read-only HTTP `/health` is readiness; `/rooms` is current public snapshots for
local assertions. Console JSONL logs join/disconnect and gameplay events.
Neither endpoint can inject gameplay. The service is a trusted local development
server; it has no remote administration, public matchmaking or user authentication.
