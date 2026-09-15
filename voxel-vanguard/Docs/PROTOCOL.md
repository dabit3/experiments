# Voxel Vanguard protocol v1

Transport: UTF-8 JSON over RFC6455 WebSockets, port **8791**. Guest names and
room codes require no external identity. Maximum payload: 2048 bytes. Maximum
client messages: 100/second. The host sends ping frames every five seconds and
terminates peers missing the previous pong.

## Join

```json
{"type":"hello","name":"Aster","create":true,"code":"GROVE"}
{"type":"hello","name":"Bramble","code":"GROVE"}
```

Names are trimmed and bounded to 16 characters. Codes contain 4–8 uppercase
letters/digits. An omitted creation code produces a random six-digit hex code.
At most 64 rooms exist; each accepts exactly two players and no mid-match new
player. A duplicate room, missing room or full room returns
`{"type":"error","message":"..."}`. Retrying a hello after an error is supported.

```json
{"type":"welcome","id":"server-generated-uuid","token":"opaque-resume-token","code":"GROVE","seq":-1}
```

Keep the token on the client only. It is never in snapshots, the HTTP observer or
state evidence. A reconnecting client sends `{"type":"hello","resume":"TOKEN"}`.
The server replaces the old socket, preserves that player's state/slot/identity
and reports the highest accepted input sequence. An old socket closing after
replacement cannot disconnect the resumed peer.

## Lifecycle and input

`{"type":"ready"}` toggles readiness in lobby or result phase. Exactly two
connected ready players start a new round. Round resets preserve identity and
sequence order while resetting encounter, health, inventory, score and counters.

```json
{"type":"input","seq":102,"x":0.8,"z":-0.3,"action":"melee"}
{"type":"input","seq":103,"x":0,"z":0,"action":"equip","choice":"guardian"}
```

- `seq` is a monotonically increasing safe integer for the resumed identity.
- `x,z` are finite world movement axes, clamped to [-1,1], vector normalized.
- Actions: `move`, `melee`, `ranged`, `dodge`, `heal`, `revive`, `artifact`, `equip`.
- Every ordinary touch and automated action uses this same message path.
- Only the server changes health, damage, inventory, score, enemy state or victory.
- Input packets are processed in WebSocket order. Movement is integrated at 20Hz.
- Stale movement expires after eight ticks. Closed peers have input zeroed.
- Revive is continuous: refresh the action while holding; range and elapsed time
  are checked by the server, and interrupted progress decays.
- Equip requires proximity to an available chest. Claims are per-player,
  synchronous and once-only. Invalid gear/remote claims do nothing.

`{"type":"leave"}` removes the player and ends an active expedition in defeat.
Disconnected peers remain reconnectable until the room is expired. During a
disconnect, the server tick/heartbeat continues but simulation is paused.
All-disconnected/empty rooms and their resume tokens expire after 120 seconds.

## Authoritative snapshots

Each socket gets its room's complete state every 50ms:

```text
type: "state"
code, phase: lobby|playing|victory|defeat, round, tick, stage: 1..3
completedStages: 0..3, objective, paused
players[]:
  id, name, slot, connected, ready, x, z, angle, hp, maxHP, down, revive
  weapon, bow, armor, gems, kills, score, charge
  action, attack/shot/dodge/potion/invincible absolute cooldown ticks
  seq, input, lastInput, stats{melee,ranged,dodge,heal,revive,hits,equipment}
enemies[]: id, kind, x, z, angle, hp, maxHP, action, telegraph
projectiles[]: id, owner, x, z, vx, vz, life, damage
loot[]: id, kind: gem|chest, x, z, claimed? [player IDs]
events[]: id, kind, x, z, text, tick
```

Snapshots are isolated by room. Events last 30 ticks; clients deduplicate event
IDs. Projectiles travel and collide on the server. Dead enemies disappear from
snapshots. Clients interpolate actor transforms but do not predict hits or
outcomes. No server randomness affects combat: enemy composition/spawns and tick
rules are authored and deterministic given ordered inputs.

## Observation and testing

`GET /health` reports process health. `GET /rooms/CODE` returns the same public
room state for local test assertions. Neither endpoint accepts writes.
`LOG_PATH=/absolute/existing/directory/server.jsonl` records timestamped room
snapshots every four ticks. Native clients separately record the snapshots they
actually received plus manual/automated control events. Compare code, round,
tick, full player IDs, statistics and outcome across peers.

The service is intentionally a local development/LAN server. Do not expose it
publicly without an authenticated room policy, encrypted transport and suitable
operational limits. There are no persistence or production availability claims.
