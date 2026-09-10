# Lastfort network protocol

Lastfort clients talk to one authoritative server over a single WebSocket
carrying JSON text frames. The server owns every rule outcome (movement
validation, hits, damage, building, looting, storm, eliminations); clients
predict their own movement and render server snapshots.

- Transport: WebSocket at `ws://<host>:<port>/ws` (default port `8787`).
- Encoding: one JSON object per frame. Every object has a string field `t`
  (message type). Unknown fields are ignored; unknown types answer `error`.
- Version: `Protocol.version = 1`. The `hello` message carries `v`; a mismatch
  is tolerated but the `welcome` reply includes `"warning": "version_mismatch"`.
- Tick rate: 20 Hz fixed (`Rules.tickRate`). Time inside the match is
  expressed in ticks; `dt = 1 / 20`.

The shared Dart definitions live in `core/lib/src/protocol.dart`,
`core/lib/src/input.dart` and the `toJson`/`fromJson` methods of the
simulation types in `core/lib/src/sim.dart`, `player.dart` and `world.dart`.

## Session lifecycle

```
client                         server
  |------- hello ---------------->|
  |<------ welcome ---------------|
  |------- createRoom / joinRoom->|
  |<------ roomState (repeated) --|   lobby: ready / setLoadout / setMode
  |------- startMatch (host) ---->|
  |<------ roomState(countdownMs)-|
  |<------ matchStart ------------|
  |<------ you -------------------|
  |------- input (every tick) --->|
  |<------ snapshot (every tick) -|
  |<------ matchEnd --------------|
  |------- returnToLobby (host) ->|
```

### Reconnection

`welcome.token` identifies the client session. A client that reconnects sends
the same `token` in `hello`; if the server still knows the token and the
client's room is mid-match, the server replays `matchStart` (with
`"resume": true`) and `you`, then resumes snapshots. A disconnected player
stays in the match for `Rules.reconnectGrace` seconds (60 by default) before
being eliminated with cause `timeout`.

If the token's previous socket is still open (for example a second browser tab
sharing the same local storage), the server sends that socket an `error` with
code `superseded` and closes it; the new socket takes over the seat. A client
that receives `superseded` drops its token and reconnects as a new identity.

## Client -> server messages

| `t`             | Fields                                                    | Notes |
|-----------------|-----------------------------------------------------------|-------|
| `hello`         | `v`, `name`, `platform`, `ld` (loadout), `token?`          | Must be the first frame. `platform` is `web`, `ios`, `android`, `macos`, or free text. |
| `ping`          | `c` (client time ms)                                       | Answered with `pong`. |
| `createRoom`    | `mode?` (`solo`/`duos`/`squads`), `fast?`, `seed?`, `code?`| A supplied `code` (4-8 chars `[A-Z0-9]`) is reused if free; a code owned by an empty lobby is recycled, an occupied one is joined. |
| `joinRoom`      | `code`                                                     | Errors: `room_not_found`, `match_in_progress`, `room_full`. |
| `leaveRoom`     |                                                            | |
| `ready`         | `ready` (bool, default true)                               | |
| `setLoadout`    | `ld`                                                       | `{outfit, pickaxe, glider, banner}` cosmetic ids. |
| `setMode`       | `mode`                                                     | Host only (`not_host`). |
| `startMatch`    | `fill?` (total player count), `countdownMs?` (default 3000)| Host only. Bots fill up to `fill` or `Rules.maxPlayers` (16). |
| `returnToLobby` |                                                            | Host only; resets the room after a match. |
| `input`         | `f` (InputFrame)                                           | See below. The server keeps at most 8 queued frames per client. |
| `testControl`   | `op`, `id?`, op-specific fields                            | Deterministic automation hooks, see below. |

### InputFrame (`f`)

```json
{
  "seq": 412,
  "mx": 0.0, "my": -1.0,
  "aim": 1.571,
  "fire": true,
  "sprint": true,
  "act": [{"t": "place"}, {"t": "select", "s": 2}]
}
```

- `seq` increments per frame; the server echoes the last applied sequence in
  the owning player's snapshot (`seq`) so the client can reconcile prediction.
- `mx`/`my` are the movement vector (clamped to unit length server-side),
  `aim` is radians.
- `act` is an optional list of discrete actions: `jump`, `select` (`s` slot),
  `buildMode`, `setPiece` (`v` = `wall|floor|ramp|roof`), `setMaterial`
  (`v` = `wood|brick|metal`), `place` (optional `gx`/`gy`), `edit`
  (`v` = a `PieceEdit` name), `interact`, `use`, `drop` (`s`), `reload`,
  `emote`, `spectateNext`, `thank`.

## Server -> client messages

| `t`          | Fields | Notes |
|--------------|--------|-------|
| `welcome`    | `v`, `token`, `name`, `serverTime`, `warning?` | |
| `error`      | `code`, `message` | Codes: `bad_message`, `room_not_found`, `room_full`, `match_in_progress`, `not_host`, `not_in_room`, `bad_token`, `version_mismatch`, `superseded`. |
| `pong`       | `c`, `serverTime`, `tick?` | |
| `roomState`  | `you`, `code`, `mode`, `fast`, `seed`, `maxPlayers`, `players[]`, `phase`, `countdownMs?` | `players[]`: `{id, name, platform, ready, connected, host, ld, team}`. |
| `matchStart` | `code`, `seed`, `mode`, `rules`, `tick`, `players[]`, `resume?` | `rules` is `Rules.toJson()`; clients build their local world from `seed` + `rules`. |
| `you`        | `id` | The receiving client's player id in this match. |
| `snapshot`   | see below | Sent every tick to every human in the room. |
| `matchEnd`   | `summary` | See match summary. |
| `testAck`    | `id`, `op`, op-specific fields | Reply to `testControl`. |

### Snapshot

```json
{
  "t": "snapshot",
  "tick": 1810,
  "match": {
    "phase": "playing", "tick": 1810, "alive": 9, "teamsAlive": 4,
    "bus": null,
    "storm": {"cx": 512.0, "cy": 470.5, "r": 310.2, "tx": 480.0, "ty": 455.0,
              "tr": 220.0, "ph": 1, "sh": true, "rem": 41.5, "dps": 1.0,
              "done": false},
    "winner": null
  },
  "players": [ ... ],
  "structs": [ ... ], "gone": [ ... ],
  "nodes": [ ... ], "chests": [ ... ], "loot": [ ... ],
  "ev": [ ... ]
}
```

- `match.phase` is one of `lobby`, `bus`, `playing`, `ended`. During `bus`,
  `match.bus` carries the bus path (`x0,y0 -> x1,y1`), progress `t` and
  seconds remaining `rem`. Per-player state (`s`) is `inBus`, `dropping`,
  `alive` or `eliminated`. `storm.ph` is the current storm phase index and
  `storm.sh` tells whether the circle is shrinking or waiting.
- Interest management: `players` contains the viewer, their teammates, the
  spectated player, everybody still on the bus, and anyone within
  `Rules.interestRadius` (90 units) of the viewer's focus (themselves, or the
  player they spectate once eliminated). Structures, resource nodes and chests
  are delta-encoded: an entry is sent only when its version changed since the
  viewer last saw it; `gone` lists structure ids that no longer exist. Floor
  loot within interest is sent every tick.
- Player entries use short keys: `id, n (name), t (team), b (bot),
  p (platform), s (state), x, y, a (aim), alt (altitude), hp, sh (shield),
  slot, bm (build mode), mv, fire, ld, k (kills), em, rl, us, con`. The
  viewer's own entry (and the spectated player) is `full` and adds `mats`,
  `inv`, `ammo`, `bp`, `bmat`, `seq`, `spec`, `cd`, `rlt`, `ust`, `st` (stats).
- Structure entries: `{id, gx, gy, p (piece), m (material), t (team), hp,
  max, e (edit), d (direction), b (built tick)}`.
- `ev` is the list of simulation events since the previous snapshot. Each
  has `type` and a `tick` plus payload. Types: `matchStart`, `busGone`,
  `jumped`, `landed`, `swing`, `nodeGone`, `pickup`, `dropped`, `chest`,
  `placed`, `edited`, `buildFailed`, `structHit`, `destroyed`, `shot`, `hit`,
  `reloaded`, `useStart`, `used`, `stormHit`, `eliminated`, `teamOut`,
  `emote`, `thanked`, `matchEnd`. Clients use these for the elimination feed,
  hit markers, sounds and haptics.

### Match summary

Broadcast in `matchEnd` and available over HTTP. It is the artefact the
cross-platform test compares between clients.

```json
{
  "seed": 4242, "mode": "squads", "endTick": 5120, "stormPhase": 3,
  "winnerTeam": 0, "teams": 4,
  "players": [
    {"id": 1, "name": "Web", "team": 0, "bot": false, "platform": "web",
     "placement": 1, "kills": 2, "damage": 180, "harvested": 240,
     "built": 9, "chests": 2, "survived": 256, "xp": 410}
  ]
}
```

## Test control (`testControl` / `testAck`)

Only used by the automated harness and the in-app `LASTFORT_AUTO` mode.

| `op`        | Fields                       | Effect |
|-------------|------------------------------|--------|
| `autopilot` | `on` (default true)          | The server drives this human with the deterministic bot brain (same `BotBrain` as server bots, seeded by `seed ^ playerId`). Autopiloted humans land together at a quiet spot away from bots. |
| `pause` / `resume` |                       | Stops or resumes the room clock. |
| `step`      | `n` (1-20000), `every`       | Advances `n` ticks synchronously, emitting snapshots every `every` ticks. |
| `summary`   |                              | Returns the current summary (or `null` before the end). |
| `state`     |                              | Tick, phase, player count, scheduler lag and the caller's full player JSON. |
| `start`     | `fill?`, `countdownMs?`      | Starts the match without requiring the host. |
| `report`    | `platform?`, `digest`, `summary`, `snapshots`, `test`, `screen` | Stores a client-side end-of-match report; the harness reads it back over HTTP. |

## HTTP endpoints

All responses are JSON and carry permissive CORS headers.

| Method | Path                     | Body |
|--------|--------------------------|------|
| GET    | `/health`                | `{ok, version, rooms, clients, uptimeSec}` |
| GET    | `/rooms`                 | `{rooms: [roomState...]}` |
| GET    | `/rooms/{code}/summary`  | `{code, phase, summary}` |
| GET    | `/rooms/{code}/reports`  | `{code, reports: {platform: report}}` |
| GET    | `/`                      | Serves the Flutter web build when the server is started with `--web-root <dir>`. |

## Determinism

`matchStart.seed` and `rules` fully determine the island, loot tables, chest
placement, bus path, storm centres and bot behaviour. Bots and autopilots use
`Rng` (a small xorshift generator) seeded from the match seed and their player
id, so a room created with `seed` and `fast` set (`createRoom`) replays the
same match on every platform.
