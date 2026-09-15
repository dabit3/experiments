# Reference research — Injustice Arcade (2017)

Research date: 2026-09-13. Reference is the Raw Thrills arcade edition, not the console fighter.

## Sources accessed before implementation

- [Raw Thrills product page](https://rawthrills.com/games/injustice-2/): official description explicitly lists card scanning, assembling teams, 200+ collectible cards and two-player tag-team action. The present page includes later Series 5 marketing; it is not a frozen 2017 build.
- [2017 launch reporting and photographs](https://arcadeheroes.com/2017/10/16/dave-busters-launches-injustice-arcade-with-exclusive-cabinet/): contemporary launch information, cabinet and original flyer. Reports bronze/silver/gold rarities and 200 cards.
- [2017 cabinet photograph](https://arcadeheroes.com/wp-content/uploads/2017/10/injustice_arcade1.jpg): inspected image, including the running display and physical controls.
- [Original promotional flyer](https://arcadeheroes.com/wp-content/uploads/2017/10/injustice_flyer.png): inspected image, collectible card framing and character treatment.
- [Official trailer](https://www.youtube.com/watch?v=it1gb6Ws39o): accessible thumbnail inspected; full moving footage was not inspected.
- [Arcade gameplay documentation](https://injustice-mobile.fandom.com/wiki/Injustice_Arcade): secondary source describes quick/strong/block, special-meter tiers, rapid pressing during special, three-character teams, tag controls, and team-card synergies.
- [Operator manual](https://www.manualslib.com/manual/1401407/Raw-Thrills-Injustice-Arcade.html) and [control guide](https://www.manualslib.com/answers/4410673/injustice-arcade-character-gameplay-controls-guide.html): four principal combat controls, red quick, blue strong, white block, jumbo special.

## Observed visual evidence

The flyer has scratched silver uppercase lettering on charcoal; tall collectible cards contain large cinematic portraits, diagonally accented tier borders, names, and stat strips. Characters have strongly contrasting silhouettes: caped muscular figures, slim armored fighters, bulky armored figures. The photographed running cabinet shows a side-on arena with dramatic 3D character lighting and a richly detailed urban interior. Red, blue, white and large illuminated special controls sit under the screen. The trailer thumbnail shows a physical bronze/silver/gold/platinum card display.

## Documented behavior translated to this game

No joystick: automatic spacing lets the player focus on reading attack animations. Quick is fast and interruptible; strong has a visible windup, higher damage and recovery. Hold block to reduce damage, tap just before impact to parry. Meter fills from combat, and the special button spends the currently available tier. Repeated presses during its timed charge add damage. Select three cards, tag surviving reserves, eliminate all three enemy heroes, then agree to rematch. Digital card selection replaces RFID scanning; all six original characters are available without payment.

## Authored design / inference

Exact timings, damage, networking, original powers and synergies are authored here, not extracted from the arcade software. Meter is per hero. Matching three faction cards grants a modest team bonus. Helion/Nocturne/Tempest form the Dawn Pact; Monolith/Hex/Wraith form the Eclipse Order. All mixed teams are legal. The native interface adapts metallic panels, card artwork, health and three-segment power bars to landscape iPhone.

## Access and parity boundary

The arcade executable, original models, animation rigs, voice performances, exact HUD state captures, all 200 cards, economy and cabinet hardware are unavailable. No ROM or proprietary asset was extracted. Reference images remain local research evidence and are not shipped in the app. Artwork, procedural effects and synthesized audio are original. No pixel-parity gate is claimed. The installed clone-this skill's research/inventory/evidence process is applied; its literal zero-pixel gate is not applicable to the user's authorized visual approximation.

## Acceptance inventory

| ID | Requirement | Evidence route |
|---|---|---|
| CARD-01 | Six portrait cards, unique traits, selectable three-hero order, faction synergy | native lobby/manual selection |
| ROOM-01 | Editable LAN address, guest names, create/join, two-player cap, ready | WebSocket integration + two-device capture |
| FIGHT-01 | Quick/strong startup, recovery, interruption, block/parry | deterministic engine tests + touch controls |
| FIGHT-02 | Per-hero health/power, tiered specials and timed mash | engine tests + shared server event log |
| TEAM-01 | Manual tag, knockout replacement, all-three defeat, shared results | engine tests + two-device match |
| NET-01 | Ordered input, authoritative clock/state, resume token, disconnect pause | integration tests + device reconnect |
| LOOP-01 | Two-sided rematch consent, fresh health and power, retained team | tests + recorded rematch |
| ART-01 | Dark metallic HUD, articulated fighters, cinematic panels, audio feedback | screenshot and moving footage inspection |
