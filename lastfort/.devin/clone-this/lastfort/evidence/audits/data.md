# Audit: data (2026-09-10T01:07:50Z, git 5f87b21)

Models: Room, Member, Rules, Player, Structure, Item/Loot, StormPhase, MatchSummary, Profile
(`core/lib/src/*.dart`, `PROTOCOL.md`). Persistence: profile/XP/cosmetics/settings in
shared_preferences (survives restart); rooms/matches are server memory (by design, documented).
Real-time: 20 Hz authoritative ticks, interest-managed snapshots (radius 90), client
prediction + reconciliation, reconnection with 60 s grace (`server/test/server_test.dart`
"reconnect resumes the same player mid-match", "disconnected players time out").
Ordering/concurrency: server sequence numbers; inputs acknowledged by tick.
No billing, uploads, or external providers exist in scope. Test-control HTTP endpoints
(`/rooms/<code>/reports|summary`) are read-only and documented in PROTOCOL.md.
Evidence: `evidence/tests/e2e-20260909-175052/server-summary.json`, `evidence/tests/e2e-20260909-175052/reports.json`, `evidence/tests/e2e-20260909-175052/server.log`.
