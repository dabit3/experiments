# Final discovery sweep 1 — reference walk (iteration 6)

Method: walk every behaviour row of `reference-overcooked.md` (the public-documentation
inventory of the source) plus the "Inaccessible" list, and confirm each has an
inventory item in `inventory.md` whose status is verified with current evidence.
Independent of sweep 2 (which starts from the clone's code instead of the reference).

Audits re-read during this walk: source, navigation, roles, states, responsive, data,
assets, accessibility, reliability, rebrand (`audit-*.md`).

| Reference row | Inventory item(s) | Verified by |
| --- | --- | --- |
| feature-orders (ticket rail, timers, expiry) | feature-orders, route-game | core tests, E2E summary (served 11 / expired 1), gameplay screenshots |
| feature-score (base, tip, penalty, combo) | feature-score | core tests, E2E identical score 426 on 4 clients |
| feature-stars (thresholds scale with players) | feature-stars, route-results | core tests, results screenshots (1 star) |
| feature-chop (board, hold action, progress) | feature-chop | core tests, E2E |
| feature-cook (pot timer, burn, fire) | feature-cook, feature-fire | core tests |
| feature-fire (spread, extinguisher) | feature-fire | core tests |
| feature-plates (plate, pass, dirty return, sink) | feature-plates, feature-wrong-serve | core tests, E2E |
| feature-floor (free drops) | feature-floor | core tests |
| feature-dash | feature-dash, feature-input | core tests, HUD Dash button in gameplay screenshots |
| feature-emote | feature-emote | core/server tests (`emote` command) |
| feature-levels (distinct gimmicks) | feature-levels, feature-level-select | core level tests, lobby level grid screenshot |
| feature-modes (1-4 co-op, seats filled) | feature-modes, feature-bots, journey-solo-with-bots | server tests (2 humans + 2 bots to results) |
| feature-timer (round timer, results) | feature-timer, route-results | E2E late-game + results screenshots |
| feature-online (rooms, online play) | feature-lobby, feature-reconnect, feature-lag-comp, integration-server-ws, journey-four-platform-match | server tests, E2E four-platform match |
| world map / progression | feature-level-select (level grid with previews) | UI smoke `08-lobby-dark.png` |
| tutorial | feature-tutorial, route-how-to-play | UI smoke `03-how-to-play.png`, Training Kitchen level test |
| HUD / controls language | route-game, feature-input | gameplay screenshots on all four platforms |
| Inaccessible: art, fonts, audio, names | asset-* items, audit-assets, audit-rebrand | original fonts (OFL), procedural sprites, no audio (limitation) |
| Inaccessible: exact thresholds / tip curve | feature-stars, feature-score (own values, documented) | core tests |

Result: every reference row maps to at least one verified item. No new item, route,
feature, or journey discovered. Frontier empty. `new_items: 0`.
