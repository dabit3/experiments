# Prism Sixteen protocol v1

JSON text frames over `ws://host:43116`. No identity provider. Limit two players
per room, 100 rooms per server, 4096-byte input frames, 120 messages/second/peer.
Server clock is Unix seconds. Client ping clocks use monotonic uptime seconds.
Every connection owns exactly one peer; `playerID` in a tap is neither needed nor
trusted.

## Client → server

```json
{"type":"create","name":"NOVA","playerID":"device-uuid","code":"P16A"}
{"type":"join","name":"ECHO","playerID":"other-device-uuid","code":"P16A"}
{"type":"ping","sent":123.4}
{"type":"select","songID":"refraction","difficulty":"ADVANCED"}
{"type":"ready","ready":true}
{"type":"tap","round":1,"seq":7,"cell":15,"at":1780000000.5,"source":"touch"}
{"type":"leave"}
```

Create's code is optional (normal UI gets a random six-character code). Codes are
4–6 uppercase letters/digits. Join of an existing player requires the returned
`token`; names and IDs alone cannot replace another player. An authenticated
replacement closes the earlier connection. `lastSequence` in welcome allows a
restarted client to continue its sequence safely.

Host-only `select` is accepted outside play and resets both ready flags. Both
connected peers must ready. The server then increments `round`, clears each
performance and publishes `startAt = now + 4`. Both clients have the same bundled
chart. All sixteen cells (0–15, row-major) accept separate inputs including chords.

`seq` must increase monotonically. Wrong rounds, invalid cells, stale/replayed
inputs and timestamps outside `[receipt − 250ms, receipt + 60ms]` cannot score.
Within that receipt envelope the server finds the nearest unjudged note on that
cell and applies the ±45/90/140ms windows. Unplayed notes become misses after
400ms, allowing arrival latency without accepting old timestamps indefinitely.
The `source` field labels evidence as touch/driver and does not alter judgment.

## Server → client

- `welcome`: `id`, random rejoin `token`, `code`, `lastSequence`.
- `pong`: echoed `sent`, `serverTime`.
- `state`: `serverTime`, `room` with `code`, `hostID`, `phase`, `songID`,
  `difficulty`, `round`, `startAt`, and complete public `players`.
- `judgment`: immediate owning-peer feedback: `cell`, `noteID`, `label`, signed
  `error` seconds, server receipt `at`, and `source`.
- `error`: human-readable `message`.

Each public player has `id`, `name`, `connected`, `ready`, `score`, `combo`,
`maxCombo`, weighted `accuracy`, normalized `shutter`, `perfect`, `great`, `good`,
`miss`, `ghost`, map `judged`, and last judgment. Private tokens never appear in
public room state or server logs.

## Timing / recovery

Clients ping every 500ms. Server offset is estimated at the midpoint of the
lowest-RTT ping in a 15-second window. Readiness requires at least three samples.
Native audio is scheduled against `AVAudioPlayer.deviceCurrentTime` using the
shared epoch; drawing and touch timestamps use that same epoch. A positive
calibration subtracts a user-selected input delay.

Unexpected disconnects retain slot/token/performance and clear readiness.
The match does not pause; misses and results remain authoritative. The client
reconnects after two seconds. On rejoin it seeks audio to the current elapsed time.
Disconnected rooms are reclaimed after 120 seconds. Explicit leave removes a
player outside a running match and transfers host to the remaining guest.

The server emits JSON-lines `join`, `start`, `hit`, `disconnect`, `result` events
with room, round and peer identities. These are evidence, not client controls.
There is no debug command to set score or force an outcome.
