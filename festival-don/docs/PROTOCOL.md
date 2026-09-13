# Festival Don wire protocol v1

UTF-8 JSON over WebSocket, normally `ws://<host>:8786`. One socket belongs to one guest. The HTTP `/health` endpoint is read-only. There is no public deployment.

## Client messages

| type | Fields | Effect |
|---|---|---|
| `hello` | — | Request catalog |
| `ping` | `sent` (client epoch ms) | Server replies with receive epoch |
| `create` | `name` | Create a random six-hex-character room |
| `join` | `code`, `name`, optional `token` | Join second slot or resume an existing guest |
| `select` | `song`, `difficulty` (`easy`/`festival`) | Host-only lobby selection; clears ready flags |
| `ready` | `ready` boolean | Toggle readiness in lobby/results; two connected ready peers start a round |
| `hit` | `seq`, `at` (calibrated server epoch ms), `kind` (`don`/`ka`), `hand` (`left`/`right`) | Authoritative hit judgment |
| `songs` | — | Host returns results to lobby |
| `leave` | — | Detach and remove a lobby guest |

## Server messages

- `catalog`: public song metadata and `now`.
- `pong`: echoed `sent` and server `now`. Client estimates offset as `now − (sent + receive)/2`, using its lowest RTT sample. It gathers fast samples before the performance and freezes offset changes during music.
- `joined`: own `id`, own secret resume `token`, room snapshot and chart. Tokens are never included in public snapshots or logs.
- `chart`: selected chart including note IDs, onset milliseconds, kind, big flag and duration.
- `state`: `now` and room snapshot, broadcast at 20 Hz while playing and after state changes.
- `error`: readable `message`; invalid room/capacity/host actions do not mutate scores.
- `left`: acknowledgment.

Room state contains `code`, `host`, `phase`, `song`, `difficulty`, `round`, `startAt`, `winner`, and public players. Every player includes ID/name/readiness/connectivity, score, combo/max combo, good/ok/bad, roll/big counts, gauge, consumed note IDs, last judgment, delta and event counter.

## Timing and scoring

When both peers are ready, server picks `startAt = Date.now() + 5000`. Note time is relative to the beginning of the bundled WAV, including its two-second count-in. Clients schedule playback on the local audio device clock. Staff motion and local driver use the same epoch; local touches play immediate sound, then send timestamped input.

The server rejects invalid enums, duplicate/nonincreasing sequence IDs, timestamps over 100 ms in the future or 250 ms old, and timestamp regressions greater than 5 ms. Inputs are processed in socket arrival order. It chooses the nearest unconsumed note within 140 ms, checks color, and awards GOOD (1000) or OK (500), plus 100 for each ten-combo tier capped at ten tiers. A valid opposite-hand big pair within 75 ms awards the first strike's points again. It permits at most one pair per big note. Rolls are time spans and do not consume notes or build combo.

The server waits 250 ms beyond the miss window before finalizing unplayed notes, allowing normal LAN jitter. Results occur after the chart duration plus 250 ms and use the same authoritative winner ID on both devices. Readying again resets each peer's counters, retaining identity and issuing a fresh common start.

## Limits and failure handling

- Two peers per room; maximum 100 rooms; six-character codes are discovery convenience, not authorization.
- 4 KiB maximum inbound message; 100 messages/s per socket; heartbeat every 10 s.
- Resume token uses 24 random bytes. A resumed socket supersedes an older socket for that same guest.
- Disconnect preserves state. Empty disconnected rooms expire after 120 s. Process restart does not persist rooms.
- Individual calibration and client event timestamps are intentionally trusted within bounds; no claim of internet-grade competitive anti-cheat.
- Original charts are deterministic; no random note generation occurs during play.
