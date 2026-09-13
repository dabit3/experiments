# Reference research — 13 September 2026

Source: **Killer Queen (2013)**. New work: **Hive Sovereign**.

## Observed

- Official rules, https://www.killerqueenarcade.com/howtoplay :
  five per team, one queen and four workers; workers carry one berry and ride
  the snail; berries purchase winged-gate warrior transformations; queens fly,
  claim gates and dive; warriors fly and sword-fight but cannot carry or ride;
  three queen deaths, a full hive, or snail delivery each independently win.
- Official overview, https://www.killerqueenarcade.com/ :
  a joystick and a single button; simultaneous strategic objectives.
- Community map documentation, https://killerqueenarcade.wiki/wiki/Day :
  symmetric Day arena with 66 berries.
- Examined full map image:
  https://static.wikitide.net/killerqueenwiki/4/43/Day-Blank.png
  (1568×882). Bright cyan sky, layered pale blue pixel clouds, narrow floating
  moss-and-ochre platforms with trailing vines, adjacent blue/gold hive towers
  high in the center, twelve dark honeycomb holes per hive, glowing eggs,
  white wing motifs on charcoal gates, magenta berry pyramids, and a low snail
  corridor with colored baskets at opposite ends. This is an empty map screenshot,
  not evidence of character animation or exact gameplay physics.
- https://killerqueenarcade.wiki/wiki/Welcome_to_Killer_Queen! :
  twelve berries fill a hive; elevation decides armed jousts.
- https://killerqueenarcade.wiki/wiki/Gate :
  neutral gates permit either team; queen contact claims gates; workers spend
  a berry and stand still for one second. Speed gates increase speed by 33%.

## Authored interpretation

Landscape iPhone, SpriteKit, original pixel insect sprites and scenery; a compact
map retains the central paired hives, mirrored aerial platforms, wing gates,
berry piles, eggs and bottom snail lane. Original chiptone effects, queen crowns,
sword gleams, flapping wings and pixel hit particles convey the roles.

Two real human captains oppose each other. Each may switch among their five units
and issue Economy / Snail / Military orders. Every unselected unit is explicitly
marked AI. This replaces the original's ten local cabinet players and is a
documented adaptation. Guest WebSockets and ready/rematch screens are new.

The arcade executable, original character sheets, precise movement timings,
collision boxes, and audio are inaccessible. Physics, AI, map geometry, effects,
timing, and controls are authored; no ROMs or original proprietary assets are
included. The accessible screenshot is research evidence only. Pixel identity
is not claimed. The clone-this strict zero-pixel gate is intentionally not marked
passed: the user's permitted original/reference-inspired artwork takes priority.

## Acceptance inventory

| ID | Behavior / visual | Evidence method |
|---|---|---|
| room | create/join, distinct peers, ready, reconnect, rematch | WebSocket integration and two-device test |
| move | run, jump, platform landing, horizontal wrap, wing flaps | physics tests and touch UI |
| economy | collect one berry, return to own hive, 12 deposits win | simulation tests + live counters |
| transform | owned/neutral gates, berry cost, delay, speed/warrior | simulation tests |
| military | height jousts, dive, queen eggs, worker respawn | simulation tests |
| snail | workers only, contestable ride, destination victory | simulation tests + shared progress |
| captains | switch only own team, AI identification, team orders | protocol tests and UI |
| art | paired towers, skies, platforms, bugs, gates, berries, snail | inspected native captures vs reference observations |
| feedback | movement animation, hit/berry/gate/win tones, results | native run |

Research followed the source/roles/states/assets/reliability/rebrand portions of
the clone-this skill, loaded from its complete public repository after managed
plugin installation timed out. Original executable comparisons, repeated source
captures and exact parity sweeps cannot be truthfully performed.
