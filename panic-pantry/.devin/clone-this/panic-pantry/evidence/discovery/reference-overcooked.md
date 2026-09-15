# Reference: Overcooked (Ghost Town Games / Team17, 2016; Overcooked 2, 2018)

## Access boundary (recorded honestly)

The source is a commercial, closed-source title. This run could NOT run, purchase,
or capture the original. Reference material is limited to publicly documented
game design gathered on 2026-09-09 from:

- https://en.wikipedia.org/wiki/Overcooked (gameplay overview, modes, kitchens/hazards)
- https://www.trueachievements.com/game/Overcooked/walkthrough/2 (scoring: +20 base per order,
  tip scaled by remaining order time, -10 for expired orders, 3-star thresholds, dirty plate
  stacks, floor drops are free, fire spreads, extinguisher)
- https://familygamesquad.com/how-to-play-overcooked/ and /overcooked-tips-and-tricks/
  (round starts with 2 orders queued, roles: chop / cook / wash / serve, dash)
- https://gamerant.com/overcooked-2-how-to-get-four-stars/ (tip combo multiplier up to 4x,
  per-player-count score thresholds, 4th star after campaign)
- https://www.mejoress.com/overcooked-2-keyboard-controls-pc/ (WASD move, Space pick/drop,
  Ctrl chop/throw, Alt dash, E emote)
- https://overcooked.fandom.com/wiki/Fire_Extinguisher, /wiki/Chopping
- https://www.superjumpmagazine.com/overcooked-how-design-creates-teamwork/ (single interact
  button, per-task visible timers, order cards stack at the top, fire as a shared emergency)

Consequences:

- Items requiring the running original (exact art, timer durations, thresholds
  and audio) are classified **inferred**. Implemented replacements follow the
  documented design; audio is omitted.
- No proprietary assets, characters, names, logos, level names, or audio were copied.
  All Panic Pantry art and names are original; no audio track is shipped.
- "Visual parity" in this run means **normalized visual parity against Panic Pantry's own
  cross-platform reference**: the web build is the visual baseline and iOS / Android / macOS
  builds are compared against it (see evidence/diffs). No literal pixel parity with Overcooked
  is claimed anywhere in this run.

## Observed (documented) design, inventoried

| ID | Behaviour | Source | Class |
| --- | --- | --- | --- |
| feature-orders | Orders arrive on a ticket rail at the top with a draining time bar; two are queued at round start | trueachievements, familygamesquad, superjump | observed (docs) |
| feature-score | +20 base per served order, tip proportional to remaining time, -10 when an order expires, tip combo multiplier up to 4x for serving in order (OC2) | trueachievements, gamerant | observed (docs) |
| feature-stars | 3-star rating from coin thresholds that scale with player count | trueachievements, gamerant | observed (docs), thresholds inferred |
| feature-chop | Raw ingredients are chopped on a cutting board by holding the action button; progress bar | fandom/Chopping, superjump | observed (docs) |
| feature-cook | Chopped ingredients go in a pot/pan on a stove; cooking has a visible timer; left too long -> burnt -> fire | trueachievements, superjump, fandom | observed (docs) |
| feature-fire | Fire spreads to nearby tiles; a fire extinguisher is picked up and sprayed with the action button | fandom/Fire_Extinguisher | observed (docs) |
| feature-plates | Cooked food is plated, served at the pass; dirty plates return on a conveyor and stack; sink washes them | trueachievements | observed (docs) |
| feature-floor | Items can be dropped on the floor without penalty | trueachievements | observed (docs) |
| feature-dash | Dash button for fast movement | mejoress, familygamesquad | observed (docs) |
| feature-emote | Emote button for quick communication | mejoress | observed (docs) |
| feature-levels | ~28 kitchens with distinct gimmicks: moving trucks, pedestrian crossing, ice, shifting kitchens | wikipedia | observed (docs); specific layouts inferred |
| feature-modes | 1-4 player co-op, single player controls two chefs, versus mode, world map progression gated by stars | wikipedia, trueachievements | observed (docs) |
| feature-timer | Fixed round timer per kitchen; results screen with coins and stars | wikipedia | observed (docs) |
| feature-online | Online multiplayer exists only in OC2 / All You Can Eat | wikipedia | observed (docs) |

## Visual language (documented conventions used by the design pass, iteration 9)

The second design pass ("follow the original as closely as possible") was driven by the
publicly documented, widely described HUD and kitchen conventions below. These are layout
and proportion conventions, not assets. Game art and names are original;
bundled fonts and Material icons use their documented open-source licenses.
The original was never run, so nothing here is a pixel measurement.

| Convention | Public description | Panic Pantry realisation |
| --- | --- | --- |
| Ticket rail | Orders as cards across the top-left, newest on the right, each with the dish picture, its ingredient pictograms and a draining bar under the card that turns from green to red | `game_screen.dart` `_Hud` / `_Ticket` (`_DishIcon`, `_IngPicto`): card with recipe picture, ingredient row, urgency bar and points badge |
| Score | Coin/money total bottom-left with a coin badge, tip pops next to it | `_CoinScore` + `_ComboBadge`: coin disc + total, tip/combo badge to its right |
| Timer | Round clock bottom-right, circular, turns red in the last stretch, "overtime" once the round is over | `_Stopwatch`: circular dial with sweep, red under 15 s |
| Kitchen | Top-down walled room: counters ring a tiled floor, stations (crates, boards, stoves, sink, pass, plate return) sit on the ring, often an island of boards/stoves in the middle, chefs are round-headed with hats | `levels.dart` layouts (`Corner Café` ring + central prep island), `sprites.dart` counters, brick frame, tiled floor, chef silhouettes |
| Station feedback | Progress bubbles above boards/pots, steam and smoke, a burning pot flashes | `kitchen_game.dart` progress bubbles, particles |
| Headlines | Chunky rounded outlined display type for "Time's up!" / countdown | `ui.dart` `OutlinedText` (Nunito Black, dark outline + shadow) |
| Results | Blue header with stars filling in, then a report card with served / tips / total and thresholds | `results_screen.dart` |
| Level select | World-map style level cards with star tallies and a lock/tutorial mark | `lobby_screen.dart` level grid + `level_preview.dart` |

Sources: the same public pages listed above (trueachievements, superjump, familygamesquad,
mejoress, fandom wiki, Wikipedia) plus press screenshots described in reviews; none were
copied into the repository.

## Inaccessible (recorded, not claimed)

- Exact sprite art, timings and level names -> original replacements.
- Fonts and UI icons -> licensed open-source assets; audio -> not shipped.
- Exact per-level star thresholds -> Panic Pantry defines its own thresholds per level and
  player count (documented in core/lib/src/levels.dart).
- Exact tip curve -> Panic Pantry uses remaining-time tiers of 8/5/3 multiplied by combo 1..4.

## Arcade redesign request (iteration 11)

The user's subsequent arcade-quality design request authorizes a new original
art direction. Panic Pantry now uses petrol teal, paprika and enamel cream,
a generated toy-diorama hero, dimensional procedural kitchen materials and a
teal results header. The documented gameplay and HUD conventions above remain
the reference; these new palette and illustration choices are original design
decisions, not newly observed properties of the commercial game.
