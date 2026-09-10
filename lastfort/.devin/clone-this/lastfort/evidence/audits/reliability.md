# Audit: reliability (2026-09-10T01:07:50Z, git 5f87b21)

Clean-checkout install + builds for all four targets from git `5f87b21` in a fresh worktree:
`evidence/checks/clean-checkout-builds.txt` (web release, iOS simulator, Android APK, macOS
release, server AOT executable). Native artifact verification (Mach-O apps, no WebView, no
bundled HTML): `evidence/checks/native-artifacts.txt`. Runtime: production web build served
by the server and the release macOS app were used in the harness; web console errors are
captured in `evidence/tests/e2e-20260909-175052/web.log` (none). Stale-server detection, port cleanup, reconnect after
disconnect and player timeout are covered by the harness and server tests.
Blocked: Android runtime cannot be exercised here (`evidence/blockers/`).
