# Source reference: Chess (public rules and conventions)

Recorded 2026-09-10T01:26:51Z, clone revision sha256:c0981af2ad3b96f6b293518092fb514456651a2af7365bf678b41423ae6d43ca.

## Access boundary
The requested source is the commercial chess title. It was **not run or purchased**
in this session and no screenshot, asset, name, logo or audio from it was captured
or copied. The reference for every inventory item is the publicly documented
game: the FIDE Laws of Chess (movement, castling, en passant, promotion, check,
checkmate, stalemate, threefold repetition, fifty-move rule, dead position),
standard algebraic notation, the PGN standard, conventional online-chess
lobbies (quick pairing, invite codes, spectators, engine opponents, clocks with
increment, takebacks by agreement, rematch) and the widely used board
conventions (light square at h1, last-move and legal-move highlights, board flip,
premoves).

## Observed / inferred / inaccessible
- **observed**: rules, notation and PGN behaviour — verified against the public
  standards by the core unit tests (`packages/gambit_court_core/test`).
- **inferred**: lobby, HUD and results presentation of typical online chess
  products. Gambit Court uses an original visual system ("ink and brass"), so
  these are product requirements, not copies.
- **inaccessible**: the commercial title's exact screens, assets and flows.
  No item claims parity with them; visual parity in this run is *normalized
  visual parity between Gambit Court's own four clients* with the web build as
  the baseline (see `evidence/tests/e2e/parity/`).
