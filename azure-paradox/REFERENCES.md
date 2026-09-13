# Azure Paradox reference audit

Research completed before implementation on 2026-09-13.

## Accessible sources

- Official *BlazBlue Chronophantasma Extend* interface manual:
  https://www.h2int.com/games/bbcpex/ps4/en/game_screen/
- Official screenshot, inspected directly:
  https://www.h2int.com/games/bbcpex/ps4/en/img/game_screen/ss01-sp.jpg
- Official actions and combat manual:
  https://www.h2int.com/games/bbcpex/ps4/en/action/
- Contemporary screenshot index (2015):
  https://www.playstationlifestyle.net/2015/06/23/e3-2015-blazblue-chrono-phantasma-extend-screenshots/

## Observed

The official screenshot has angular silver/gold/blue life frames across the top,
portraits outside the bars, a large centered clock in a jewel-like surround,
separate thin barrier gauges and two bottom heat gauges. Large italic hit counts
and "HEAT" text sit in the open space beside the fighters. Detailed anime sprites,
flowing contrasting costumes, diagonal light streaks and brilliant hit sparks
stand against a richly painted, layered fantasy setting.

The manual explicitly documents character-specific Drive actions, heat gain on
contact, 50%-cost Distortion Drives, barrier depletion/Danger, aerial movement,
round wins and combo counters. It also documents mechanics beyond this assignment
(throws, Overdrive, Rapid Cancel, Astral Heat, training/story/arcade modes).

## Adaptation and inference

Azure Paradox uses two original fighters: Seraph, a crimson-coated swordsman whose
Rift Drive steals life, and Lyra, an ivory/cobalt lance mage whose Frost Drive
launches a crystal projectile and briefly freezes its target. Motion, frame data,
damage, hitboxes, music, stage, costumes and animation are authored approximations.
The controls are adapted to landscape iPhone touch: movement, double jump, air
dash, light/medium/heavy, Drive, barrier and 50-heat super. These are design
decisions, not claims about original internal frame data.

Original generated art is used in the actual game: a moonlit celestial cathedral
and eight-pose sprite sheets for each fighter, with authored animation and effects.
No ROMs, extracted game assets, game code, music or original character names are
included. The reference screenshot is research evidence only and is not bundled.

## Evidence boundary

Original arcade/console software was not accessible. No equivalent-state image
diff, interactive source test, original netcode comparison, or literal pixel
parity is claimed. The clone-this research/evidence workflow was read from
`.devin/skills/clone-this/SKILL.md` in a separate read-only clone of
https://github.com/dabit3/clone-this. Its strict zero-difference completion gate
does not pass for an original reference-inspired fighter; the user's explicit
allowance for visual approximation governs this delivery. Native functionality
and two-device behavior are verified separately from reference fidelity.
