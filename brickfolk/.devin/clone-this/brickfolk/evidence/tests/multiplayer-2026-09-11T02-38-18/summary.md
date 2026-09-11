# Brickfolk multiplayer e2e — FAILED

- platforms: web, ios, android, macos  (host: web)
- experience: obby  seed: 1234  party: BRIK  room: 97GE  bots: 0
- checksum (all clients): 05b96827  server: 05b96827
- identical final state: web=true ios=true android=true macos=true
- duration: 2674s  server tick: 71921
- android screenshots: emulator display frames taken once the app's phase marker showed each phase (display trails the app on the software emulator; markers seen at {"lobby":2330.9,"countdown":2447.9,"gameplay":2475.5,"results":2499.7} s), verified free of system ANR dialogs (1 dismissed during the run)

| rank | player | score | detail |
|---|---|---|---|
| 1 | MacMia | 98177 | Finished 60.8s |
| 2 | WebWren | 98155 | Finished 61.5s |
| 3 | IosIvy | 98129 | Finished 62.4s |
| 4 | DroidDax | 96853 | Finished 104.9s |

## Visual parity (web reference vs macOS)
- hub: MISMATCH (differing 1, edge cells 83, max delta 64, cluster 3)
- place: match (differing 0, edge cells 21, max delta 37, cluster 3)
- avatar: match (differing 0, edge cells 30, max delta 37, cluster 3)
- social: MISMATCH (differing 1, edge cells 16, max delta 49, cluster 2)
- chat: match (differing 0, edge cells 8, max delta 30, cluster 1)
- profile: match (differing 0, edge cells 25, max delta 43, cluster 7)
- daily: match (differing 0, edge cells 5, max delta 43, cluster 1)
- sensitivity (web hub vs itself shifted 8px): detected (differing 2042, cluster 212)
- noise baseline (web hub captured twice, tolerance 0): differing 0

## Failures
- visual mismatch web vs macos on hub:
- visual mismatch web vs macos on social:
