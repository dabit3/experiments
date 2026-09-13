# Orbital Versus network protocol v1

Transport: JSON UTF-8 WebSocket messages to `ws://HOST:8787`. `/health` is the only
HTTP route. No scores/HP/positions from clients are accepted. One Node process
owns all rooms in memory; restarting the server ends its matches.

## Join / reconnect

```
C → {"type":"join","name":"ALPHA","code":"ORBIT"}
S → {"type":"welcome","id":"UUID","token":"opaque 192-bit rejoin token","code":"ORBIT"}
```

Code is 4–8 alphanumeric characters, case insensitive. Blank creates a random
six-character code. A supplied unused code creates that room. First two guests
become opposing team pilots, with one AI wingman each. A third is rejected.
Names are trimmed and limited to 16 characters. There are at most 100 rooms.

Reconnect uses the same join shape plus `token` and the original `code`.
The token is sent only to its owner, never in snapshots or logs. It stays in native
memory. Reconnect preserves player ID, team, damage and round; resetting the
sequence counter starts a new connection input epoch. An already connected token
is rejected. At disconnect inputs clear immediately; the suit remains targetable.
After 60 seconds a live match becomes a forfeit. Empty rooms are reclaimed;
abandoned lobbies close to prevent an occupied ghost seat.

## Ready, input, rematch

```
C → {"type":"ready"}
C → {"type":"input","seq":123,"x":0.3,"z":-0.5,"boost":true,"guard":false,
     "actions":["fire","lock","dodge","melee","burst"]}
C → {"type":"rematch"}
```

Only two **connected humans** voting ready launch the match. Both votes are
required again at the result screen for rematch. Each start resets unit stats,
ammo, charge, costs and projectiles; round increases.

Input is 30 Hz, ordered by monotonically increasing integer `seq`; duplicate
and out-of-order inputs are discarded. World x/z are finite normalized vectors.
Up to four discrete action requests per packet are retained, with a bounded
12-action queue and four actions processed per simulation tick. Cooldowns,
ammo, range, boost and invulnerability are server validated. Controls, XCTest
touches and the labeled local autopilot all use this identical message path.
No server-side test victory/teleport/damage commands exist.

## Simulation and snapshots

The authoritative simulation is fixed 1/30-second steps. AI is deterministic.
Every two ticks (15 Hz) every room peer receives the same `state`:

- `code, phase, round, tick, time, countdown`
- `costs[2], winner` (`-1` draw/unresolved), `reason`
- `ready[], rematch[]` (human IDs)
- `units[]`: identity/team/AI, position/orientation, HP, boost, ammo, burst,
  animation state, current target, connection, damage/kills/action counters
- `projectiles[]`: ID, owner/team, target, position, velocity, lifetime
- `events[]`: most recent 32 monotonically identified fire, hit, saber, step,
  destruction, burst, guard and respawn events

Native rendering smooths suits/camera toward snapshots and never predicts damage.
Beam collision uses swept segments; short initial aim assist tracks unless the
target steps. Hits ignore friendlies, invulnerability and phase-step windows.
Human HP 520/cost 2000; AI HP 360/cost 1500. Teams have 6000 cost. Death respawns
after 2.5 seconds with 1.8 seconds protection; insufficient remaining cost scales
respawn armor. Zero team cost ends immediately. At 90 seconds, higher remaining
team cost plus current armor wins; exact equality draws.

Movement: ground 9 units/s; boost 24, drains 27/s and rises to 13 units. Release
falls at 10/s. Ground refills 46/s (28/s when overheated until fully recovered).
Step costs 24, translates 5 and gives 0.24 s invulnerability, cancelling recovery.
Rifle: seven rounds, one reloaded per 1.35 s, 65 damage. Saber: lunge under 19m,
hit under 5m, three strikes 70/70/105. Overdrive activates at 50 charge, resets
boost, and grants 7 s enhanced damage/speed/fire rate. Guard slows movement and
reduces damage to 28%; it is omnidirectional in this adaptation.

Payloads are limited to 4 KiB, input rate to 90 messages/s, queued socket writes
to 256 KiB. Slow clients miss snapshots, not authoritative ticks. Errors return
`{"type":"error","message":"..."}`. `ping` echoes `sent` in `pong` for RTT.

## Local trust boundary

This is an unauthenticated local/LAN game server. Rejoin tokens are not user
accounts. The iOS app allows non-TLS local sockets and exposes an editable address.
Only connect to trusted hosts. Internet hosting, TLS termination, persistence,
spectators, NAT traversal and hostile-network hardening are outside this build.
