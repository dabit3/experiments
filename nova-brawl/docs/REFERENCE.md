# Reference research — Nova Brawl

Researched 13 September 2026 before implementation. Reference: **Dragon Ball
Zenkai Battle Royale (2011)**, Bandai Namco arcade arena fighter. This is an
original two-player adaptation, not a port or a pixel-parity claim.

## Sources accessed

- [Siliconera launch controls, 25 May 2011](https://www.siliconera.com/dress-up-goku-before-a-big-bout-in-dragon-ball-zenkai-battle-royale/):
  joystick plus ki, strike, jump, target switch and guard; combinations trigger
  special moves; grabs and team holds; up to four players.
- [Siliconera screenshot collection, 2 December 2010](https://www.siliconera.com/a-big-bang-of-dragon-ball-zenkai-battle-royale-screens/):
  national network play and published press imagery.
- [Official site archive](https://web.archive.org/web/20160524180127/https:/db-zenkai.com/):
  search-accessible official site entry; describes later 2-on-2 version. Not
  treated as proof of exact 2011 mechanics.
- [Japanese player control guide](https://w.atwiki.jp/dbzenkaibattleroyale/pages/28.html):
  repeated strikes form combos, long jump enables flight, target lock and guard,
  individual projectile variations. The guide includes later characters;
  post-2011 details are not asserted as launch mechanics.
- [IGN summary](https://www.ign.com/games/dragon-ball-zenkai-battle-royal):
  four-player everyone-for-themselves combat and lever/five-button scheme.

## Images directly viewed

1. [Network/character screen](https://www.siliconera.com/wp-content/uploads/2010/12/011.jpg),
   1280×720. Observed: 3D orange-gi fighter on left; strongly spiked dark hair;
   blue wristbands, boots and undershirt; bulky fabric folds, muscular limbs;
   four horizontal player nameplates against a globe.
2. [Energy windup closeup](https://www.siliconera.com/wp-content/uploads/2010/12/041.jpg),
   1280×720. Observed: tight dynamic camera, forward crouch, cupped hands,
   white-core cyan aura, orange/navy costume, angular eyes/brows, grass-topped
   layered rock plateaus, clear blue sky.
3. [Airborne impact](https://www.siliconera.com/wp-content/uploads/2010/12/091.jpg),
   1280×720. Observed: airborne fighters, kick/punch impact with white-yellow
   core and orange edge, radial speed lines, water channels and rounded cliffs.
4. [Beam attack](https://www.siliconera.com/wp-content/uploads/2010/12/061.jpg),
   1280×720. Observed: large blue-white horizontal beam, two-handed stance,
   airborne target, physical terrain and reflective water.

The latter three press screenshots hide the normal combat HUD. Therefore the
Nova Brawl health/energy HUD, timer and portrait mobile touch arrangement are
authored adaptations; their exact source layout was not verified.

## Applied visual and interaction inventory

| ID | Nova Brawl treatment | Evidence class |
|---|---|---|
| V1 | Original spiked gold/ice hair, stern faces, broad shoulders, baggy orange/blue martial clothing and armor | Inspired by viewed characters; original geometry |
| V2 | Layered grass-covered rock islands, blue water/sky, distant mesas | Directly observed terrain motifs |
| V3 | White-core cyan beam, glowing charge aura, yellow projectiles, radial hit shards | Directly observed energy language |
| V4 | Dynamic trailing/target camera, flight poses, fist/kick combos, impact knockback | Observed still poses + documented behavior; exact timing authored |
| G1 | Target lock, flight, boost, dodge, projectile, 3-strike combo, charge, telegraphed beam | Documented categories + requested controls; numerical balance authored |
| N1 | Real guest room networking, two separate native human clients, ready/result/rematch | User requirement; custom authoritative protocol |
| U1 | Health/energy, altitude/lock status, guest lobby, timer, result statistics | Authored iPhone portrait adaptation |

## Scope and provenance

No ROMs, extracted game models, source code, licensed sounds, accounts, or
production endpoints are used. Every mesh, procedural sky, effect and synthesized
audio buffer in the app is original and actually rendered/played at runtime.
Original arcade software was not available, so timing, exact balance, 2011
multiplayer latency behavior and literal screenshot parity remain unverified.

The `clone-this` skill was absent from active discovery. Its complete public
repository was inspected locally (SKILL.md and parity-audit.md) and its durable
run initialized under `.devin/clone-this/nova-brawl/` (ignored). Research provenance,
inventory, state transitions and evidence review follow that workflow. The user's
explicit permission for an approximation and requested PR supersede its strict
zero-pixel-difference gate. No passing parity gate is claimed.

## Known adaptation gaps

Two-player duel rather than the arcade's four-player/team roster; two original
fighters rather than licensed characters; no grabs, team assists, original
costume unlocks or physical arcade cabinet input combinations. The authored
models are stylized low-poly, not the source's textured muscular models.
