# Audit: source — reference and source coverage

## Reference identity

- Source: **Bughouse chess** (also "tandem chess", "Siamese chess"), a 2-vs-2
  two-board chess variant. Requested clone name: **Swapmate**.
- Reference-access boundary: the user stated the original is a commercial title
  that cannot be run or purchased in this session. No original binary, screen
  or asset was observed. The reference is the *publicly documented* game
  design, captured on 2026-09-10 (UTC) into `evidence/reference/`:
  - `bughouse-wikipedia-raw.txt` — Wikipedia "Bughouse chess" article text
    (rules, drops, clocks, partner communication, tournament conventions).
  - `chesscom-bughouse.html` / `chesscom-bughouse.txt` — chess.com "Bughouse
    Chess Variant" terms page (the chess.com/FICS rule set the user asked for:
    pawns may not be dropped on ranks 1/8, checking and mating drops are
    legal, promoted pieces revert to pawns when captured, independent clocks).
  - `chessvariants-tandem.html` — chessvariants.com tandem/bughouse page
    (historic rule variations; used only to confirm which rules are optional).
- Consistency across sources: all three agree on the core loop and drop
  rules. They differ on optional conventions (drop-mate legality, promotion
  handling); Swapmate follows the chess.com/FICS choice and documents it in
  `README.md` and `PROTOCOL.md` ("Rules enforced by the server").

## Classification of requirements

- **Observed (public documentation):** two boards, partner piece passing,
  reserve, drop restrictions, drop-check/mate legality, promoted-piece
  reversion, independent clocks with increment, match ends when either board
  ends, partner communication ("need a knight"), premove/pre-drop as common
  online-play affordances, BPGN as the export format.
- **Inferred (no running original):** concrete HUD layout, colour palette,
  typography, animation timing, lobby/team-assignment flow, results screen
  layout, spectator UX, quick-chat vocabulary. These are original Swapmate
  designs; the manifest never claims pixel parity with any commercial title.
  Visual parity is defined as *normalized parity between Swapmate's own four
  clients*, with the web build as baseline (see `checks.visual`).
- **Inaccessible:** literal look-and-feel, audio, matchmaking/ratings, account
  systems and monetisation of any commercial Bughouse product. These are out
  of scope by the user's instruction and are not modelled as blockers because
  the user explicitly redefined the reference as the public rule set.

## Available structure of the clone

- `packages/swapmate_core/` rules engine, protocol types, BPGN, bot (22 tests)
- `server/` shelf + web_socket_channel authoritative server (8 tests)
- `app/` Flutter client with web / ios / android / macos targets (widget tests)
- `test/multiplayer-e2e.sh` four-platform end-to-end harness
- `PROTOCOL.md` documents every message, error code and test command.

Reference did not change during the run (static captures).
