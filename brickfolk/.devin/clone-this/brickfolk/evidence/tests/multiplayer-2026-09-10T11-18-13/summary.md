# Brickfolk multiplayer e2e — PASSED

- platforms: web, ios, android, macos  (host: web)
- experience: obby  seed: 1234  party: BRIK  room: 97GE  bots: 0
- checksum (all clients): 3b7b1423  server: 3b7b1423
- identical final state: web=true ios=true android=true macos=true
- duration: 466s  server tick: 8427
- android screenshots: emulator display frames taken once the app's phase marker showed each phase (display trails the app on the software emulator; markers seen at {"lobby":255.5,"countdown":333.7,"gameplay":340.1,"results":350.9} s), verified free of system ANR dialogs (0 dismissed during the run)

| rank | player | score | detail |
|---|---|---|---|
| 1 | WebWren | 98177 | Finished 60.8s |
| 2 | MacMia | 98176 | Finished 60.8s |
| 3 | IosIvy | 98129 | Finished 62.4s |
| 4 | DroidDax | 98061 | Finished 64.6s |

## Visual parity (web reference vs macOS)
- hub: match (differing 0, edge cells 20, max delta 31, cluster 1)
- avatar: match (differing 0, edge cells 10, max delta 33, cluster 3)
- social: match (differing 0, edge cells 12, max delta 38, cluster 1)
- chat: match (differing 0, edge cells 3, max delta 28, cluster 1)
- profile: match (differing 0, edge cells 14, max delta 38, cluster 3)
- daily: match (differing 0, edge cells 5, max delta 43, cluster 1)
- sensitivity (web hub vs itself shifted 8px): detected (differing 710, cluster 89)
- noise baseline (web hub captured twice, tolerance 0): differing 0

