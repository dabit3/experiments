# Skyline Pulse protocol 1

Transport: JSON text over WebSocket, default TCP 8769. Server binds `0.0.0.0` for LAN play; no cloud service or account. `GET /` returns health only. The native client uses `URLSessionWebSocketTask`; no browser renderer.

## Lobby

Client `{"type":"join","create":true,"name":"Aria","room":"","token":null}` creates a random six-hex-character room. A second client uses `create:false` and the code. Server returns `joined` with a unique UUID, room and random rejoin token. Tokens are sent only to their owner and never appear in state/log output. Room capacity is two and server capacity is 100. Names are 1–20 characters. No player bots are added by the server.

The creator is host. `{"type":"song","song":"neon"}` selects either `neon` or `aurora`, clearing ready flags. Only the host can change it. `{"type":"ready","ready":true}` toggles readiness; two connected ready players atomically start. `leave` exits; lobby/results slots are removed and host transfers to the remaining player.

## Clock and rounds

`ping` carries client `sent` epoch milliseconds. `pong` echoes `sent` and includes server `now`. The client samples six times, chooses minimum RTT midpoint offset, and continues measuring every two seconds. Local time progresses using monotonic uptime anchored to an epoch. Both peers receive the same server `startAt` (four seconds ahead), song and round.

`AVAudioPlayer.play(atTime:)` schedules each bundled original track against the audio device clock. A reconnect during a track seeks to the room time. Rendering uses the common song clock. No synchronization claim below measured network/audio device uncertainty.

## Input and scoring

`{"type":"input","seq":42,"at":1780000000123,"pointer":"touch-…","action":"move","x":7.3,"y":0.90}`

- `seq`: strictly increasing integer per player/round; duplicates and stale sequences ignored.
- `at`: estimated server milliseconds, bounded to ±350ms of receipt.
- `pointer`: finger identifier, at most ten active contacts.
- `action`: `down`, `move`, `up`.
- `x`: normalized horizontal segment position 0–16.
- `y`: normalized screen coordinate, 0 top / 1 bottom.

Server runs at 60Hz, buffers 180ms, sorts pending inputs by timestamp and advances independent player judgments before each input. State broadcasts at 20Hz. Clients submit finger positions, never judgments or scores. Late input beyond an already resolved unit cannot undo it. Each sustain tick requires a fresh (≤250ms) contact in the appropriate lane and slider region (`y>0.72`). Slides interpolate their lane across the ribbon. Air requires at least 0.09 upward displacement within 0.5 seconds; static contacts do not trigger it.

Head windows: critical ±45ms, justice ±90ms, attack ±160ms; air maximum ±200ms. Weighted units critical=1, justice=.98, attack=.5, miss=0. Score is earned/total units × 1,000,000. Sustains have independent half-beat ticks; releasing loses ticks, reholding recovers. Accuracy is earned/judged units; misses reset combo. Every chart has an ending tail, after which server issues the common `results` state. Both ready again create a new round with reset scores and a new common start.

## State

`state` contains `room`, `phase` (`lobby`, `playing`, `results`), `song`, `startAt`, `round`, `host`, `now`, and two public `players`: identity, name, connection/ready flags, score, combo, maxCombo, accuracy, counts, last judgment. No secrets or other peer's pointer stream are exposed.

## Disconnects and limits

Socket closure marks its player disconnected and clears contacts; the timeline continues, so unplayed units miss. Client reconnects automatically using its in-memory token and retains its sequence. Explicit reconnect is also available on results. Disconnected rooms expire after two minutes without activity. Process restart loses rooms; app restart does not persist rejoin tokens. All traffic is local by default. Use `wss` behind a TLS proxy on untrusted networks.

Messages have a 4KiB maximum and rate limiting. This is a friendly guest game, not a hardened tournament anti-cheat system: client gesture coordinates/timestamps and the optional disclosed automation driver are trusted within validation limits. No public deployment is included.
