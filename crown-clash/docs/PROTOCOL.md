# Crown Clash wire protocol

Endpoint: `ws://HOST:8767`. UTF-8 JSON text messages, maximum 4096 bytes.
No accounts. A room admits exactly two distinct guests. Health, movement, meter,
damage, active fighter, timer, phase and winner are server-owned.

## Join and ready

```json
{"type":"hello","id":"alpha","name":"ALPHA","code":"CROWN1","create":true,"roster":["rook","vesper","atlas"]}
```

`id`: 3–80 letters/digits/underscore/hyphen. `code`: 4–8 alphanumeric characters,
normalized uppercase. A blank host code creates a random six-character code.
`roster`: three different IDs from rook, vesper, atlas, sora, kestrel, jin.
The second peer sends the same shape with `create:false`.

```json
{"type":"welcome","id":"alpha","token":"opaque-resume-token","code":"CROWN1","ack":-1}
{"type":"ready","roster":["rook","vesper","atlas"]}
```

Both peers must be connected and ready before the server starts the countdown.
Invalid requests receive `{"type":"error","message":"..."}`. Third guests are
rejected. Tokens are private to their owner and absent from snapshots/logs.

## Input

```json
{"type":"input","seq":42,"move":1,"guard":false,"crouch":false,"run":true,"action":"punch"}
```

`seq` is a strictly increasing safe integer per guest, retained across reconnects.
Stale/duplicate sequences are ignored. `move` is -1, 0 or 1. Held inputs and one
optional action share a packet. Actions: hop, jump, roll, punch, kick, heavyPunch,
heavyKick, special, super. Unknown actions become no-op. The queue is capped at
eight; held controls time out after 30 simulation ticks without input. Native
clients send held controls at 20 Hz and actions immediately. The server closes
sockets exceeding 150 messages per second.

## Authoritative snapshots

The simulation runs at nominal 60 Hz and broadcasts at nominal 30 Hz.

```text
state {
  code, tick, phase, match, round, timer, wait, winner, paused,
  peers: [{
    id, name, roster:[{fighter,hp}, ...], active, connected, ready,
    x, y, face, pose, meter, guard, guarding, crouch, combo, ack,
    damage, knockouts, rematch
  }],
  projectiles:[{id,owner,x,y,direction,super,fighter}],
  events:[{id,tick,kind,...}]
}
```

Phases: lobby → countdown → fight → transition → countdown (next fighter) or
result. `active` indexes the ordered roster; 3 means eliminated. `timer` is
remaining whole seconds; `wait` is remaining countdown/transition ticks.
Winner is a peer ID or `draw`. A result occurs only when a peer has no members left.
Peers see the same world coordinates; both screens keep player one on the left.
`paused` is true when a guest disconnects. Event IDs increase within the room;
the latest 40 events accompany every snapshot and clients deduplicate by ID.

Events include joined, ready, countdown, fight, hop, jump, roll, attack, cancel,
hit, guard, guardBreak, ko, replacement, result, rematchVote, rematch,
disconnected, reconnected.

## Rematch and reconnect

```json
{"type":"rematch"}
{"type":"hello","id":"alpha","code":"CROWN1","create":false,"token":"previous-token"}
```

Both rematch votes reset the rosters/health/meter, increment `match`, and begin a
new countdown. Reconnect keeps the prior roster, active member and combat state.
The peer's input queue/held controls are cleared. `welcome.ack` tells the client
where its sequence must resume. A valid reconnection replaces any previous socket
for that identity; closing that old socket cannot disconnect the new one.
The client retries unexpected connection losses while it retains its token.
Leaving the room discards the token and identity continuity is no longer promised.

Rooms are in memory, capped at 32, and expire after all peers have been
disconnected for 60 seconds. The application does not deploy a public service.
