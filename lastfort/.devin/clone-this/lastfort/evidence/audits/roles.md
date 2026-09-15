# Audit: roles (2026-09-10T02:05:00Z, git 11a8115)

No account system exists in the reference scope that is reproducible here (Epic accounts are
out of the reference-access boundary). Lastfort uses local identities: a display name plus a
server-issued session token stored in shared_preferences (`client/lib/app/profile.dart`).
Roles observable in the clone: host (mode selection, Start match, bot fill) vs member (Ready
up), alive vs eliminated (spectator controls only), bot vs human. Server-side authorization:
only the host may start; only alive players' inputs are applied; eliminated players can only
switch spectate targets (`server/lib/src/room.dart`, `server/test/server_test.dart`).
Evidence: `evidence/tests/e2e-20260909-184420/all-lobby.png` (host controls on Web, "Waiting for the host" on Mac).
