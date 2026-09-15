# Iron Relay protocol v1

WebSocket text JSON, port 8769. Local guest rooms use `[A-Z0-9]{4,8}` codes.
The first guest creates a room; the second joins it. At most 32 rooms, 2 players
each, 8 KiB per message, 100 messages/second per socket. No clients can set health,
position, time, scores, active fighter or winner directly.

## Client → server

```json
{"type":"join","code":"IRON","name":"Alpha","team":[0,1],"token":""}
{"type":"ready"}
{"type":"input","seq":1,"action":"move","x":1,"z":0}
{"type":"input","seq":2,"action":"guard","down":true}
{"type":"input","seq":3,"action":"punch"}
{"type":"input","seq":4,"action":"kick"}
{"type":"input","seq":5,"action":"launch"}
{"type":"input","seq":6,"action":"tag"}
{"type":"rematch"}
{"type":"ping","sent":123}
```

Roster indices: 0 Kade, 1 Nyx, 2 Atlas, 3 Sora. Teams have two distinct indices.
Names are trimmed to 16 characters. Invalid teams become `[0,1]`. The peer ID is
assigned server-side and bound to the socket. IDs supplied in input are ignored.
An integer `seq` must exceed that peer's last accepted sequence; duplicates and
reordered old packets are ignored. The native client serializes all sends.
Movement values are finite/clamped to [-1,1]. A held input expires after 24 frames
unless refreshed. Unknown actions do not mutate combat.

## Server → client

```json
{"type":"welcome","id":"uuid","token":"opaque-private-rejoin-token","code":"IRON","seq":-1}
{"type":"error","message":"Room full. Choose another code."}
```

`state` broadcasts at 20 Hz:

- `tick` is the authoritative 60 Hz monotonic simulation tick.
- `phase`: lobby → countdown → fight → roundEnd → countdown/result.
- `paused`: at least one peer is offline. Combat time/physics pause.
- `remaining`, `countdown`: remaining frame counts.
- `round`, `winner`, `roundWinner`: authoritative match outcome.
- `players`: both public peer states (IDs, names, selected teams, connection/ready,
  separate health/red arrays, active reserve index, position, attack and age,
  cooldown, guard/stun/air state, combo and wins).
- `events`: last 24 numbered events; clients deduplicate IDs for particles/audio.
  Includes join/disconnect, attack, hit, block, launch, juggle, tag, land,
  wall, round, fight, ko, victory, rematch, forfeit.

The snapshot never contains reconnect tokens. A reconnect sends the welcome token
in a new `join`; the player ID, sequence history and match state are retained.
An already connected identity cannot be replaced by another socket. All combat
pauses on a disconnect; rejoin is allowed for 60 seconds. After expiry, the
remaining player gets a forfeit. Empty rooms expire after 120 seconds.

## Combat

Simulation integrates fixed-size frame steps (real-time cadence is subject to
host scheduling). Attack startup/end/range/width/damage/stun are centralized in
`MOVES`. `punch → cross → finisher` depends on timely P,P,K input. The attack's
target depth is captured at startup, allowing sidestep; K has wider coverage.
Guard chips two health but cannot KO. A successful launcher creates vertical
velocity; subsequent air hits have reduced damage and are capped at three.
Launch can cancel into Tag after its active frame. Tag is otherwise unavailable
during attack/stun/air time and has a four-second cooldown.

Resting health restores only up to the red-life cap. Any active knockout loses a
round, consistent with Tag 2's documented risk; first to two rounds wins.
Timeout compares both fighters' combined remaining life; equality draws and
starts another round. Server state is in-memory and ephemeral.
