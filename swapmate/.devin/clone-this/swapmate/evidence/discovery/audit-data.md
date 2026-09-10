# Audit: data — state, persistence, protocol

- Source of truth: the server (`server/lib/src/room.dart`) owns rooms, seats,
  clocks, the `BughouseMatch` and results. Clients never mutate game state;
  they render `game.state` snapshots and extrapolate the running clock from
  `serverTime`.
- Wire format: JSON over WebSocket at `/ws`, fully documented in
  `PROTOCOL.md` (handshake, room lifecycle, gameplay, chat, errors, test
  channel). Shared Dart types in `packages/swapmate_core/lib/src/protocol.dart`
  are used by both ends, so client and server cannot drift.
- Identity / persistence: player id + resume token per connection; rooms are
  in-memory and garbage-collected when empty (`onEmpty`). There is no database
  by design — the reference describes a live game, not a persisted service.
- Export: BPGN (`packages/swapmate_core/lib/src/bpgn.dart`) with both boards
  interleaved chronologically, tags for event, site, players, time control and
  result; verified by `match_test.dart` ("BPGN export lists both boards
  chronologically") and exported by the e2e harness as `final.bpgn`.
- Snapshot round trip: `snapshot json round trip` test; `GET /rooms/<code>`
  returns the same room snapshot the clients receive.
- Cross-client consistency: the e2e harness compares `fenA`, `fenB`, `moves`,
  `score`, `moveText` / BPGN, `result`, `gameId` and `over` across all four
  clients and fails on any difference (`summary.json` → `agreement`).
- Determinism: server `--seed`, seeded bots, fixed time control, scripted
  moves; the same script yields the same final FENs on every run
  (`e2e-20260910T054256Z`, `e2e-20260910T061421Z` and the final run all end in
  the same position).
