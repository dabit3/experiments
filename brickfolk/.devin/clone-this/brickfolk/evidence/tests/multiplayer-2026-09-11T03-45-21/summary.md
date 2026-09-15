# Brickfolk multiplayer e2e — FAILED

- platforms: web, macos  (host: web)
- experience: tag  seed: 1234  party: BRIK  room: BX68  bots: 2
- checksum (all clients): 323fbb0a  server: 323fbb0a
- identical final state: web=true macos=true
- duration: 173s  server tick: 2087

| rank | player | score | detail |
|---|---|---|---|
| 1 | MacMia | 36 | 1 frozen |
| 2 | Mortar | 22 | 2 frozen |
| 3 | WebWren | 11 | 2 frozen |
| 4 | Pipsqueak | 0 | 4 frozen |

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
