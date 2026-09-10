# Security review (final revision)

Scope: everything under `swapmate/` that will be committed (264 files as listed
by `git ls-files -o --exclude-standard swapmate`), plus the runtime surface of
the server and the four clients.

## Secrets

- No `.env`, keystore, `.p12`, `.pem`, `key.properties` or credential files
  are present or staged.
- Regex sweep for AWS keys, GitHub tokens, `sk-` API keys, private-key PEM
  blocks, hard-coded passwords and bearer tokens over all text files: no hits.
- The Android debug signing config from the Flutter template is used only for
  local builds; no release keystore is committed.
- Run artifacts under `.devin/clone-this/swapmate/evidence` contain no
  authorization headers or cookies (the app has no accounts).

## Server surface

- WebSocket messages are parsed inside `try/catch`; malformed JSON or payloads
  return `bad_request` instead of crashing the isolate (`hub.dart`).
- Every gameplay action is authorised against the seat that owns the
  connection; spectators and wrong-seat players receive `forbidden` /
  `not_your_turn`; illegal moves never reach the match model.
- Name (24 chars) and chat (200 chars) inputs are trimmed and capped; chat is
  flood-limited to 10 messages per 5 seconds (`rate_limited`).
- The `/test/*` control channel is only mounted when the server is started with
  `--test` or `SWAPMATE_TEST=1`; production starts without it. `/healthz`
  reports `testMode` so a deployment can be checked.
- CORS is `*` for the read-only `/healthz` and `/rooms/<code>` snapshots; no
  cookies or credentials are involved.
- Rooms are in-memory and garbage-collected when empty; there is no
  persistence layer and therefore no injection or data-at-rest concern.

## Clients

- The clients connect over `ws://` to a LAN/loopback server by default, so the
  Android manifest sets `usesCleartextTraffic="true"` and the iOS/macOS
  builds allow arbitrary loads / outgoing network. The README's run
  instructions show the `ws://` LAN default; a deployment behind TLS should
  pass a `wss://` `server` parameter and tighten these flags (noted here as a
  hardening follow-up, not a defect of the local multiplayer setup).
- macOS release entitlements request only `network.client`.
- No third-party analytics, ads or telemetry SDKs; dependencies are limited to
  `flutter`, `web_socket_channel`, `shelf`, `shelf_web_socket`,
  `swapmate_core` and the dev-only `playwright` for the harness.

## Result

PASS — no secrets, no unauthenticated mutating endpoints outside explicit test
mode, input validated and bounded, and remaining relaxations are development
defaults called out above.
