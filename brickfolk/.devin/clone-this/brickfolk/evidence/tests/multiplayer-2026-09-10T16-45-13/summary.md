# Brickfolk multiplayer e2e — PASSED

- platforms: web, macos  (host: web)
- experience: tycoon  seed: 1234  party: BRIK  room: BX68  bots: 2
- checksum (all clients): 2f1d181c  server: 2f1d181c
- identical final state: web=true macos=true
- duration: 198s  server tick: 2944

| rank | player | score | detail |
|---|---|---|---|
| 1 | Pipsqueak | 269551 | 36 bricks, 4914/s |
| 2 | WebWren | 260460 | 36 bricks, 4842/s |
| 3 | Mortar | 234074 | 36 bricks, 4320/s |
| 4 | MacMia | 223655 | 36 bricks, 4212/s |

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

