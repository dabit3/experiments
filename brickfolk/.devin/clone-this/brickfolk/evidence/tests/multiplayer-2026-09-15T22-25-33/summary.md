# Brickfolk multiplayer e2e — PASSED

- platforms: web, macos  (host: web)
- experience: tag  seed: 1234  party: BRIK  room: BX68  bots: 2
- checksum (all clients): 389f937d  server: 389f937d
- identical final state: web=true macos=true
- duration: 159s  server tick: 1896

| rank | player | score | detail |
|---|---|---|---|
| 1 | MacMia | 32 | 1 frozen |
| 2 | Mortar | 22 | 2 frozen |
| 3 | WebWren | 8 | 2 frozen |
| 4 | Pipsqueak | 0 | 3 frozen |

## Normalized visual parity (web reference vs macOS)
- Hub/social text bounds use the approved symmetric 5x5 font-edge filter; raw captures and unfiltered comparisons are retained.
- hub: match (differing 0, edge cells 41, max delta 47, cluster 2)
- place: match (differing 0, edge cells 21, max delta 37, cluster 3)
- avatar: match (differing 0, edge cells 30, max delta 37, cluster 3)
- social: match (differing 0, edge cells 11, max delta 34, cluster 2)
- chat: match (differing 0, edge cells 8, max delta 30, cluster 1)
- profile: match (differing 0, edge cells 25, max delta 43, cluster 7)
- daily: match (differing 0, edge cells 5, max delta 43, cluster 1)
- sensitivity (web hub vs itself shifted 8px): detected (differing 2001, cluster 212)
- noise baseline (web hub captured twice, tolerance 0): differing 0

