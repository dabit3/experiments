# Source reference: Fortnite Battle Royale (public documentation only)

Captured: 2026-09-09 (UTC) during the Lastfort clone run.

## Reference-access boundary

The source is a commercial title that cannot be run, purchased, or captured on this
machine (no Epic account, no game client, no console). The reference used for this run
is the **publicly documented game design** gathered from:

- https://fortnite.fandom.com/wiki/The_Storm (storm phase table, damage per second,
  minimap shortest-path line, storm sickness/surge)
- https://fortnite.fandom.com/wiki/Building (walls/floors/stairs/pyramids, 3x3 edit
  grid, wood/stone/metal properties, 10 materials per piece, 500 material cap,
  placement colors light-blue/red/yellow, support-collapse rule)
- https://fortnite.fandom.com/wiki/Rarity (Common → Uncommon → Rare → Epic → Legendary
  → Mythic ladder; common weapons floor-loot only; epic/legendary from chests)
- https://fortnite.fandom.com/wiki/Battle_Bus (straight randomized line over the island,
  horn when doors open, forced drop at path end, "thanked the bus driver" feed message)
- General public knowledge of the mode (100 HP + 100 shield, small/big shield potions,
  bandages/medkits, squads of 1/2/4, elimination feed, compass strip, minimap, storm
  timer, hotbar with 5 weapon slots, spectating after elimination, Victory Royale
  screen, lobby with Locker / Battle Pass / match stats).

Consequences recorded honestly:

- Every item that depends on the running original (exact HUD geometry, fonts, colors,
  audio, animation timing, exact weapon statistics, exact map) is **inferred** from the
  public description, not observed. Items are tagged `provenance: inferred` in
  `state.json`.
- Literal pixel parity with the original is **inaccessible** and is not claimed anywhere.
  Visual verification in this run is **normalized visual parity against the clone's own
  cross-platform reference**: the web build is the visual baseline and the iOS, Android
  and macOS builds must match it in the shared UI (see `evidence/tests/visual/`).
- No proprietary assets, names, logos, characters or trademarks are copied. All art,
  names, cosmetics and copy are original and use the new name **Lastfort**.

## Requirement inventory derived from the reference (design-level)

| Area | Reference behaviour (public) | Lastfort mapping |
| --- | --- | --- |
| Match lifecycle | Lobby → bus over island → drop → loot/fight → storm phases → last squad standing → victory screen | `phase`: lobby → bus → playing → ended |
| Bus | Straight randomized line, players jump when doors open, forced drop at end | Deterministic seeded line; `jump` action; forced drop at path end |
| Storm | Ring shrinks in timed phases; wait then resize; DPS grows 1→2→5→8→10; minimap shows next circle and shortest path | 8-phase table scaled to match length; DPS 1/1/2/5/8/10 |
| Health/shield | 100 HP, 100 shield; small shield +25 (cap 50), big shield +50, bandage +15 (cap 75), medkit → 100 | Same values |
| Looting | Floor loot + chests; rarity tiers colour coded; ammo; materials | Chests + floor loot with rarity table |
| Harvesting | Pickaxe on trees/rocks/vehicles gives wood/stone/metal; 500 cap each | Same, seeded resource nodes |
| Building | Wall/floor/ramp/roof, 10 mats each, wood weak/fast, metal strong/slow, edits, placement preview colours | Same, 2D grid tiles with `edit` (door/window) |
| Squads | Solo/Duos/Squads (1/2/4); friendly fire off; teammate structures editable | Same |
| Players | Up to 100 in original; this clone caps at 16 with bots filling | 16 max, deterministic bots |
| HUD | Health/shield bars, hotbar, materials, minimap + compass, storm timer, elimination feed, players-left counter, squad panel | Same, identical across four clients |
| Spectating | After elimination watch teammates/eliminator | Same |
| Victory | "Victory Royale" style banner, placement, eliminations | "Lastfort Victory" banner, placement, eliminations, damage, XP |
| Lobby | Play, mode select, Locker (cosmetics), Battle Pass progression, career stats | Same, original cosmetics, XP → unlocks |
| Networking | Server authoritative, prediction, reconnection | Dart server, JSON over WebSocket, `PROTOCOL.md` |
