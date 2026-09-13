# Protocol v1

One UTF-8 JSON object per WebSocket message. Default endpoint
`ws://127.0.0.1:8794`; HTTP `GET /health` reports readiness. No account/login.
Frames limited to 4 KiB and 150 client messages/second. Maximum 100 rooms,
two peer slots each.

## Client → server

```json
{"type":"join","code":"NITE","name":"Alpha","playerID":"","token":""}
{"type":"ready"}
{"type":"input","seq":42,"axis":1,"guard":false,"action":"light"}
{"type":"ping","sent":123}
```

`join` creates the room if absent. Code is 4–8 alphanumerics, canonical uppercase.
Names are truncated to 16 characters. Server assigns the UUID and private resume
token. Save these on that device; on rejoin pass both with the same code.
A token cannot claim another ID and is never included in shared state. A
successful resume closes the old socket. A third unauthenticated peer is rejected.

`ready` applies in lobby and match result. Both connected peers must ready; a
three-second broadcast-versus phase precedes each round. Mutual result-ready
starts a fresh match.

`input.seq` must be an integer greater than the previous accepted sequence for
that peer. Axis is finite and clamped to [-1, 1]. Guard is boolean. Valid actions:
`jump`, `light`, `heavy`, `summon`, `burst`, `super`, or empty for held-state
updates. Inputs are processed in WebSocket order. Held state expires after
30 simulation ticks without an input; action buffering is capped at three with
six-tick expiry. Inputs are accepted only during combat. Invalid combat choices
(insufficient meter, cooldown, break) do not mutate resources.

## Server → client

```json
{"type":"welcome","playerID":"uuid","token":"private","slot":0,"lastSeq":42}
{"type":"error","message":"Room has two fighters. Choose another code."}
{"type":"pong","sent":123,"now":456}
```

Snapshots have `type:"state"`, `code`, monotonic simulation `tick`, `phase`,
`phaseTicks`, `round`, `match`, remaining `time`, `winner` (player UUID or empty),
`paused`, `fighters` and a bounded replay tail of combat `events`.

Each fighter includes: `id`, `name`, `slot`, `connected`, `ready`, `wins`,
position `x/y`, `vy`, `hp`, `meter`, `cards`, `breakTicks`, `burst`, `face`,
`move`, move `frame`, `stun`, `guard`, `axis`, `companion` visibility ticks,
`combo`, `awakened`, `invulnerable`, `lastSeq`.

Each event has monotonic `id`, `tick`, `kind`, actor `player`, and optional
`target`, `damage`, `x/y`, `combo`, `cards`, `round`. Clients deduplicate by event
ID. Events include round/fight, actions, hit/block, card/break/restore,
awakening, KO and result. Rendering never owns health or hit detection.

## Simulation and failure semantics

60 Hz fixed-step simulation, 30 Hz snapshots. Attack evaluation uses the same
deterministic order on every server tick. The client interpolates presentation
but does not predict damage. This is LAN-oriented delay-based networking,
not rollback. A slow connection may skip snapshots, never action order.

Disconnect immediately clears held controls and buffers, sets the peer offline,
and freezes the room's simulation clock. Reconnect with saved ID/token resumes
the same match with the same resources and sequence. Rooms abandoned by either
peer expire after two minutes; server restart clears all in-memory rooms.
Room codes are convenience grouping, not a security/privacy boundary. Host
the server only on a trusted LAN; TLS/authentication is out of scope.
