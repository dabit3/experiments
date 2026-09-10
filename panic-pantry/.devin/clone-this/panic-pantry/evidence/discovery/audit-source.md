# Audit: source

Panic Pantry is a from-scratch cooperative kitchen game in the spirit of the
publicly documented Overcooked design. The original is a commercial, closed
title that this run could not run, purchase or capture; there is no source
code, asset bundle or running instance to enumerate, so the "entry points"
audited here are the *documented* design surfaces recorded in
`reference-overcooked.md` (fetched 2026-09-09, URLs listed there):

| Documented surface | Inventoried as | Access class |
| --- | --- | --- |
| Core loop: orders, chop, cook, plate, serve, wash | feature-orders, -chop, -cook, -plates, -wrong-serve, -floor | observed (docs) |
| Scoring: +20 base, tip by remaining time, -10 expired, combo x4, 3 stars | feature-score, feature-stars | observed (docs) |
| Fire: burnt pot ignites, spreads, extinguisher | feature-fire | observed (docs) |
| Kitchens with hazards / moving layouts, level select map | feature-levels, feature-level-select | observed (docs); exact layouts inaccessible |
| 1-4 player local/online co-op, lobbies, round timer, results | feature-modes, -lobby, -timer, -reconnect, route-lobby, route-results | observed (docs); online lobby flow inferred |
| Controls: move, single interact, chop/action, dash, emote | feature-input, feature-dash, feature-emote | observed (docs) |
| Tutorial | feature-tutorial | observed (docs) |
| Exact art, audio, timers, thresholds per level | asset-* (original replacements) | inaccessible -> inferred |

Every route, feature, journey, asset and integration in `state.json` traces
back to one of these rows (`inventory.md` holds the per-item detail). Items
the docs imply but that need the running original (exact timings, per-level
thresholds, audio) are recorded as *inferred* in `state.json` and were
implemented from the documented rules, not copied. Nothing was left as an
unrecorded frontier entry: the reference document has no remaining
"to inspect" branches, and `frontier` is empty.

Commercial-title consequence recorded in `state.json.notes`: no literal
parity with the original is claimed; visual parity is normalized parity
between Panic Pantry's own four clients.
