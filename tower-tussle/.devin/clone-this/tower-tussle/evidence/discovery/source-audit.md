# Source audit — Clash Royale → "Tower Tussle"

## Reference identity and accessible scope

- Source: Clash Royale (Supercell). Closed-source, commercial, mobile-only (iOS/Android).
- The running reference is **not accessible** in this session: no App Store / Play Store account,
  no authorized binary, no game assets, no source code. No screenshots of the source were captured.
- The user explicitly requested a *"Clash Royale-lite"* with an **original title** and a
  *"slightly different name, design, etc."* — i.e. a gameplay-inspired reimplementation, not a
  pixel-identical copy. Pixel parity against the source is therefore both impossible (no
  reference captures) and out of scope by request.
- All requirements below are **inferred** from public, widely documented gameplay rules
  (arena layout, elixir economy, tower/troop/spell card types, 3-minute match with
  double-elixir and overtime, crowns → win/loss). They are recorded as `inferred`, never as
  `observed`.

## Consequences for the completion gates

- `visual` comparisons against the source cannot be produced → recorded as a blocker
  (`blocker-no-reference-captures`). Clone screenshots are still captured as evidence of the
  clone's own rendering on iOS. Android runtime remains blocked by host virtualization.
- All other audit categories are evaluated against the *inferred requirement inventory* and
  against the clone itself (functional behavior, persistence, build, rebrand).
- The run will therefore end as `blocked` (visual parity gate), not `complete`, and is reported
  honestly as such.

## Inferred requirement inventory (the design spec for both native apps)

### Navigation (routes)
- `route-home` Home: title, trophies + gold, BATTLE, CARDS buttons.
- `route-cards` Cards: current 8-card deck, collection of remaining cards, tap-to-swap, card detail.
- `route-battle` Battle: arena, timer, crowns, elixir bar, 4-card hand + next card.
- `route-results` Results: VICTORY / DEFEAT / DRAW, crowns per side, trophy delta, gold, Home / Rematch.

### Battle rules
- Arena 18×32 tiles, portrait. River across the middle with two bridges (left/right lanes).
- Each side: 2 Guard Towers (HP 2500, dmg 100, range 7.5, hit 0.8 s) + 1 Keep (HP 4000, dmg 120,
  range 7, hit 1.0 s). The Keep activates once it takes damage or a Guard Tower falls.
- Elixir: max 10, start 5, +1 per 2.8 s; ×2 rate during the final 60 s and overtime.
- Match: 3:00 regulation. Destroying a Keep ends the match immediately (3 crowns).
  If crowns are tied at 3:00 → 1:00 overtime, first tower destroyed wins. Still tied → draw.
- Hand: 4 cards visible + next card; deck of 8 cycles.
- Deploy: tap a card, then tap on your own half (troops) or anywhere (spells).
- Troops target nearest enemy troop in aggro range, else nearest enemy tower in their lane;
  ground troops path through the nearest bridge; building-only troops ignore troops;
  melee troops cannot hit flying troops.
- Opponent AI: same elixir rules; plays a troop when it can afford it, chooses the lane under
  pressure, casts spells on clusters of ≥2 player troops.

### Cards (10 total, 8 in deck)
| id | name | cost | kind | notes |
|---|---|---|---|---|
| knight | Knight | 3 | troop | melee tank |
| archers | Archers | 3 | troop ×2 | ranged |
| giant | Colossus | 5 | troop | buildings only, slow |
| duelist | Duelist | 4 | troop | high single-target dmg |
| sharpshooter | Sharpshooter | 4 | troop | long range |
| gremlins | Gremlins | 2 | troop ×3 | very fast swarm |
| bones | Bone Brigade | 3 | troop ×6 | fragile swarm |
| whelp | Whelp | 4 | troop, flying | ranged |
| meteor | Meteor | 4 | spell | radius 2.5, 570 dmg (35% to towers) |
| volley | Volley | 3 | spell | radius 4, 240 dmg (35% to towers) |

### Data / persistence
- Trophies (start 0, +30 win / −20 loss floor 0), gold (+50 win / +10 loss / +20 draw),
  wins/losses/draws, deck composition. Persist across process restart
  (UserDefaults on iOS, SharedPreferences on Android).

### Rebrand
- Original title "Tower Tussle"; original card names where they would otherwise collide with
  Supercell trademarks (Giant→Colossus, Mini P.E.K.K.A→Duelist, Musketeer→Sharpshooter,
  Goblins→Gremlins, Skeleton Army→Bone Brigade, Baby Dragon→Whelp, Fireball→Meteor, Arrows→Volley,
  Princess Tower→Guard Tower, King Tower→Keep). No Supercell assets, fonts or art are used;
  artwork combines original Blender models rendered to PNG atlases/portraits/scenery,
  native vector effects and UI, and original synthesized audio. See `art/README.md`
  and `evidence/checks/arcade-redesign.md` for generation and verification details.
