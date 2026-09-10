# Audit: states (2026-09-10T01:07:50Z, git 5f87b21)

Interactions verified through their results (not notifications): create room → code shown on
all clients; join by code → member list updates on every client; mode chips → lobby label
changes; Ready → host sees readiness; Start → bus phase; jump → drop; harvest → material
counters; build → structure appears on every client and costs 10 materials (core test);
loot → hotbar; storm → damage + timer; elimination → feed + spectate; match end → identical
summary digest `CA0FF4A2` on web/iOS/macOS (`evidence/tests/e2e-20260909-175052/report.md`).
Loading/empty/error states: connecting spinner, "Reconnecting (attempt n)" banner
(`evidence/screens/state-reconnecting-banner.png`), empty locker categories, invalid room
code error, disconnected-player timeout (server test).
Keyboard shortcuts: WASD/arrows, mouse aim, click fire, Shift sprint, Space jump/leave bus,
E interact, 1-5 hotbar, Q/F build pieces, Esc pause (`client/lib/game/controls.dart`).
