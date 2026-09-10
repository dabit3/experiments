# Audit: reliability

| Scenario | Handling | Evidence |
| --- | --- | --- |
| Socket drop mid-match | client `ConnState.reconnecting`, exponential retry, resume token restores seat | server test "reconnect with token resumes seat mid-match" (`evidence/tests/unit-tests.log`); `client.dart` `_open(reconnect: true)` |
| Server unreachable at start | `ConnState.failed` chip + retry on home; auto-join times out to home with toast | `home_screen.dart`; ui-smoke error toasts show the same path |
| Bad / full join code | server `error`, client stays on home, field keeps code | ui-smoke `summary.json` |
| Player leaves mid-match | seat marked disconnected, match continues, host migrates | `room.dart`; server test rematch flow |
| Rendering lag on slow devices (software-rendered Android emulator) | clients report `framesSinceScreen` / `screenAgeMs`; harnesses wait for painted frames before capture | `test/visual/run.mjs`, `visual-parity.log` |
| Transition races | outgoing screens hold model snapshots (no `room!` during fades) | ui-smoke "web console has no errors" |
| Determinism under jitter | inputs are tick-stamped and applied before the step; all four clients + server + offline plan agree on the final result | E2E `summary.json` |
| Resource cleanup | timers/subscriptions cancelled in `GameClient.dispose`, rooms closed when empty, harness kills every child process | `client.dart`; ui-smoke room count; `test/e2e/run.mjs` cleanup |
| Long run | full 150 s + overtime match with four clients, recording and per-platform screenshots completed without a crash | `evidence/e2e/<final>/e2e.log`, `four-way-match.mov` |

Console/log hygiene: the web console is asserted error-free during the smoke
run (`ui-smoke/web-console.log`); `flutter analyze` / `dart analyze` report
no issues (`quality.log`).
