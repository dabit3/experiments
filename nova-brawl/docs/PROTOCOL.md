# Nova Brawl protocol v1

JSON text frames over WebSocket, default `ws://127.0.0.1:8787`. Plain HTTP on
the same port returns `{game, protocol:1, rooms}` for readiness checks.

## Client → server

```json
{"type":"join","name":"Flare","code":"NOVA26","create":true,"token":""}
{"type":"ready"}
{"type":"input","seq":1,"x":0,"z":1,"lift":0,"charge":false,"boost":true,"actions":["shot"]}
{"type":"ping","client":123456}
```

- Join is required within ten seconds. Codes are case-insensitive, 4–8
  alphanumeric characters. Trimmed names are limited to 16 characters.
- `create:true` requires a fresh code. `create:false` requires an existing room.
  At most two identities occupy a room, including temporarily disconnected ones.
- Server assigns unpredictable ID and reconnect token. Resend the token with the
  same code to reattach the **same** fighter; name does not establish identity.
  Reattachment replaces any previous connection and restarts input ordering.
- `seq` is a monotonically increasing safe integer. Duplicate/out-of-order
  inputs are ignored. Components must be finite; they are clamped to `[-1,1]`
  and movement normalized. Packet actions are bounded and allow-listed.
- `x` is strafe, `z` forward/back, `lift` vertical flight. Continuous
  `charge`/`boost` are holds. Edge actions: `melee`, `shot`, `beam`, `dodge`,
  `flight`, `lock`. The client cannot submit health, damage, position or winner.
- Holds time out after 0.5 seconds without fresh input. `ready` is valid
  only in lobby/result and requires both connected peers to start.

## Server → client

```json
{"type":"welcome","id":"<random-16-hex>","token":"<random-48-hex>","code":"NOVA26"}
{"type":"error","message":"Room is full (2 players)."}
{"type":"pong","client":123456,"server":123460}
```

Snapshot `type:"state"`:

| Field | Meaning |
|---|---|
| `code`, `round`, `tick` | Room and simulation identity |
| `phase` | `lobby`, `countdown`, `playing`, `result` |
| `countdown`, `time` | Seconds remaining, server-owned |
| `winner`, `reason` | Winner ID (empty for draw), `KNOCKOUT` / `TIME` / `DISCONNECT` |
| `paused` | A member is temporarily disconnected |
| `players` | ID/name/slot/connected/ready, health/energy, position/yaw, flight/lock, pose/combo, damage/hits/dodges |
| `projectiles` | ID/owner/position/direction for currently traveling blasts |
| `effects` | Recent ordered effect events for hits, beams, dodge, melee, joins and phases |

Positions are `{x,y,z}`; Y is altitude, ground zero. Health/energy are server
numbers. Effect `event` is monotonic within a room; clients de-duplicate it
before audio/visual playback. Each snapshot includes recent effects, avoiding
dependence on a separate unreliable effect channel.

## Timing and lifecycle

Simulation uses `DT=1/30`. State broadcasts every second tick (~15 Hz). Clients
send up to 20 input packets per second and animate the SceneKit scene at 60 Hz.
The server orders effects, applies damage and decides results. Rendering
interpolation changes only presentation.

Two ready peers → three-second countdown → 90-second match → result.
KO wins immediately; time limit compares health. Rematch requires two new
ready acknowledgments, increments round and resets fighter stats/energy/positions.

Disconnect marks a fighter unavailable and pauses countdown/match without
changing health. Rejoin within 30 seconds restores it. After that grace period,
the remaining peer wins by disconnect and the expired identity is removed.
An empty room is deleted. Server process restart does not restore rooms.

## Bounds and diagnostics

4096-byte maximum frame; 90 messages per second per socket; at most 64 rooms.
WebSocket ping/pong every ten seconds removes unresponsive sockets. These are
local-development bounds, not a full public-service abuse defense.

Stdout is JSONL with join/ready/start/hit/result/disconnect/rejoin events and
three-second combat checkpoints. Reconnect tokens are never included in this log.
Use IDs and room/round fields to correlate two device streams with the same
authoritative match. Tests use an ephemeral port and close all sockets.
