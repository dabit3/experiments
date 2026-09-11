# Audit: reliability

| Scenario | Handling | Evidence |
| --- | --- | --- |
| Socket drop (lobby or mid-match) | client `ConnState.reconnecting`, app-level overlay with Leave, exponential retry, resume token restores seat; if the server forgot the seat the stale room is dropped with a toast | server test "reconnect with token resumes seat mid-match" (`evidence/tests/unit-tests.log`); `client.dart` `_open(reconnect: true)` |
| Server unreachable at start | `ConnState.failed` chip + retry on home; auto-join times out to home with toast | `home_screen.dart`; ui-smoke error toasts show the same path |
| Bad / full join code | server `error`, client stays on home, field keeps code | ui-smoke `summary.json` |
| Player leaves mid-match | seat marked disconnected, match continues, host migrates | `room.dart`; server test rematch flow |
| Rendering lag on slow devices (software-rendered Android emulator) | clients report `framesSinceScreen` / `screenAgeMs`; harnesses wait for painted frames before capture | `test/visual/run.mjs`, `visual-parity.log` |
| Transition races | outgoing screens hold model snapshots (no `room!` during fades) | ui-smoke "web console has no errors" |
| Determinism under jitter | inputs are tick-stamped and applied before the step; all four clients + server + offline plan agree on the final result | E2E `summary.json` |
| Resource cleanup | timers/subscriptions cancelled in `GameClient.dispose`, rooms closed when empty, harness kills every child process | `client.dart`; ui-smoke room count; `test/e2e/run.mjs` cleanup |
| Long run | full 150 s round with four clients, recording and per-platform screenshots completed without a crash; natural overtime checked separately in the manual UI pass | `evidence/e2e/2026-09-11T04-08-18/e2e.log`, `four-way-match.mov`, `evidence/tests/arcade-ui/report.md` |

Console/log hygiene: the web console is asserted error-free during the smoke
run (`ui-smoke/web-console.log`); `flutter analyze` / `dart analyze` report
no issues (`quality.log`).

## Final arcade revision

`sha256:7624c6febbe0677676ccdf9f39d47b066e86d09b2b602875c98ce7c2bb7478c6`
was frozen before the final suite. `evidence/tests/fingerprint-files.txt`
records Git coverage of 174 files: application/core/server source, all test
scripts, original art and fonts, native projects, nonsecret configuration,
lockfiles and fixtures. Only the established generated-output and run-evidence
exclusions apply; no exclusions were added for this pass.

`evidence/tests/clean-checkout-build.log` comes from a clean detached Git
worktree at source commit `82b05af`, with `flutter clean`, dependency resolution
and all four builds returning zero. `build.log` repeats the same builds in
the working checkout.

The Android-x86 fixture required provisioning, disabling its setup/analytics
apps, wake/keep-awake configuration and dismissing a System UI ANR. Invalid
captures were discarded and all nine visual pairs and the four-client match
were recaptured after recovery. Archived failure material is under
`evidence/diffs/arcade-fixture-recovery/` and
`evidence/diffs/arcade-systemui-recovery/`.

The browser recorder originally closed the browser before its recording
context finished muxing WebM, leaving missing duration metadata. Cleanup now
awaits context closure first. The editor rejects missing/nonpositive media
duration rather than cutting repeated half-second opening clips. The review
includes nine distinct log-derived browser-check entries.

The final screenshot review found that a loosely fitted score panel left
the tablet stopwatch near the middle of the footer. A new right-edge widget
regression failed before the layout correction and passed afterward, together
with the other five widget tests. Evidence: `tablet-clock-before.log`,
`tablet-clock-after.log` and `tablet-clock-analyze.log` under `evidence/tests/`.
The source freeze and both four-target clean builds were repeated after this
correction.
