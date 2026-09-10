# Audit: reliability

- Transport: automatic reconnect with exponential backoff and a resume token
  (`GameClient`); the server keeps a disconnected player's seat for
  `reconnectGraceMs` and re-sends room + game snapshots on resume (test
  "reconnecting with a resume token restores the seat").
- Heartbeat: client `ping` / server `pong` measures latency and detects dead
  sockets; the hub closes on stream error/done and releases the seat after the
  grace timer.
- Input validation: every inbound message is parsed inside try/catch and
  answered with `bad_request` on malformed JSON or payloads; names are trimmed
  and capped at 24 chars, chat text at 200 chars; chat is flood-limited (10 per
  5 s → `rate_limited`); illegal moves / wrong turn / wrong seat return
  `illegal_move` / `not_your_turn` / `forbidden` (test "errors are reported for
  illegal moves and wrong turns").
- Authority: clients never apply their own moves optimistically beyond a
  premove hint; state is replaced by server snapshots, so divergent clients
  are impossible by construction and verified by the e2e agreement check.
- Abandonment: a player leaving mid-game forfeits for their team
  (`match.abandon`); the host role migrates to the next human; empty rooms are
  freed (`onEmpty`).
- Clocks: flag detection runs server-side (`_flagTimer`); clients extrapolate
  from `serverTime` so a paused tab or slow emulator cannot drift the result.
- Slow devices: the software-emulated Android build (no hypervisor on this
  host) is handled with a release/AOT APK, longer test-channel timeouts and the
  `wait … frames` primitive so screenshots show the presented frame.
- Test coverage: 10 server tests (end-to-end match on four platforms, bots,
  premoves, reconnection, chat scopes, flood limit, truncation, error codes,
  HTTP endpoints), 22 core rule tests, 2 widget tests, and the four-platform
  e2e harness with negative controls.
