# Reference audit — Metro Impact

## Selected edition

**Super Street Fighter II Turbo, Capcom, 1994 CPS-II arcade** throughout. Not
Alpha, Street Fighter III, HD Remix or Street Fighter 6. Research performed
2026-09-13 before implementation.

### Sources

- Screenshot inspected directly:
  https://www.syltefar.com/screenshot/?id=289
  (image https://syltefar.com/images_full/ssf2t.png).
  The 384×224 image shows Ryu versus Fei Long: yellow health interiors with
  white outlines, red lost-health areas, mirrored portraits and blue names,
  central red KO box and amber two-digit timer; small corner super gauges.
  Fighters have strong black outlines, stepped highlight/shadow bands,
  anatomically articulated silhouettes, and grounded elliptical shadows.
  Stage has saturated teal railings, orange rock, blue water, perspective floor.
- https://www.fightersgeneration.com/games/super-sf2t.html
  Read description of Super Turbo's new super meter, new animations, fast
  combat, and distinction from the later redrawn HD Remix.
- https://wiki.supercombo.gg/w/Super_Street_Fighter_2_Turbo/System
  Read normal attack speed/recovery, proximity and crouch/jump variants,
  guarding, impact freeze, and super-meter rules.
- https://wiki.supercombo.gg/w/Super_Street_Fighter_2_Turbo/Controls_and_Notation
  Read grounded and aerial normals and super reset each round.
- Official Capcom product listing:
  https://store.steampowered.com/app/1556722/Capcom_Arcade_StadiumSuper_Street_Fighter_II_Turbo/
  Identifies Capcom as developer/publisher and the available arcade reissue.
- Official platform listing:
  https://www.nintendo.com/us/store/products/capcom-arcade-stadiumsuper-street-fighter-ii-turbo-70050000025539-switch/
  Identifies 1–2 player versus fighting and Japanese/English versions.

## Observed, interpreted, inaccessible

**Observed visually:** the screenshot composition, pixel outlines, segmented
palette, colorful scenic stage, symmetrical life/portrait HUD, corner super
bars, low camera and fighter-to-stage proportions.

**Documented:** hit freeze, normals with startup/recovery, standing/crouching/
airborne variations, guard, projectiles, meter, super attacks and rounds.

**Original interpretation:** Metro Impact's harbor at sunset, Kai (balanced
wave martial artist), Rhea (long-range kickboxer), authored animation poses,
music and effects. Dedicated special/super buttons suit iPhone touch input.
Frame timings, damage and network model are our own, not measured Capcom data.

**Inaccessible:** original executable/ROM, deterministic matching game states,
frame-by-frame source animation captures and original audio. No ROM extraction
or assets copied into the app. Pixel identity and exact balance are not claimed.
The clone-this skill's zero-pixel-difference gate is intentionally **not passed**:
the user authorizes original art and approximation. Its research, inventory,
provenance and evidence workflow applies; exact parity and its no-commit default
are superseded by the explicit task.

## Finite implementation / evidence inventory

| ID | Requirement | Acceptance evidence |
|---|---|---|
| L1 | Guest name, editable LAN server, create/join code, two character choices | Native lobby + network integration test |
| N1 | Distinct peers, ordered inputs, authoritative collision, shared state | WebSocket integration tests and two-device recording |
| G1 | Walk, jump, crouch, stand/crouch guard | Combat tests and native touch path |
| G2 | Fast light, committed heavy, airborne/low variants | Combat tests, visible poses |
| G3 | Projectile, meter, super | Combat tests, recorded live match |
| G4 | Hitstop, hit/block effects, knockback, KO, best-of-three | Combat tests + shared recorded result |
| V1 | Pixel fighters, saturated scenic stage, mirrored HUD, brush title | Full native screenshot, qualitative comparison |
| A1 | Original audible soundtrack and action sounds | Native audio playback, WAV resources |
| R1 | Ready, result, unanimous rematch, disconnect pause/rejoin | Server tests + two-device evidence |

Reference screenshot is retained locally under the ignored research run, not
distributed as a game asset. The app's original art generator and audio generator
are included for reproducibility.
