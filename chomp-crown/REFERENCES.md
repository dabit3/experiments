# Reference research — 13 September 2026

Research preceded implementation. No ROM, extracted sprite or arcade software was
accessed. All in-app geometry, animation, effects and sound are original.

## Accessible evidence

* [Bandai Namco official Chompionship product page](https://ww.bandainamco-am.com/Ecommerce/category/commercial-games/pac-man-battle-royale-chompionship):
  competitive four-player maze game, eating other players, new power-ups,
  linked cabinets supporting eight players.
* [2011 gameplay description](https://en.wikipedia.org/wiki/Pac-Man_Battle_Royale):
  multicolored players, oversized power state that eats opponents and ghosts,
  vulnerable players turn blue while retaining their own outline, equal-strength
  collisions knock back, last survivor receives the round, returning players
  compete over several rounds, fruit refreshes pellets.
* [2022 description and power-up list](https://www.mobygames.com/game/198053/pac-man-battle-royale-chompionship/):
  faster pace, score counters, more lives and ten special power-ups. This build
  concentrates on the 2011 elimination rules and shared oversized power mechanic.
* [Accessible gameplay screenshot](https://syltefar.com/screenshot/?id=2413),
  [direct image](https://syltefar.com/images_full/pac_man_battle_royale_arcade.jpg):
  **visually inspected**, 1024 × 768. Symmetrical compact maze with central ghost
  pen, black background, thick rounded luminous tubes (red in this particular
  state), tiny gold dots, deep-blue vulnerable bodies with player-colored rims,
  a dramatically oversized yellow chomper, directional player markers.

## Design and evidence boundaries

Chomp Crown uses the requested electric-blue wall palette, paired thin neon wall
contours, a dark ink/navy background, gold pellets, four distinct player colors,
animated wedge mouths, blue vulnerability with a retained color rim, a central
ghost pen, glowing powered bodies and crown pips. Portrait iPhone composition
places a scoreboard above the arena and a directional pad below. These are
original authored drawings actually rendered by SpriteKit, not marketing assets.

The screenshot establishes visual traits; descriptions establish reported rules.
Exact speed, collision radii, maze dimensions, ghost AI, audio, timing and bounce
distance are **inferred/tuned**, not measured against a running arcade cabinet.
Original software and equivalent native reference capture are inaccessible.
Literal pixel parity and the clone-this strict zero-difference gate are therefore
**not claimed or passed**. The user's explicit approximation permission governs.

## Acceptance inventory

| ID | Behavior | Evidence target |
|---|---|---|
| lobby | Editable LAN address, guest identity, room create/join, ready | two native instances |
| maze | Buffered orthogonal turns, walls block movement, connected corridors | engine tests, touch test |
| pellets | Server-authoritative collection, score, refill fruit | engine/integration tests |
| power | Timed growth, vulnerable outline, human and ghost eating | tests and recorded gameplay |
| ghosts | Visible AI chase/flee, ghost pen release, normal-player elimination | tests and match |
| rounds | Elimination, crowns, first to two, shared result, both vote rematch | two-device match |
| network | Distinct peers, ordered input, room limit, reconnect, per-peer state | WebSocket integration tests |
| controls | D-pad, swipe, ready, sound, reconnect, leave, rematch | native touch paths |
| presentation | Moving mouths, glow, score typography, effects, original audio | visible native recording |

Not implemented from the 2022 sequel: eight-player linked cabinets, all ten
special power-up types, its multi-life mode, exact arena layouts or licensed
soundtrack. Chomp Crown supports two to four human peers; ghosts are identified AI.
