# Brickfolk multiplayer e2e — PASSED

- platforms: web, ios, android, macos  (host: web)
- experience: obby  seed: 1234  party: BRIK  room: 97GE  bots: 0
- checksum (all clients): 1ffa7529  server: 1ffa7529
- identical final state: web=true ios=true android=true macos=true
- duration: 633s  server tick: 9800
- android screenshots: emulator display frames taken once the app's phase marker showed each phase (display trails the app on the software emulator; markers seen at {"lobby":423,"countdown":497.3,"gameplay":500.9,"results":515.8} s), verified free of system ANR dialogs (0 dismissed during the run)

| rank | player | score | detail |
|---|---|---|---|
| 1 | WebWren | 98177 | Finished 60.8s |
| 2 | MacMia | 98177 | Finished 60.8s |
| 3 | DroidDax | 98144 | Finished 61.9s |
| 4 | IosIvy | 98129 | Finished 62.4s |

## Visual parity (web reference vs macOS)
- hub: match (differing 0, edge cells 13, max delta 34, cluster 2)
- place: match (differing 0, edge cells 20, max delta 35, cluster 3)
- avatar: match (differing 0, edge cells 25, max delta 37, cluster 3)
- social: match (differing 0, edge cells 17, max delta 48, cluster 2)
- chat: match (differing 0, edge cells 6, max delta 28, cluster 1)
- profile: match (differing 0, edge cells 33, max delta 43, cluster 7)
- daily: match (differing 0, edge cells 5, max delta 43, cluster 1)
- sensitivity (web hub vs itself shifted 8px): detected (differing 824, cluster 49)
- noise baseline (web hub captured twice, tolerance 0): differing 0

