# Audit: navigation (2026-09-10T02:05:00Z, git 11a8115)

Surfaces: hub with side rail (desktop), compact rail (tablet) and bottom bar (phone) →
Play / Locker / Pass / Settings; Play → room card (create / join by code) → lobby → match
(HUD) → match-over overlay → results → back to lobby. Deep-link/query parameters on web:
`server, name, room, auto, autostart, seed, fast, mode, theme, test` (`client/lib/app/config.dart`).
Overlays: name editor, connection banner, elimination feed toasts, spectate bar, pause/quit
prompt. Evidence: `evidence/tests/e2e-20260909-184420/all-lobby.png`, `evidence/tests/e2e-20260909-184420/all-results.png`,
`evidence/screens/web-desktop-light-*.png`, `evidence/screens/web-phone-light-*.png`.
Not-found/refresh: the web app is a single entry point; a reload re-joins via the persisted
session token (`feature-reconnect`). No further navigation requirements found.
