# Local guest protocol v1

Host: `ws://<host>:8789`, JSON text WebSockets. `ws` 8.21.3 is pinned and locked.
Simulation at 30 Hz; read-only snapshots at 15 Hz, interpolation on the client.
No client message can set world state or a score.

## Messages

```json
{"type":"hello","id":"client-generated-uuid","name":"Azure","create":true}
{"type":"hello","id":"another-uuid","name":"Amber","room":"ABC12"}
{"type":"welcome","id":"client-generated-uuid","room":"ABC12","team":0,"token":"server-generated-resume-secret"}
{"type":"ready"}
{"type":"input","seq":18,"move":-1,"jump":true,"action":false,"dive":false}
{"type":"switch","slot":0}
{"type":"order","order":"military"}
{"type":"ping","sent":12345}
{"type":"pong","sent":12345,"tick":250}
{"type":"error","message":"Room full: two captains maximum"}
```

- Guest IDs are 8–64 alphanumeric/hyphen characters; names 1–18 characters.
- Room codes are server-generated random five-character hex, unique among live
  rooms. The first guest is Azure (team 0), the second Amber (team 1).
- A room has exactly two slots and only starts when both connected guests ready.
  A three-second countdown precedes the match. No late third player.
- `input.seq` must be a strictly increasing safe integer for that connection.
  Invalid/nonfinite movement, missing boolean fields, duplicates and stale
  sequences are ignored. The server clamps accepted movement to [-1, 1].
  Input only applies to that peer's selected own-team unit. Input older than
  500 ms clears to neutral.
- `switch.slot` is an integer 0–4 on the sender's team. Q is 0. Previous unit
  becomes AI; next becomes human. The client cannot select enemy units.
- `order` is `economy`, `snail`, or `military`, and applies only to sender's team.
- Ready on a result requests rematch. Both ready creates an entirely new world,
  resets scores/lives/snail/upgrades, advances `match`, and counts down again.

## State

Each connected peer gets its own envelope with `you` set to its guest ID:

```json
{
  "type":"state","you":"uuid","room":"ABC12","phase":"playing",
  "countdown":0,"paused":false,"match":1,
  "peers":[
    {"id":"uuid","name":"Azure","team":0,"connected":true,"ready":false,
     "slot":1,"seq":18,"inputs":16}
  ],
  "game":{
    "tick":150,"time":5,"phase":"playing","winner":-1,"victory":"",
    "score":[1,0],"lives":[3,3],"orders":["economy","snail"],
    "snail":{"x":480,"y":65,"rider":"","team":-1},
    "units":[],"berries":[],"gates":[],"platforms":[],"events":[],
    "deposits":[1,0],"kills":[0,0]
  }
}
```

Unit snapshots include position, velocity, facing, role, grounded, carrying,
upgrade, respawn/protection timers, gate progress and explicit `human`. AI uses
the same physics and abilities, never teleports or changes score. Server events
carry increasing IDs for deduplicated local audio/particles. Victory is one of
`MILITARY`, `ECONOMIC`, `SNAIL`; only the server resolves it.

## Disconnect/rejoin

Socket loss clears input, marks that peer disconnected and pauses the match
(including countdown and respawn clocks). Reconnect sends `hello` with the same
room, guest ID and secret `token`. Invalid tokens fail. A valid reconnect replaces
the previous socket, preserves team, selected unit and world state, and resets
input sequence tracking. The app retries every two seconds. Neither snapshots
nor HTTP telemetry include tokens. Tokens are intentionally in app memory only.

Empty rooms expire after 120 seconds. The service limits to 64 rooms, 8 KiB
messages, 90 messages/second/socket and a five-second join deadline. Slow outgoing
sockets above 256 KiB buffered output skip snapshots. HTTP health and room
telemetry are read-only. The service is designed for a trusted LAN; use WSS,
origin policy, stronger session policy and deployment rate limits before any
separately authorized public deployment.
