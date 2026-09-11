# Audit: states (2026-09-10T02:05:00Z, git 11a8115)

Interactions verified through their results (not notifications): create room → code shown on
all clients; join by code → member list updates on every client; mode chips → lobby label
changes; Ready → host sees readiness; Start → bus phase; jump → drop; harvest → material
counters; build → structure appears on every client and costs 10 materials (core test);
loot → hotbar; storm → damage + timer; elimination → feed + spectate; match end → identical
summary digest `CA0FF4A2` on web/iOS/macOS (`evidence/tests/e2e-20260909-184420/report.md`).
Loading/empty/error states: connecting spinner, "Reconnecting (attempt n)" banner
(`evidence/screens/state-reconnecting-banner.png`), empty locker categories, invalid room
code error, disconnected-player timeout (server test).
Keyboard shortcuts: WASD/arrows, mouse aim, click fire, Shift sprint, Space jump/leave bus,
E interact, 1-5 hotbar, Q/F build pieces, Esc pause (`client/lib/game/controls.dart`).

Manual UI pass findings (testing agent, web + macOS) and their fixes, re-verified by the
server suite and the `e2e-20260909-184420` run: Esc now opens the leave-match dialog
(`match_screen.dart`); a second tab sharing the persisted token is handled by the
`superseded` protocol error (old socket closed, new socket keeps the seat, old client
resets to idle and re-identifies) instead of the room disappearing (`server_test.dart`:
"a second connection with the same token supersedes the first"); a room's second match
no longer stalls at bus 0:00 and stale queued inputs are dropped ("a room can play a
second match after the first ends"); manual Create Room inherits the server's fast
default unless the user asks for normal rules.
