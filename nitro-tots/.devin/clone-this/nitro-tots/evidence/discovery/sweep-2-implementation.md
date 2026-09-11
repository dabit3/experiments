# Final discovery sweep 2 — implementation-driven (code enumerations → inventory)

Method: independently enumerate every screen, play mode, game mode, item, track,
protocol message and asset from source, and confirm each is covered by an
inventory item. Anything uncovered would be a new requirement.

## Screens (app/lib/main.dart)
enum Screen { title, garage, track, settings, online, lobby, race, podium }
→ route-title route-garage route-track route-settings route-online route-lobby route-race route-podium (8/8 covered)

## Play modes (app/lib/state/flow.dart) / game modes (nitro_core sim.dart)
enum PlayMode { grandPrix, quickRace, timeTrial, battle, online }
enum GameMode { race, timeTrial, battle }
→ journey-solo-gp, feat-grand-prix (grandPrix); journey-solo-gp (quickRace); journey-time-trial (timeTrial); journey-battle (battle); journey-online-match (online)

## Items (nitro_core items.dart, enum ItemKind)
turbo tripleTurbo rocket orb slick shield zap comet (8)
→ feat-items

## Tracks / arena (nitro_core tracks.dart)
8:  name: 'Sprinkle Speedway',
44:  name: 'Mossy Hollow',
95:  name: 'Tin City Loop',
145:  name: 'Frostbite Pass',
194:  name: 'Bumper Bowl',
252:  Cup(id: 'sugar', name: 'Sugar Cup', trackIds: ['sprinkle', 'mossy', 'tincity', 'frostbite'], color: 0xFFFF6B9D),
253:  Cup(id: 'nitro', name: 'Nitro Cup', trackIds: ['frostbite', 'tincity', 'mossy', 'sprinkle'], color: 0xFF00E5FF),
→ feat-tracks-4, feat-battle-arena

## Roster (nitro_core roster.dart)
characters: 'Pip' 'Bea' 'Juno' 'Ozzie' 'Mabel' 'Kiki' 'Rocco' 'Tank'
karts: 'jellybean' 'Jellybean' 'tincan' 'Tin Can' 'bubble' 'Bubble Buggy' 'pinewood' 'Pinewood Racer' 'rocketscoot' 'Rocket Scoot' 'bigwheel' 'Big Wheel' 
→ route-garage, rebrand audit

## Protocol message types (nitro_core protocol.dart)
'hello' 'resume' 'create_room' 'join_room' 'leave_room' 'set_ready' 'update_profile' 'update_settings' 'start_match' 'input' 'ping' 'test_report' 'next_race' 'welcome' 'error' 'room_state' 'match_start' 'snapshot' 'race_finished' 'gp_standings' 'match_over' 'pong' 'player_left' 
→ feat-multiplayer-rooms, feat-reconnect (resume), feat-prediction (snapshot/input), integration-server

## Assets
fonts: Fredoka.ttf Nunito.ttf OFL-Fredoka.txt OFL-Nunito.txt 
audio: 21 wav files
→ asset-fonts asset-audio asset-art

## Result
0 new requirements; every enumerated screen, mode, item, track, message and asset
is covered by a verified inventory item. Frontier empty. All ten audits re-checked
(source navigation roles states responsive data assets accessibility reliability rebrand).
