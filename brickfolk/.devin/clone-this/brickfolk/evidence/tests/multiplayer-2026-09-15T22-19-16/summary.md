# Brickfolk multiplayer e2e — PASSED

- platforms: web, macos  (host: web)
- experience: obby  seed: 1234  party: BRIK  room: BX68  bots: 2
- checksum (all clients): 0604703a  server: 0604703a
- identical final state: web=true macos=true
- duration: 176s  server tick: 2269

| rank | player | score | detail |
|---|---|---|---|
| 1 | MacMia | 98177 | Finished 60.8s |
| 2 | WebWren | 98148 | Finished 61.7s |
| 3 | Mortar | 97987 | Finished 67.1s |
| 4 | Pipsqueak | 97975 | Finished 67.5s |

## Normalized visual parity (web reference vs macOS)
- Hub/social text bounds use the approved symmetric 5x5 font-edge filter; raw captures and unfiltered comparisons are retained.
- hub: match (differing 0, edge cells 41, max delta 47, cluster 2)
- place: match (differing 0, edge cells 22, max delta 37, cluster 3)
- avatar: match (differing 0, edge cells 30, max delta 37, cluster 3)
- social: match (differing 0, edge cells 11, max delta 34, cluster 2)
- chat: match (differing 0, edge cells 8, max delta 30, cluster 1)
- profile: match (differing 0, edge cells 25, max delta 43, cluster 7)
- daily: match (differing 0, edge cells 5, max delta 43, cluster 1)
- sensitivity (web hub vs itself shifted 8px): detected (differing 2001, cluster 212)
- noise baseline (web hub captured twice, tolerance 0): differing 0

