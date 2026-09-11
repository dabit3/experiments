# Swapmate wire protocol (v1)

Swapmate clients talk to one authoritative server over a single WebSocket
carrying JSON text frames. The server owns all rules, clocks and room state;
clients only render snapshots and send intents. Every message is a JSON object
with a `type` field. Unknown fields are ignored; unknown types produce an
`error`.

The canonical constants live in
`packages/swapmate_core/lib/src/protocol.dart` and are shared by the server
and the Flutter client, so all four platforms speak byte-identical JSON.

```
ws://<host>:8787/ws        WebSocket endpoint
http://<host>:8787/healthz  {ok, rooms, clients, testMode}
http://<host>:8787/rooms/<CODE>  {room, game, bpgn} read-only snapshot
http://<host>:8787/         static web build when started with --static
```

## Vocabulary

| Term | Values | Meaning |
| --- | --- | --- |
| board | `A`, `B` | The two simultaneous boards. |
| seat | `aw`, `ab`, `bw`, `bb` | Board letter + colour. Team 1 = `aw`+`bb`, Team 2 = `ab`+`bw`. |
| team | `1`, `2` | Partners sit on opposite colours of opposite boards. |
| colour | `w`, `b` | |
| piece letter | `P N B R Q K` | |
| square | `a1` … `h8` | |
| move | `{from, to, promotion?}` or `{drop, to}` | `drop` is a piece letter placed from the reserve. |
| FEN | standard FEN + `[reserve]` | Reserve letters in brackets after the placement field (uppercase = white). |

## Handshake

```jsonc
// client -> server (first message)
{"type":"hello","v":1,"name":"Nader","platform":"ios",
 "resumeToken":"r-…", "testId":"ios"}          // both optional

// server -> client
{"type":"welcome","v":1,"playerId":"p-…","resumeToken":"r-…",
 "room":"SWAP"|null,"serverTime":1710000000000,"testMode":false}
```

`resumeToken` re-attaches a dropped connection to its player and room; the
server replays `room.state`, `game.state` and the player's pending premove.
`testId` is only honoured by servers started with `--test`.

`{"type":"ping","t":<ms>}` ⇄ `{"type":"pong","t":<ms>,"serverTime":<ms>}` keeps
the connection alive and lets clients estimate skew for clock rendering.

## Rooms and lobby

| client → server | fields | notes |
| --- | --- | --- |
| `room.create` | `timeControl?` `{initialMs, incrementMs}`, `fillBots?`, `code?` | `code` only honoured in test mode; otherwise a 4-letter join code is generated. `fillBots` seats deterministic bots in every empty seat. |
| `room.join` | `code`, `spectate?` | Spectators receive every broadcast but cannot act. |
| `room.leave` | | |
| `room.seat` | `seat` or `null` | Take/leave a seat. Seats are first-come. |
| `room.bot` | `seat`, `add` | Host only. Adds/removes a server-side bot. |
| `room.ready` | `ready` | |
| `room.start` | | Host only; requires four seats and every human ready. |
| `room.timeControl` | `timeControl` | Host only, lobby only. |
| `room.rematch` | | Any seated player after `finished`; when all humans vote the room returns to `playing` with colours swapped. |

Every change broadcasts

```jsonc
{"type":"room.state","room":{
  "code":"SWAP","phase":"lobby|playing|finished","host":"p-…",
  "timeControl":{"initialMs":180000,"incrementMs":0},
  "players":[{"id":"p-…","name":"Web player","seat":"aw","ready":true,
              "bot":false,"connected":true,"platform":"web"}, …],
  "spectators":[…],"rematchVotes":["p-…"]}}
```

`room: null` is sent to a player who has left.

## Gameplay

| client → server | fields | notes |
| --- | --- | --- |
| `game.move` | `move` | Must be legal for the sender's seat and colour to move. |
| `game.premove` | `move` or `null` | Stored per player, validated and executed when the player's turn arrives; `null` clears. Works for drops (pre-drop). |
| `game.resign` | | Ends the match for the sender's team. |
| `game.draw` | `action`: `offer`, `accept`, `decline` | Agreement requires both teams. |
| `chat.send` | `quick` (code) or `text`, `scope`: `team` or `room` | Quick codes: `need_p need_n need_b need_r need_q no_q sit go trades mating help gg thanks sorry`. |

The server broadcasts a full snapshot after every change:

```jsonc
{"type":"game.state","game":{
  "gameId":"g-…",
  "boards":{
    "A":{"id":"A","fen":"rnbqkbnr/…[NP] w KQkq - 0 1",
         "clock":{"w":179400,"b":180000,"running":"w"},
         "lastMove":{"from":"e2","to":"e4"},"inCheck":false},
    "B":{…}},
  "moves":[{"seq":1,"board":"A","color":"w","number":1,
            "move":{"from":"e2","to":"e4"},"san":"e4","clockMs":180000},
           {"seq":7,"board":"A","color":"b","number":4,
            "move":{"drop":"P","to":"h6"},"san":"P@h6","clockMs":171200,
            "captured":null}],
  "result":null | {"winner":"1"|"2"|null,
                   "reason":"checkmate|timeout|resignation|stalemate|repetition|agreement|abandonment",
                   "board":"A","loser":"2"},
  "serverTime":1710000000000,
  "premove":{"from":"g8","to":"f6"} | null,    // recipient's own premove
  "drawOffers":["aw"],
  "bpgn":"[Event …]" | null                    // present once finished
}}
```

Clocks are sent as remaining milliseconds sampled at `serverTime`; clients
extrapolate the running side locally and never enforce time themselves.

Alongside each snapshot the server emits a `game.event` so clients can
animate what happened:

```jsonc
{"type":"game.event","event":{"kind":"move|drop|pass|start|finish",
  "board":"A","seat":"aw","move":{…},"san":"Qxf7#",
  "captured":"P","toBoard":"B","toColor":"b"}}
```

`pass` events carry the captured piece to the partner's reserve on the other
board (`toBoard`, `toColor`), which drives the piece-passing animation.

## Rules enforced by the server

Standard chess movement including castling, en passant and promotion, plus
Bughouse extensions per the common chess.com/FICS rule set:

- A captured piece is added to the *partner's* reserve (partner = opposite
  colour on the other board). Promoted pieces revert to pawns when captured.
- A drop places one reserve piece on any *empty* square as a full move.
  Pawns may not be dropped on ranks 1 or 8.
- Drops that give check **or checkmate** are legal.
- Checkmate, timeout or resignation on either board ends the whole match for
  both boards. Stalemate, threefold repetition and agreement are draws.
- Each board keeps independent white/black clocks with per-move increment.
- Sitting (declining to move) is allowed; the clock keeps running.

## Chat

```jsonc
{"type":"chat.message","message":{"from":"p-…","name":"iOS player","seat":"ab",
  "ts":1710000000000,"scope":"team","quick":"need_n"}}
{"type":"chat.message","message":{…,"scope":"room","text":"gg"}}
```

## Errors

```jsonc
{"type":"error","code":"illegal_move","message":"…","ref":"game.move"}
```

Codes: `bad_request room_not_found room_full seat_taken not_host not_seated
not_your_turn illegal_move not_playing not_ready rate_limited`.
`rate_limited` is returned for `chat.send` beyond 10 messages in 5 seconds.
`chat.send` text is trimmed and truncated to 200 characters.

## Test channel (server started with `--test`)

Used by `test/multiplayer-e2e.sh` to drive every platform through one game.
A client that sent `testId` in `hello` can be addressed over HTTP:

```
GET  /test/clients                  -> {"clients":[{"testId","playerId","name","platform","room","seat"}]}
POST /test/command                  {"testId":"ios","command":{"cmd":"move","uci":"e2e4"},"timeoutMs":30000}
                                    -> {"ok":true,"result":{…client state…}} | {"ok":false,"error":"…"}
```

The server forwards the command as `{"type":"test.command","id":"t-…", …command}`
and the client answers `{"type":"test.result","id":"t-…","ok":true, …}`.
Commands run through the same UI controllers a user drives (the board
controller executes `move`), not a back door into the server.

| cmd | fields | result |
| --- | --- | --- |
| `state` | | `{screen, status, theme, playerId, room, seat, phase, gameId, fenA, fenB, moves, moveText, over, score, result, viewport}` |
| `create_room` | `code?`, `fillBots?`, `timeControl?` | state once the room exists |
| `join_room` | `code`, `spectate?` | |
| `seat` | `seat` | waits until the seat is held |
| `bot` | `seat`, `add` | |
| `ready` | `ready` | |
| `start` | | waits for `playing` + first `game.state` |
| `move` | `uci` (`e2e4`, `e7e8q`, `P@h6`) | waits for the move to be applied or rejects with the server error |
| `premove` | `uci` | |
| `quick_chat` | `code` | |
| `chat` | `text` | |
| `resign`, `draw` (`action`), `rematch`, `leave` | | |
| `theme` | `mode`: `dark` or `light` | |
| `wait` | `phase?`, `moves?`, `over?`, `frames?`, `timeoutMs?` | blocks until the predicate holds, then until `frames` more frames were produced (a device screenshot needs 3 on slow emulators) |
| `capture` | | state plus `png` (base64), `pngWidth`, `pngHeight`: the client's own rasterised frame. Used when the host cannot screenshot (software-rendered Android emulator). |

Seeds: `--seed` fixes the server RNG (room codes, bot move choice) and bots
choose moves by a deterministic evaluation over the seeded RNG, so a test with
a fixed seed and fixed time control replays identically.
