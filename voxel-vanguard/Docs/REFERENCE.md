# Reference research — 13 September 2026

Reference: **Minecraft Dungeons Arcade (2021)**. Voxel Vanguard uses an original
title, world, characters, geometry, textures, UI and audio. No ROMs, proprietary
code, extracted models or reference images are included in the app.

## Observed

- Mojang announcement: https://www.minecraft.net/en-us/article/minecraft-dungeons-going-arcade
  describes four-player cooperation, nine levels, three primary buttons
  (Melee, Dodge, Range), 60 collectible physical cards, up to five scanned cards,
  and card meters filled by gems and defeated enemies.
- Manufacturer: https://rawthrills.com/games/minecraft-dungeons-arcade/
- Contemporary coverage: https://arcadeheroes.com/2021/05/10/raw-thrills-rolls-out-a-product-page-for-minecraft-dungeons-arcade/
- Direct screenshot, woodland village:
  https://arcadeheroes.com/wp-content/uploads/2021/05/minecraft_arcade_001.png
  Inspected at 1568 × 882: oblique overhead camera; sharply cuboid characters;
  layered grass cliffs with exposed brown sides; cobbled roads; timber roofs;
  warm amber torch pools against cool ambient shade; clustered armored green
  monsters; bright purple/green magical effects; four colored score lanes at
  the top; framed MELEE/RANGE/ARMOR/PET cards and heart-centered status strips
  across the bottom. Cards visibly glow when charged.
- Direct screenshot, icy dungeon:
  https://arcadeheroes.com/wp-content/uploads/2021/05/minecraft_arcade_006.png
  Inspected at 1568 × 882: giant voxel steps, strongly blue-lit stone, warm wall
  lanterns, square heads and limbs, animated action poses, particle motes,
  differentiated armor silhouettes. This is a cinematic boat scene rather
  than proof of the interactive movement camera.

## Adaptation and inference

Native landscape iPhone is appropriate for the joystick and three main combat
buttons. SceneKit provides actual traversable 3D geometry, orthographic oblique
camera, original cuboid heroes/monsters, pixel materials, torch light and shadow.
Two human players cooperate through three connected ruins, two enemy encounters,
loot choices and a telegraphed boss. Red/blue heroes, gem score, framed weapon/
armor cards, hearts, card charge and three attack controls preserve recognizable
design cues. Healing and proximity revive satisfy the requested cooperative
mechanics. Numerical combat balance, boss design, level, mobile HUD arrangement,
network protocol and revive timing are authored interpretations.

## Access boundary and parity claims

The arcade executable, cabinet controls and source assets were unavailable.
Only public screenshots and documented behavior were observed; no original
gameplay was directly exercised. Nine stages, physical card printing/scanning,
four-player cabinet sharing, the full 60-card collection and licensed pets are
outside this implementation. It is an original reference-inspired game, not
literal pixel parity. The clone-this skill was read from a separately fetched
copy after managed-plugin fetching timed out. Its research/evidence inventory
applies; its exact zero-pixel gate is intentionally not claimed as passed,
consistent with the user's explicit permission for visual approximation.
