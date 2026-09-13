# Midnight Decks protocol v1

UTF-8 JSON over ws/wss. Default trusted-LAN endpoint: port 8317.
Every peer is a separate WebSocket connection. Client cannot choose player IDs.
Maximum two peers per room, 100 rooms, 8 KiB inbound payload, 150 messages/s/peer.
Closed sockets are marked offline; all-offline rooms are reclaimed after 120s.

## Client → server

```
{type:"ping", sent:<client epoch ms>}
{type:"join", name:"NOVA", room:"NIGHT", create:true}
{type:"join", name:"ECHO", room:"NIGHT"}
{type:"join", name:"ECHO", room:"NIGHT", token:"<prior joined token>"}
{type:"ready"}
{type:"input", seq:1, lane:0..7, down:true|false, time:<song ms>}
{type:"leave"}
```

Room codes are 4–6 ASCII letters/digits, case-insensitive; omitted create code is
generated. Guest names are 1–20 characters. Duplicate create fails. Resume token
is randomly issued and is never included in public snapshots or telemetry.
Rejoining closes any prior socket for that peer. A wrong token cannot claim a
slot in a full room. READY toggles outside gameplay; both online, ready peers
cause a start 3500 ms in the future. At results the same mechanism starts a new
round, resets all judgment state and keeps identities.

Input sequence numbers must be safe integers greater than the last seen number.
The server consumes them monotonically, even for rejected timestamp inputs.
Timestamps must be within ±250 ms of server receipt song time. Notes are judged
using the submitted clock-corrected input time. Misses expire after the 140 ms
window plus 250 ms network grace. Duplicate heads and tails cannot score twice.
Chords affect separate lanes. Up events judge the active hold's tail.
Unknown/no-note key presses make local sound but do not add a POOR.

## Server → client

```
{type:"pong", sent:<echo>, serverTime:<epoch ms>}
{type:"joined", you:<UUID>, token:<secret>, chart:<bundled chart>, state:<state>, serverTime:<epoch>}
{type:"state", you:<UUID>, state:<state>, serverTime:<epoch>}
{type:"error", message:<human readable>}
```

`state` includes `room`, `phase` (lobby/playing/result), `startAt` (server epoch
ms), `round`, `winner` (UUID, "draw", or empty), and `players`.
Each player has `id`, `name`, `online`, `ready`, `seq`, and `stats`.
Stats contain score, combo, maxCombo, groove gauge, counts, head/tail completion
arrays, and last judgment `{text, delta, lane, serial}`.

Both clients render the same authoritative state every 50 ms. They receive the
same chart, but each player has independent head/tail judgments. The winner is
the greatest EX score; a tie is explicitly a draw. The song ends at 64000 ms,
after all chart endpoints and network grace have elapsed.

The app estimates server offset as `serverTime − midpoint(sent, received)` from
its minimum-RTT sample. Client epoch is derived from a monotonic clock anchored
at startup. Inputs and note rendering use the same estimated song clock.
Audio is prepared in advance and scheduled on the device audio clock for the
announced future start. A resumed client seeks to the current song position.
The calibration slider adjusts input timestamps; speed changes rendering only.
