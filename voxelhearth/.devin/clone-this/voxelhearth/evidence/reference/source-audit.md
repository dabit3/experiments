# Source audit: Minecraft (public documentation reference)

Captured: 2026-09-09 (UTC) from public documentation. The source game is a
commercial title; it cannot be run, purchased, or captured on this machine.

## Reference-access boundary

- Accessible: publicly documented game design (rules, core loop, modes,
  controls, HUD, crafting/smelting, day/night, mobs, multiplayer concepts) from
  https://minecraft.wiki/w/Gameplay, /w/Controls, /w/Heads-up_display,
  /w/Crafting (fetched 2026-09-09; sanitized notes below).
- Inaccessible: the running original (screens, exact geometry, fonts, timing,
  network protocol, textures, audio, private behaviour). Every visual claim in
  this run is therefore **normalized visual parity against the clone's own
  cross-platform reference** (web build = baseline; iOS/Android/macOS compared
  against it). No literal pixel parity with the original is claimed anywhere.
- No proprietary assets, names, logos, characters, or trademarked content are
  copied. All textures, creature designs, names, and sounds are original work
  under the name "Voxelhearth".

## Observed (documented) facts used as requirements

| ID | Fact | Source |
| --- | --- | --- |
| S-01 | Core loop: place/break blocks in a procedurally generated world; sandbox goals | Gameplay §Core mechanics |
| S-02 | Inventory: 27 storage + 9 hotbar slots; stacks of 64 for blocks/most items; tools do not stack | Gameplay §Inventory |
| S-03 | Crafting: 2x2 grid in inventory, 3x3 grid at crafting table; planks, sticks, crafting table, torches fit 2x2 | Crafting |
| S-04 | Smelting: furnace consumes fuel (coal) to convert e.g. raw iron -> iron ingot | Gameplay §Smelting |
| S-05 | Mobs: passive animals in bright surface areas, hostile monsters in the dark/at night; spawn/despawn in a radius around players | Gameplay §Mobs |
| S-06 | Day/night: 20 real minutes per cycle, 10 day / 10 night; sleeping in a bed skips the night | Gameplay §Daylight cycle |
| S-07 | Survival: health, hunger bars above hotbar; death respawns at spawn point. Creative: bars hidden, unlimited blocks, flying | Gameplay §Game modes |
| S-08 | HUD: hotbar bottom-centre, crosshair, health (hearts) left, hunger right above hotbar; held item name shown briefly above hotbar when switching | HUD |
| S-09 | Controls (PC): WASD move, Space jump, double-tap forward = sprint, Shift sneak, E inventory, Esc pause, 1-9 / wheel hotbar, LMB break, RMB place/use, T chat | Controls |
| S-10 | Shift-click moves stacks between container and inventory | Controls |
| S-11 | Multiplayer: dedicated servers share a persistent world; players see each other; chat | Gameplay §Multiplayer |
| S-12 | Touch (mobile) HUD variant: health/hunger positions differ, extra inventory button beside the hotbar | HUD |

## Inferred (not directly documented in fetched pages; resolved by design decision)

- Tool-appropriate break speeds (pickaxe for stone/ore, axe for wood) — documented elsewhere on the wiki; implemented from general knowledge and recorded as a design table in `voxelhearth_core/lib/blocks.dart`.
- Chunk size 16x16 columns, greedy/culled meshing, frustum culling — engine implementation detail, not a visible rule. The clone renders a packed voxel volume in a fragment shader (ray-march) instead of greedy-meshed geometry; recorded as an intentional deviation (`intentional-renderer`).

## Where the clone intentionally differs (recorded, not hidden)

- Original names/art/audio replaced with Voxelhearth originals.
- A match structure (lobby -> gameplay -> results with an "expedition" score) is added because the clone brief requires a cross-platform match with a shared final score; the sandbox itself remains open-ended.
- World height is 64 blocks (not 384) to keep the mobile/web GPU ray-marcher within budget.
