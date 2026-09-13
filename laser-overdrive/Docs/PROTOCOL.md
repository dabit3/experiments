# Local WebSocket protocol v1

Transport: UTF-8 JSON over WebSocket, default port 8769. HTTP `/health` reports
host/chart/room status. Packets are limited to 4096 bytes and 180 per connection
per second. Room capacity is two, host capacity is 100 rooms.

## Client → server

| Type | Required fields | Meaning |
|---|---|---|
| `hello` | `id`, `token`, `name`, `chart` | Register a guest. UUID and random token persist per app installation. |
| | `code`, `create` | Empty code creates a random six-character code. Nonempty code joins; `create:true` may create a deterministic test room. |
| `ping` | `sent` | Client epoch milliseconds. |
| `ready` | none | Toggle this peer's ready state in lobby/results. |
| `input` | `epoch`, `seq`, `time`, `kind`, `source` | Match epoch, increasing sequence, song-relative seconds. |
| | `kind:"button"`, `lane:0..5`, `down:bool` | BT A–D are lanes 0–3; FX-L/R are 4–5. |
| | `kind:"laser"`, `color:0..1`, `x:0..1` | Cyan or magenta cursor. A live gesture sends periodic samples even when held still. |
| `leave` | none | Release the connection; remove the seat immediately outside gameplay. |

Input timestamps must be within ±250 ms of authoritative song time, monotonic to
25 ms jitter, finite and inside the song. Sequence numbers may never repeat within
an epoch. Identical button transitions are rejected. Wrong-epoch events are ignored.
No client score packet exists. `source` only labels evidence; it never changes scoring.

## Server → client

- `joined`: `id`, `code`, `chart`, `nextSeq` for resumed input ordering.
- `pong`: echoes `sent` and includes `serverNow`.
- `error`: human-readable `message`.
- `state` at 20 Hz: `code`, `phase` (`lobby`, `playing`, `results`), `epoch`,
  `serverNow`, `startAt` in epoch milliseconds, `duration`, and two peer snapshots.
  Snapshots contain scores, combo, max combo, gauge, judgment, readiness/connection,
  cursor positions and scored-mechanic/input counters. They never contain tokens.

Both connected peers ready → reset per-peer scoring, increment epoch, start four
seconds in the future. The clients use the lowest-round-trip ping's midpoint clock
offset; local audio is scheduled in host audio time. Resume schedules the remaining
audio segment at the current server song offset. Rendering uses the shared song
clock, not incoming snapshot intervals.

## Scoring

All chart scoring opportunities have a known total weight; score is earned/total
normalized to ten million. Notes weigh 1000, hold/laser ticks 150, slams 600.
Critical notes within 50 ms earn full weight, near notes within 120 ms earn half.
Missing notes are resolved after 150 ms. Hold ticks inspect historical button
state, allowing recovery after an early release. Laser ticks require a sample
within 140/1000 of the chart target and at most 180 ms old. Slams additionally
require a recent crossing of at least 280/1000 from the preceding segment.
Ticks are adjudicated 150 ms late to permit normal input delivery, without delaying
the audio or local visuals.

At chart duration plus 200 ms both receive the same result snapshot. Both ready
again resets the engine into a new epoch. There are no AI competitors.

The server retains disconnected seats during play; the same ID plus secret token
can resume without changing the start time or score. Concurrent reuse replaces
the older connection. Wrong-token reuse and third-seat attempts are rejected.
Outside play, disconnected seats expire after 60 seconds. Empty inactive rooms
expire after ten minutes. Rooms and tokens are in-memory only.

## Timing diagnostics

`EVENT_LOG` writes JSONL asynchronously so filesystem latency cannot block input
handling. Accepted touch entries include `seq`, `time`, `x` and server epoch-ms
`at`; rejected inputs include the validation reason and receive song time.
`tick-delay` records server tick intervals over 100 ms. Native `touch` and
`send-completed` entries preserve sampling and WebSocket completion wall times.
Compare these separately: regular sampling alone cannot prove timely delivery.
Graceful server close drains pending evidence writes.
