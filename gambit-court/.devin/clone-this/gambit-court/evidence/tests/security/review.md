# Security review

Revision sha256:c0981af2ad3b96f6b293518092fb514456651a2af7365bf678b41423ae6d43ca, 2026-09-10T01:26:51Z

- Authorization: the server is the only authority on game state; spectators, the
  wrong side and out-of-turn clients receive `not_allowed` / `not_your_turn`;
  illegal moves are rejected with `illegal_move`; only the host may seat a bot.
- Test automation: `/control/*` and `ui_command` exist only when the server is
  started with `--control`; production start (`dart run bin/server.dart`) does
  not expose them. The README documents this flag as test-only.
- Secrets: no credentials, tokens or key material in the tree (secret-scan.txt);
  `.env`, keystores and node_modules are not tracked.
- Dependencies: Dart packages current; Node harness `playwright-core@1.52.0`
  with `npm audit` reporting 0 vulnerabilities (dependencies.txt).
- Side effects: the harness only touches localhost, the iOS Simulator, the
  local macOS app and the user's Dock auto-hide setting (restored on exit).
