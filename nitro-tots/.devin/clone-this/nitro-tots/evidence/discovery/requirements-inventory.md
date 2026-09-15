# Requirements inventory — Nitro Tots

Every item is derived from the public design documentation captured in
`evidence/reference/public-docs-wikipedia-mariowiki.txt` (see
`source-access-boundary.md` for the observed / inferred / inaccessible rule).
Item IDs match `state.json`.

## Routes (Flutter `Screen` enum, `app/lib/main.dart`)

| ID | Screen | Public-doc basis | Verified by |
| --- | --- | --- | --- |
| route-title | Title / splash | observed: series has a title screen with mode menu | `app/test/screens_smoke_test.dart` (`title`), parity `title`, e2e screenshots |
| route-garage | Character + kart select | observed: driver + vehicle selection with stats | smoke test `garage`, parity `garage` |
| route-track | Track / cup select | observed: courses grouped in cups of 4 | smoke test `track select`, parity `track` |
| route-settings | Settings (controls, audio, theme, camera) | inferred: controls table exists; audio/theme are Nitro Tots design | smoke test `settings`, parity `settings` |
| route-online | Online: create / join room by code | observed: online play with rooms; join codes inferred | smoke tests `online (*)`, parity `online`, e2e |
| route-lobby | Lobby (ready-up, profile, settings, bots) | inferred | smoke test `lobby`, e2e `*_lobby.png` |
| route-race | Race / battle HUD | observed: HUD with position, lap counter, item, minimap | e2e `*_racing.png`, `test/verify_room.py` |
| route-podium | Results / GP standings / podium | observed: results, points table, podium | smoke test `podium`, e2e `*_results.png`, `*_matchover.png` |

## Features

| ID | Feature | Class | Verified by |
| --- | --- | --- | --- |
| feat-race-3-laps | 3-lap races with checkpoints, wrong-way detection, lap counter | observed | `sim_test.dart` "bots finish 3 laps on … deterministically" |
| feat-tracks-4 | 4 hand-designed tracks with shortcuts, jumps, boost pads, hazards | observed (count/features) / inferred (layouts) | `sim_test.dart` "every track samples cleanly and has a full grid"; `packages/nitro_core/lib/src/tracks.dart` |
| feat-8-racers-bots | Up to 8 racers, deterministic bots fill empty seats | observed | `server_test.dart`, e2e (3 humans + 5 bots) |
| feat-drift-miniturbo | Drift with charged mini-turbo tiers | observed | `sim.dart` drift charge; e2e autopilot uses drift; manual play |
| feat-slipstream | Slipstream speed bonus when trailing closely | observed | `sim.dart` slipstream; core tests run the mechanic |
| feat-items | Item boxes, 8 original items, position-weighted odds, shield/homing/dropped hazard/boost | observed (rules) / inferred (odds table) | `sim_test.dart` "different seeds produce different item draws"; `items.dart` |
| feat-position-minimap | Live position tracking + minimap | observed | HUD (`hud.dart`), e2e racing screenshots |
| feat-results-points | Race results with points table | observed | `sim_test.dart` "grand prix standings accumulate points" |
| feat-grand-prix | Grand Prix cups across 4 tracks with cumulative points | observed | `server_test.dart` "two clients race a one-lap grand prix…", e2e Sugar Cup 4 races |
| feat-time-trial-ghost | Time Trial with ghost replay | observed | `flow.dart` `PlayMode.timeTrial`, `session.dart` ghost record/playback |
| feat-battle-arena | Battle arena mode (timed, points) | observed | `sim_test.dart` "battle mode ends on the timer and awards points" |
| feat-multiplayer-rooms | Server-authoritative rooms, join codes, lobby → racing → results → match-over | observed (online) / inferred (codes) | `server_test.dart`, e2e |
| feat-reconnect | Reconnect / resume with token | inferred | `server_test.dart` "a player can resume after disconnecting mid-lobby" |
| feat-prediction | Client prediction + interpolation + reconciliation | inferred (standard netcode) | `session.dart`; e2e final hash agreement |
| feat-determinism | Fixed-step 30 Hz sim, seeded RNG, deterministic bots | inferred (test requirement) | `sim_test.dart` "rng is deterministic", "snapshot round-trips" |
| feat-input | Keyboard, touch, mouse/trackpad controls | observed (controls table) | `controls.dart`; smoke tests run on phone/tablet/desktop sizes |
| feat-themes | Light + dark theme, reduce-motion | Nitro Tots design | smoke tests both themes; parity light theme |
| feat-audio-haptics | Original generated audio + haptic feedback | inaccessible (original audio) → original assets | `tools/gen_audio.py`, `audio.dart` |

## Journeys

| ID | Journey | Verified by |
| --- | --- | --- |
| journey-solo-gp | Title → garage → track → GP race → results → podium (bots) | `screens_smoke_test.dart` + manual macOS/web play |
| journey-online-match | Online → create/join room → lobby ready → 4-race GP → results → match-over on web + iOS Simulator + macOS simultaneously | `test/multiplayer-e2e.sh`, `evidence/multiplayer/<stamp>/result.json` |
| journey-reconnect | Disconnect in lobby → resume with token → same seat | `server_test.dart` |
| journey-time-trial | Track → time trial → ghost saved → replayed next run | `session.dart` ghost, manual play |
| journey-battle | Bumper Bowl battle → timer ends → points results | `sim_test.dart` |

## Visual (normalized cross-client parity, web = baseline)

| ID | Screen | Evidence |
| --- | --- | --- |
| visual-title | title | `evidence/parity/reference/title.png` vs `clone/title.png`, `diffs/title.png` |
| visual-garage | garage | same layout under `evidence/parity/` |
| visual-track | track | same |
| visual-settings | settings | same |
| visual-online | online | same |

Normalization is documented in `evidence/parity/visual_parity.json` and
`README.md` ("Cross-platform visual parity").

## Assets / integrations

| ID | Item | Verified by |
| --- | --- | --- |
| asset-fonts | Fredoka + Nunito (OFL) bundled | `app/assets/fonts/OFL-*.txt`, `pubspec.yaml` |
| asset-audio | 21 generated WAVs (19 cues + 2 music loops) | `app/assets/audio/*.wav`, `tools/gen_audio.py` |
| asset-art | Code-drawn karts, characters, tracks, icons | `app/lib/game/*_art.dart` |
| integration-server | Dart WebSocket server, `/health`, `/rooms/<code>`, `/ws` | `server_test.dart` "health endpoint responds", `PROTOCOL.md` |
