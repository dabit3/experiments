# Sewer Strike protocol v1

Transport: plain WebSocket over local TCP, default port **8767**. All packets are
UTF-8 JSON objects. Server ticks at 30 Hz with a fixed 1/30 second simulation step.
There is no HTTP game/control endpoint, identity provider or score submission API.

## Client → server

```json
{"type":"hello","name":"Alpha","hero":0,"create":true,"code":"STRIKE"}
{"type":"hello","name":"Bravo","hero":2,"code":"STRIKE"}
{"type":"hello","token":"<previous random resume token>"}
{"type":"ready"}
{"type":"input","seq":42,"dx":1,"dy":0,"action":"attack"}
{"type":"rematch"}
{"type":"ping","client":123}
```

- `hero`: integer 0…3. Duplicate hero selections rejected. Name trimmed to 16
  characters. Code: 4…6 alphanumeric uppercase characters; blank create generates
  six hex characters. Joining a missing/full/running room is rejected.
- `ready` toggles readiness in lobby. At least two connected guests and unanimous
  readiness start a 90-tick countdown.
- `input`: strictly increasing safe-integer `seq`; finite `dx/dy` normalized to a
  unit vector; optional `action` is `attack`, `jump` or `special`.
  Native heartbeat is 20 Hz, even at rest. The server maps the socket to its own
  player identity and ignores any claimed identity in the input. It consumes a
  bounded action queue in arrival order during the next tick. Cooldowns, range,
  lanes, jumping, immunity and meter are server rules. Missing input for 350ms
  neutralizes movement. Maximum 90 packets/second per connection and 4096 bytes
  per message. State backpressure is bounded to 1MB per connection.
- `rematch`: valid only at clear/gameover. All connected players (minimum two)
  must vote. Reinitializes combat stats and map while preserving guest identity.

## Server → client

```json
{"type":"welcome","id":"<UUID>","token":"<192-bit random token>","code":"STRIKE","resumed":false}
{"type":"error","message":"That hero is already selected"}
{"type":"pong","client":123,"tick":501}
```

`state` is broadcast identically to all connected room peers each tick:

```text
type, code, tick, match, phase, sector, sectorName, gate,
startAt, elapsed, banner, defeated, waveClear,
players[], enemies[], pickups[], events[]
```

Phases: `lobby → countdown → playing → clear | gameover`; rematch returns to
countdown. Match is monotonic within the room. Tick never resets on rematch.

Player fields: `id,name,hero,connected,ready,rematch,x,y,z,vz,face,hp,power,score,
hits,combo,action,actionTime,attackCD,comboTime,invuln,down,revive,seq,stats`.
Stats include `attacks,jumps,specials,damage,revives,distance`.
Position is centimeters: `x` stage progress, `y` belt lane, `z` jump altitude.
The renderer maps `x/100, z/100, y/100` to SceneKit world coordinates.

Enemy fields: `id,kind,x,y,hp,maxHP,face,action,timer,stun,attack,targetX,targetY,vx`.
`kind`: grunt, drone, brute or boss. `windup` locks a telegraphed ground target;
the subsequent strike checks current human positions and altitude. These are
explicitly server-controlled AI enemies, not pretend networked humans.

Pickup fields: `id,x,y`. Events: `id,tick,kind,x,y,text,player`, a rolling last-40
event window; clients deduplicate by monotonically increasing event ID and ignore
stale animations on reconnect. They never derive gameplay health from effects.

## Recovery and limits

Tokens are sent only to their own client, never broadcast or written to match
logs. Reconnecting with a valid token retains ID, hero, score, health and match.
A new transport resets the accepted input sequence. A replacement connection
closes the old one; its subsequent close callback cannot disconnect the new
socket. Offline heroes do not act or take enemy aggro. A match with no connected
guests pauses simulation progress. An all-down connected crew loses.

Room capacity four, server capacity 64 rooms, idle cleanup ten minutes. The
process stores rooms and resume tokens in memory. Restart loses them. Guests are
trusted local users; possession of a token grants that guest role. Use only on a
trusted LAN, or add authenticated TLS hosting before Internet use.

Read-only HTTP: `GET /health`, `GET /rooms/CODE` (same state, without secrets).
