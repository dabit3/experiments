# Rift Requiem network protocol v1

Transport: UTF-8 JSON over WebSocket. Default port **8787**, configurable with
`PORT`. The app accepts editable `ws://` / `wss://` addresses. HTTP on the same
port returns a health object. Intended for local/LAN play, not a hosted service.

## Client → server

```json
{"type":"join","name":"Aria","style":"vesper","code":""}
{"type":"join","name":"Bram","style":"rook","code":"A1B2C3"}
{"type":"join","token":"opaque-secret-from-welcome"}
{"type":"ready"}
{"type":"input","seq":1,"action":"move","value":1}
{"type":"input","seq":2,"action":"guard","value":1}
{"type":"input","seq":3,"action":"jump"}
{"type":"rematch"}
{"type":"leave"}
```

Empty code creates a random six-character room. A nonempty code must already
exist. Rooms contain at most two players, server at most 100 rooms. Names have
16-character maximum. Allowed fighter IDs: `rook`, `vesper`.

`welcome` contains `{type,id,token,code,seq}`. A UUID is a player identity;
the independently random 192-bit token permits reconnection. Tokens are not in
state snapshots or evidence logs. An already-connected token cannot be taken over.
The native client keeps tokens only in memory; app termination creates a new guest.
Leaving a room or dying without reconnection retains the slot for the grace period.

Ready is idempotent. Both guests must ready. There is no AI opponent on the server.
`input` sequence must be strictly increasing per guest. `move` accepts -1, 0, 1;
`guard` accepts 1 for held / 0 for released. Discrete action names: `jump`, `dash`,
`slash`, `heavy`, `special`, `cancel`. The queue is capped at eight pending actions.
The native send queue preserves order. Messages are limited to 4096 bytes;
more than 120 messages per second closes the sender.

## Server → client

30 Hz snapshots carry `{type:"state",code,tick,phase,round,seconds,countdown,
winner,roundWinner,paused,matches,players,projectiles,events}`.

Each player has identity/name/style/slot, connectivity, ready/rematch votes,
health, meter, wins, position/velocity/facing, animation pose, current attack/frame,
stun/dash/slow counters, and highest processed input sequence. Snapshots exclude
input queues. `events` is a rolling window of 20 monotonically numbered effects:
jump, dash, airdash, attack, projectile, hit, block, cancel, round, start, finish.
Clients deduplicate by event ID. Hit events include attacker, damage, combo and
counter flag. Events and snapshots are authoritative, not client score claims.

60 fixed simulation ticks per game-second. Each tick processes ordered input,
movement, hitboxes and projectile sweeps; snapshots every other tick.
Native rendering interpolates positions, animates articulated shapes at the
display rate, and drives particles/audio from events. There is no rollback or
client movement prediction; LAN latency is expected.

Phase graph: lobby → countdown (150 ticks) → fight (60 seconds) → roundEnd
(180 ticks) → countdown, or result at two round wins. A timeout compares health.
Equal health draws without adding wins. The match ends at two wins; simultaneous
equal-health KOs can produce an extra round. Both result rematch votes reset all
health, meters, wins and round number; `matches` increments.

Guard faces the opponent and reduces damage to two chip. Attacking prevents
guard. Counter hits increase damage 20%. Rook's attack ranges are 150/210;
Vesper receives +20. Specials emit a travelling projectile. Each jump allows one
air dash. Meter starts at 25, rises with advance/hits/blocks. Neutral cancel costs
25 (yellow), recovery cancel costs 50 (red after hit, purple on whiff), and causes
25/45 ticks of half-speed opponent action. Unavailable actions are ignored.

A disconnect pauses the duel, clears held movement and guard, and allows 30
seconds for token reconnection. After grace, a connected opponent receives the
forfeit result. A departed opponent cannot vote rematch; leave and create a new
room in that case. Empty rooms are deleted. Guest state is memory-only; server
restart invalidates rooms. Reconnect retries are bounded in the app.

## Automation is input, not a separate simulation

Launch `-auto 1 -evidence 1` enables a visibly labeled local input driver. Each
app runs its own driver and sends the same `input` messages as touch controls;
neither driver can set health, score, velocity or outcomes. The first ten seconds
exercise movement/jump/airdash/guard/specials; later pressure uses attacks/cancels.
Slot 0 applies more pressure so recordings reach an outcome promptly. Both are
explicitly automated guest peers, not secretly substituted human opponents.
The driver votes rematch five seconds after receiving a result.

Evidence launch mode writes full received snapshots to Documents/network.jsonl
and the latest snapshot to Documents/state.json. Use `scripts/assert-evidence.py`
to compare both logs. A test runner must additionally inspect and record the UI.
