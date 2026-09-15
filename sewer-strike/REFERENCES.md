# Reference audit — Sewer Strike

Research date: 2026-09-13. Reference: Raw Thrills *Teenage Mutant Ninja
Turtles*, announced and location-tested in 2017; shipping screenshots are from 2018.

## Sources accessed before implementation

- [Official product information](https://rawthrills.com/games/tmnt/): describes
  four-player action brawling, the Nickelodeon series' 3D models, and updated pacing.
- [2017 location test and producer corrections](https://arcadeheroes.com/2017/10/23/test-teenage-mutant-ninja-turtles/):
  joystick, separate jump/attack, large Turtle Power button, color-coded stations.
- [Hardware screenshot gallery](https://arcadeheroes.com/2018/02/26/sewer-level-shredders-throne-room-revealed-new-teenage-mutant-ninja-turtles-arcade-game-screenshots/).
- [Sewer surfing screenshot, inspected](https://i0.wp.com/arcadeheroes.com/wp-content/uploads/2018/02/02_TMNT_RT_Sewer.jpg).
- [Rail tunnel combat screenshot, inspected](https://i0.wp.com/arcadeheroes.com/wp-content/uploads/2018/02/12_TMNT_RT_Sewer.jpg).

## Direct visual observations

Both captures have four persistent player panels across the top: blue, orange,
purple, red. Each has a round masked-head portrait, slanted uppercase name and
score, red health bar with a white cross, and separate vivid green power bar.
Inactive slots stay visible. Active hit counters appear underneath. Characters
have large expressive masked heads, green limbs, gold abdominal shell plates,
dark green rear shells, elbow/knee wraps, and visibly different weapons.

The sewer capture has dark masonry, rusty pipework, green water, spray and pink
utility lights. The rail scene has layered perspective tracks, warning lights,
steam, a train, grounded shadows, airborne characters, and colored player rings.
Enemies include dark humanoid soldiers, small metal creatures, and tall red
mutants. These are true 3D characters on a side-scrolling belt-plane stage.

## Translation into this app

Original, modeled-in-code reptilian heroes Riptide, Cinder, Circuit and Fang use
twin sabers, chained batons, a long staff and twin prongs. The four-slot team HUD,
colored floor rings, jumping weapon silhouettes, hit counters, neon sewer
architecture and separate charge attack follow the observed visual grammar.
Three linked combat sectors take the team from a city service alley to a sewer
conduit and a reactor arena. Enemy waves and a telegraphed armored boss are
authoritative server actors. Pizza-like triangular “power slices” heal.

Exact damage, timing, combos, boss AI, meter costs, revival and network protocol
are **authored/inferred mechanics**, not measurements of the original arcade.
Comic impact words and energetic original audio implement the requested direction.
The four heroes are selectable guest roles, not four pretend human clients.

## Access and parity boundary

The original arcade executable, input capture and licensed production assets are
inaccessible here. No ROMs, extracted assets, trademarks, voices or soundtrack
are bundled. Screenshots are research evidence, not shipped game textures.
Original procedural 3D art and original synthesized music are shipped in the app.
This is a reference-inspired playable approximation; no literal or normalized
pixel-parity gate is claimed. The clone-this skill's research, provenance,
inventory and evidence workflow applies; its zero-pixel-difference/no-commit
defaults are superseded by the user's explicit approximation/PR instructions.

## Finite acceptance inventory

| ID | Requirement | Evidence method |
|---|---|---|
| lobby | editable server, guest names, room codes, unique heroes, ready | two native clients + protocol tests |
| controls | lane movement, jump, directional three-hit combo, special | touch exercise + input event audit |
| combat | differentiated weapons, knockback, invulnerability, enemy windups | deterministic simulation tests + recording |
| co-op | two peers share waves/boss, damage credited per peer | socket tests + simultaneous displays |
| recovery | slices, proximity revive, token reconnect, consensus rematch | simulation/socket tests + native reconnect/rematch |
| result | gate traversal, boss defeated, shared stage clear | full recorded match |
| visual | 3D masked reptiles, four cards, sewer/city, comic FX | footage inspection; approximation only |
| audio | original music, impact/jump/power/clear sounds, mute | native playback + generated audio checks |
