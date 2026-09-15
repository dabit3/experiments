# Final discovery sweep 1 — reference-driven (public docs → inventory)

Method: re-read the public documentation capture and list every gameplay/UX
concept it names; each must map to an inventory item ID or be classified
inaccessible (not claimed). Revision: see state.json.

## Concepts named in evidence/reference/public-docs-wikipedia-mariowiki.txt

| Concept (doc) | Inventory item | Class |
|---|---|---|
| kart racing, up to N racers | feat-8-racers-bots | observed |
| rocket start | feat-drift-miniturbo (countdown boost in sim) | observed |
| slipstreaming | feat-slipstream | observed |
| drifting, mini-turbo tiers | feat-drift-miniturbo | observed |
| item boxes on course | feat-items | observed |
| speed-boost item | feat-items (Turbo Can / Triple Turbo) | observed |
| thrown projectile (homing) | feat-items (Homing Rocket / Bouncy Orb) | observed |
| dropped hazard | feat-items (Syrup Slick) | observed |
| defensive/shield item | feat-items (Bubble Shield) | observed |
| field-wide attack item | feat-items (Thunder Zap) | observed |
| auto-pilot catch-up item | feat-items (Comet Ride) | observed |
| position-based item odds (rubber banding) | feat-items | observed rule / inferred table |
| cups of 4 courses, Grand Prix points | feat-grand-prix, feat-results-points | observed |
| Time Trial vs ghost | feat-time-trial-ghost | observed |
| Battle mode, balloons/points, timer | feat-battle-arena | observed |
| online play, rooms | feat-multiplayer-rooms | observed |
| controls: steer/accelerate/brake/item/drift | feat-input | observed |
| HUD: position, lap, item, map | feat-position-minimap, route-race | observed |
| course elements: shortcuts, jumps, boost pads, hazards | feat-tracks-4 | observed (kinds) / inferred (layouts) |
| character + vehicle stats selection | route-garage | observed |
| engine classes (50/100/150cc), mirror mode | — not claimed (out of scope for v1) | inferred |
| anti-gravity, gliders, underwater | — not claimed | inaccessible/out of scope |
| exact item probability tables | — original tables in items.dart | inferred |
| exact layouts, fonts, colours, audio | — original Nitro Tots design | inaccessible |

Result: 0 new requirements. Every observed concept maps to a verified item;
inferred/inaccessible rows are recorded as original design or out of scope, not
as parity claims. Frontier empty.

## Audits re-run during this sweep
source navigation roles states responsive data assets accessibility reliability rebrand — all still verified (see audits.md).
