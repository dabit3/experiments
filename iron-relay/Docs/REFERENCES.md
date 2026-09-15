# Reference research / 13 September 2026

This is an original, reference-inspired native fighter, not an authorized port.
No ROMs, source game files, trademarks, characters, or extracted assets are used.

## Observed images

- [Bandai Namco: Jin close-up](https://static.bandainamcoent.eu/high/tekken/tekken-7/02-screenshots/1-new-screens/Jin%20%281%29.jpg),
  linked by [official screenshots](https://en.bandainamcoent.eu/tekken/news/new-screenshots-tekken-7).
  Observed: cold steel-blue rim light, red leather panels, metal studs, asymmetric
  angular hair, detailed clothing and a close three-quarter fighter silhouette.
- [Official Steam gameplay screenshot](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/389730/ss_d92a558644ad60ae5814fc4d2bbaebc5abf62fa3.1920x1080.jpg).
  Observed: camera close enough for fighters to fill most of the frame, bent-knee
  weight-bearing poses, airborne hit reaction, orange concentric sparks and red
  electrical arcs. Foreshortened limbs communicate impact.
- [Tag 2 Fight Lab stage](https://www.levelupyourgame.com/wp-content/uploads/2012/04/TekkenTag2-Stage-FightLab-1.jpg),
  from [stage gallery](https://www.levelupyourgame.com/2012/04/17/tekken-tag-2-new-stage-screenshots-brazil/).
  Observed: circular metal inset arena, radial gantry, exposed pipes and supports,
  vents, industrial floor markings and localized emissive lighting.

The files were fetched and visually inspected before implementation. Reference
copies live in session evidence, not in the app bundle.

## Documented behavior

- [Tag 2 HUD](https://www.ign.com/wikis/tekken-tag-tournament-2/HUD):
  two life gauges per team; losing one character loses the round; recoverable
  red life is restored while that character rests.
- [Tag 2 review](https://www.eurogamer.net/tekken-tag-tournament-2-review):
  launcher into tag combo; reserve recovery; risk of switching; tag assault differs
  from a normal switch.
- [Namco / Level Up Your Game combo tutorial](https://www.levelupyourgame.com/2012/09/13/luyg-tekken-tag-tournament-2-tutorial-4-combos/):
  bounds, red life management, tag combos, rage and tag assault are distinct systems.
- [Tekken 7 glossary](https://gameplay.tips/guides/632-tekken-7.html):
  sidestep evades linear attacks, homing moves cover sidesteps, launchers start
  aerial juggles, and screw attacks extend air combos.

## Authored interpretation and limits

Iron Relay uses four original articulated fighters, a red-lit steel arena,
paired slanted gauges, match timer, cinematic ROUND / FIGHT / K.O. language,
short punch/punch/kick strings, linear uppercut launch, a wider tracking kick,
guard, sidestep, bounded air juggles, wall pressure, reserve healing and tag relay.
First to two rounds wins; either active fighter's knockout loses a round.
Frame data, damage, arena geometry and outfits are original and inferred design
choices. The app does not reproduce either game's full move list, skeletal
motion capture, photorealism, rage arts, throws, low/high guard mixups, tag assault
or destructible stages. It implements a tag combo through switching mid-juggle.

Original arcade/console software is unavailable. No matching interactive source
capture, literal pixel comparison, or original gameplay-input timing comparison
was possible. The clone-this research/inventory workflow is used, but its strict
zero-pixel parity gate is **not passed**. The user's explicit approximation and
PR instructions govern this delivery.

## Acceptance inventory

| ID | Requirement | Verification |
|---|---|---|
| IR-01 | Guest name, editable host, room join, two fighter selection | native two-device test |
| IR-02 | Two distinct network peers, ready gate, first-to-two rounds | protocol tests and recording |
| IR-03 | Movement, range, sidestep, guard, attack recovery | simulation tests and touch test |
| IR-04 | Punch strings, kick, launcher, bounded juggle, tag | simulation tests and recording |
| IR-05 | Separate health, reserve recovery, shared KO/winner | simulation tests and recording |
| IR-06 | Result, mutual rematch, disconnect/rejoin with identity | protocol tests and recording |
| IR-07 | Articulated animated fighters, arena camera, hit FX/audio | native capture and visual review |
| IR-08 | Error/occupied room handling and input validation | protocol tests |
| IR-09 | Reproducible native build and lint | build and swift-format |
