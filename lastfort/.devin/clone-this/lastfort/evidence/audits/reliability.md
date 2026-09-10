# Audit: reliability (2026-09-10T02:05:00Z, git 11a8115)

Clean-checkout install + builds for all four targets from git `11a8115` in a fresh worktree:
`evidence/checks/clean-checkout-builds.txt` (web release, iOS simulator, Android APK, macOS
release, server AOT executable). Native artifact verification (Mach-O apps, no WebView, no
bundled HTML): `evidence/checks/native-artifacts.txt`. Runtime: production web build served
by the server and the release macOS app were used in the harness; web console errors are
captured in `evidence/tests/e2e-20260909-184420/web.log` (none). Stale-server detection, port cleanup, reconnect after
disconnect and player timeout are covered by the harness and server tests.
Blocked: Android runtime cannot be exercised here (`evidence/blockers/`).

Second pass at git `11a8115`: same-token takeover no longer lets the stale socket's close
callback evict the new connection (`server.dart` guards `c.channel != ws`), per-match tick
counters reset so a room can host consecutive matches, and pending input frames are cleared
on join and match start. Automated clients load an isolated profile namespace
(`LASTFORT_TEST=<id>`) and the light theme so runs never inherit device state.
