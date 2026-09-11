# Audit: source (2026-09-10T02:05:00Z, git 11a8115)

- Reference identity: Fortnite Battle Royale as publicly documented (wiki pages listed in
  `evidence/discovery/source-reference.md`, captured 2026-09-09). No running copy, source
  code, design files or account was available; this is the recorded reference-access boundary.
- Accessible scope: rules, loop, modes, HUD elements, building/storm/loot systems, lobby
  surfaces (design level). Inaccessible: exact geometry, fonts, colours, audio, map, weapon
  statistics, exact animation timing. All items carry `provenance: inferred`; literal
  parity with the original is never claimed.
- Lastfort side: repository structure = `core/` (deterministic sim + protocol), `server/`
  (authoritative rooms), `client/` (Flutter web/iOS/Android/macOS), `test/` (harness),
  `PROTOCOL.md` (wire contract), `README.md`.
- Reference did not change during the run (public docs; snapshot table in the discovery file).
- Blocker carried honestly: Android runtime (`evidence/blockers/`).
