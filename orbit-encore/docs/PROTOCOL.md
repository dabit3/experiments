# Orbit Encore protocol v1

Transport: JSON over WebSocket at `ws://HOST:8788`. Server listens on all local
interfaces for LAN play. `GET /` returns status/room count. No cloud deployment.
Pinned `ws` dependency and lockfile; max frame payload 4096 bytes, per-connection
limit 240 messages/second; at most 100 rooms and exactly two guests per match.

## Connection and room lifecycle

Client → server:

```json
{"type":"join","name":"Nova","room":"","token":""}
{"type":"ping","sentAt":1789308000123.45}
{"type":"select","songID":"sugar"}
{"type":"ready","ready":true}
{"type":"rematch"}
{"type":"leave"}
```

Empty `room` creates a random six-character hex code. Joining an unknown or full
room errors. Server assigns a random independent player ID and a 192-bit random
rejoin token. `joined` contains `id`, `token`, `room` and complete `charts`. Only
the first player can select charts in lobby; selection clears both ready states.
Rejoin with the token requires the original socket to be disconnected and
preserves performance/identity. The app retains its token in memory.

`pong` echoes `sentAt` and sends server epoch milliseconds. The client samples
every 400ms and uses the minimum-RTT sample to estimate server − local offset at
the RTT midpoint. Local time derives from monotonic uptime plus an epoch anchor.
Both ready + both connected schedules `startAt = serverNow + 5000ms`. This
increments `matchID`. Native audio is scheduled once on the audio device clock
using that epoch. A late rejoin seeks audio to the current chart position.

## Gameplay input

```json
{"type":"input","matchID":1,"seq":19,"at":1789308000123.45,
 "pointer":3,"phase":"move","x":0.31,"y":-0.65}
```

`at` is the estimated server epoch time when the input was made, accepted within
300ms of server receipt. `seq` must monotonically increase per player. `matchID`
rejects old-round input. Coordinates are normalized around playfield center
(x right, y up); target radius 0.82, lane angle π/2 − (lane+0.5)π/4. Input
coordinates must be finite and within ±1.25. `phase` is down/move/up and pointer
is an integer finger identity. Moves require a held pointer. Touch-began and
touch-moved use this same schema as the explicitly labeled automated driver.

Server matches downs to nearest pending note within ±160ms and a 0.28-radius
target area. Holds retain finger identity and enforce continuity/lane distance.
Slides retain finger identity and advance only ordered path checkpoints, with
timed completion. The server never accepts client-declared scores or judgments.
Events are processed in WebSocket order; timestamps cannot go backward >3ms.
The tick leaves a 300ms admission buffer before expiring missed notes.

## Server snapshots

`state` is broadcast on room changes and every 33ms while playing:

```text
type, room, phase[lobby|playing|results], songID, startAt, serverTime, matchID,
players[{
  id, name, ready, connected,
  score, combo, maxCombo, accuracy, judged,
  counts{PERFECT,GREAT,GOOD,MISS},
  lastJudgment{id,text,at,lane}?,
  notes[{state[pending|active|done],checkpoint,judgment}]
}]
```

The two peers receive the same ordered player/performance state. The app selects
its own state by server-assigned ID. `accuracy` is accumulated achievement against
the whole chart denominator. At `duration + 0.5s` the server finalizes results;
highest score wins, equal scores draw. Both `rematch` requests reset readiness/
scores and return to the lobby. Guests then may select another track and ready.

Disconnect clears held fingers and readiness, allowing remaining notes to miss
while the shared song continues. Automatic reconnect uses the same token. An
explicit Leave during a match counts as disconnect (results still settle).
All-disconnected rooms expire after 120s. In-memory state does not survive a
server restart. This is a trusted LAN protocol: bounded timestamp trust is
latency tolerance, not robust protection against a malicious client.

Server stdout JSON events (`join`, `start`, `judgment`, `disconnect`, `results`,
`rematch`) deliberately omit secret rejoin tokens. App telemetry similarly omits
tokens and records human/automated input source for test evidence.
