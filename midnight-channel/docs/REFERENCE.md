# Reference audit — September 13, 2026

Reference: **Persona 4 Arena (2012)**. New identity: **Midnight Channel**.

## Directly observed

- [Publisher-supplied UI screenshots hosted by WorthPlaying](https://worthplaying.com/article/2012/6/26/news/86484-persona-4-arena-all-shows-off-user-interface-screens/).
- [Controller screen, 1280×720](https://worthplaying.com/wpimages/p/e/persona4arena/336986.jpg): warm golden-yellow header, diagonal cuts, black fighter silhouettes with yellow outline, blue secondary bursts, oversized condensed slanted type and narrow information footer.
- [Character screen, 1280×720](https://worthplaying.com/wpimages/p/e/persona4arena/336984.jpg): large anime character artwork, independent supernatural companion art, curved tarot-card selection row, oversized black/white labels over saturated color.
- [Box art](https://worthplaying.com/wpimages/p/e/persona4arena/335657.jpg): jagged red/yellow/white graphic shapes against black. This image is box art, not combat evidence.

## Documented mechanics

- [IGN: SP/Persona/Burst gauge usage](https://www.ign.com/wikis/persona-4-arena/SP/Persona/Burst_Gauge_Usage): four cards lost when a visible companion or its owner is hit, ten-second break, 50-SP supers, SP earned on attacks/blocks/damage, low-health awakening.
- [Dustloop gameplay primer](https://www.forums.dustloop.com/topic/4931-p4a-gameplay-primer/): yellow health with recent damage trail, attack buttons, jump, defense, companion resources and special attacks.
- [Giant Bomb game description](https://giantbomb.com/wiki/Games/Persona_4_Arena): burst escape pushes away attackers, rounds and timer, life/SP/card/burst gauges.

## Interpretation implemented

Landscape iPhone is the primary platform: simultaneous direction and attack touch controls suit the side-on fighter. Golden broadcast interface, checkerboard/static, animated versus cards, two original rivals (Rei / silver hair, sword and black coat; Mika / red hair, white jacket and scarf), individually rendered articulated spectral companions (Antenna / cyan plated knight; Redshift / red winged mask), rooftop transmission stage, hit sparks, hitstop and camera shake.

The stage, portrait cards and combat pose sheets are original generated illustrations used inside the app. Each playable fighter has 12 adult-proportioned, shaded anime poses with expressive faces, costume folds and articulated attacks; each independently rendered companion has four poses. SpriteKit selects poses using authoritative move/frame state and adds continuous breathing, recoil, approach, afterimages and glow. These are authored key-pose animations, not traced commercial frames. The music and effects are synthesized locally. No ROM, extracted game assets, or original trademarks are bundled.

## Evidence boundary

The commercial reference executable was not accessible. Timing, reach, frame data, exact animation poses, stage composition and balancing are authored interpretations. This is a two-character inspired fighter, not a reproduction of the complete roster/story/training content. There is no literal pixel-parity or strict clone-this gate claim. User-approved approximation and explicit PR instructions override that skill's zero-difference and no-commit requirements.

## Acceptance inventory

| ID | Requirement | Verification |
|---|---|---|
| NET-01 | Two independent native peers share a room | Recorded simulator test + real WebSocket test |
| COM-01 | Light/heavy, range, jump and guard | Engine tests + native manual controls |
| COM-02 | Visible companion, four cards and ten-second break | Engine tests + footage |
| COM-03 | Burst escape and earned meter/super/awakening | Engine tests + footage |
| FLOW-01 | Both ready, versus, best-of-three, result, rematch | Recorded native test |
| NET-02 | Ordered input, peer limit, secure resume, offline pause | Protocol tests + rejoin test |
| VIS-01 | Golden broadcast, cards, checkerboard, articulated rivals | Native screenshot/footage inspection; approximate only |
| AUDIO-01 | Audible original loop and feedback | Native audio playback; capture capability reported separately |
