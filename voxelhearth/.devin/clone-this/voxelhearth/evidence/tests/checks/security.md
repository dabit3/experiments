# Security review (check `security`)

Scope: `server/`, `packages/voxelhearth_core/`, `app/lib/net`, platform shims.
Method: source inspection + grep, 2026-09-09, at the final revision.

| Area | Finding | Evidence |
| --- | --- | --- |
| Secrets | No tokens, keys or passwords in the tree; `grep -ri 'secret\|password\|api_key'` matches only the word "tokens" in the design-token comment and the session `token` field. | `app/lib/ui/theme.dart:4`, `app/lib/net/game_client.dart:142` |
| Session tokens | Server issues 24-char tokens from `math.Random.secure()`; the client stores its token in memory + SharedPreferences and presents it to rejoin the same player id. Test mode uses predictable `test-<name>` tokens **only when `--test-mode` is set**. | `server/lib/server.dart:70,178,275-282` |
| Director channel | Rejected unless `--test-mode`; requires `--director-key` match (`voxelhearth-director` default, test only). Production servers never enable it. | `server/lib/server.dart:405-416` |
| Host authority | `startMatch`, `endMatch`, `backToLobby`, room settings gated on `pid == hostId` in the shared sim. | `packages/voxelhearth_core/lib/src/sim.dart:426-430` |
| Input limits | Player names truncated to 20 chars; bots clamped 0..6; chat trimmed, capped at 200 chars and 300 lines; block edits validated against reach/solidity server-side; all JSON reads go through `jstr/jint` helpers with defaults (malformed frames cannot throw). | `server/lib/server.dart:272,356`, `sim.dart:884-890` |
| Transport | Plain `ws://` on `0.0.0.0:8787` by default (LAN play); `--host 127.0.0.1` for local-only. TLS termination is expected from a reverse proxy; documented in README. iOS `NSAllowsLocalNetworking` and Android `usesCleartextTraffic` are limited to the dev/LAN use case. | `server/bin/server.dart:15,73-80`, `app/ios/Runner/Info.plist`, `AndroidManifest.xml` |
| CORS | `Access-Control-Allow-Origin: *` on the health/static endpoints only; the WebSocket carries no cookies or credentials. | `server/bin/server.dart:43-49` |
| Persistence | Saves are JSON under `server/saves/` (git-ignored); no user PII beyond the display name. | `.gitignore` |
| Dependencies | `dart pub`/`flutter pub` lockfiles committed; `flutter analyze` / `dart analyze` clean; no native plugins beyond `shared_preferences`. | `checks/core.txt`, `checks/server.txt`, `checks/app.txt` |

No high-severity findings. Open recommendation (not a blocker for a LAN/dev
game server): put the server behind TLS and rate-limit joins per IP before
exposing it to the public internet.
