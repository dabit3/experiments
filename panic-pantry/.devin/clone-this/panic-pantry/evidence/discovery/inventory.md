# Panic Pantry — requirement inventory (detail for `state.json` items)

Reference boundary: the source (Overcooked) is a commercial title that was neither run
nor purchased; requirements were inventoried from public documentation only
(`reference-overcooked.md`). Every item below therefore states the *documented* source
behaviour it derives from, how Panic Pantry implements it, and the executable test that
verifies it. "Visual" items are normalized comparisons between Panic Pantry's own four
clients (web is the reference), never against the original.

Paths are relative to `panic-pantry/` unless they start with `evidence/`
(relative to this run directory).

Common test fixtures: server on `ws://127.0.0.1:8787/ws`, room `E2E4` / `VIS1`, level
`corner-cafe`, seed `23`, deterministic bot planner (`server/bin/plan.dart`), fixed
20 Hz simulation step. Fresh-session: every harness run starts a new server process and a
new room; the clients are launched cold (`PP_AUTO=1`).

## Routes (screens)

| ID | Screen | Preconditions / entry | Controls and states | Implementation | Test |
| --- | --- | --- | --- | --- | --- |
| route-home | Home | app start without `PP_AUTO`, or after *Leave* | Host kitchen, Join (4-letter code field, validation), How to play, Change server (URL field), Toggle theme; connection chip (offline/connecting/connected); feature chips | `app/lib/screens/home_screen.dart`, `app/lib/main.dart:_screen` | visual home-{ios,android,macos} (`evidence/diffs/visual-parity.json`; the harness puts every native client and the web reference on this screen and the captures match); `test/ui-smoke.sh` → `evidence/tests/ui-smoke/` (leave → home, join missing/full room → error toast and stay on home, host from home, dark/light); `evidence/discovery/audit-navigation.md` |
| route-joining | Auto-join loading | `PP_AUTO=1` while connecting / joining | busy `StatePanel` "Joining kitchen…"; times out to home with error toast | `app/lib/main.dart:_screen`, `app/lib/widgets/ui.dart:StatePanel` | E2E and visual harness launch every client through this state (`*-lobby.png` must show the lobby, not this panel: `test/visual/run.mjs` `painted` check) |
| route-how-to-play | How to play sheet | Home → *How to play*, Lobby → help icon | scrollable tutorial (stations, actions, rules, controls per platform), *Got it* closes | `app/lib/screens/how_to_play.dart` | `test/ui-smoke.sh`: opened over home in both themes and dismissed, home route intact underneath (`evidence/tests/ui-smoke/03-how-to-play.png`, `07-how-to-play-dark.png`, `04-home-after-dismiss.png`, `summary.json`) |
| route-lobby | Lobby | Host or Join succeeded | roster (4 seats, colours, platform label, ready chips, `(you)`), Add/Remove bot (host), level select grid with live map previews, round time and star thresholds, join code with copy + snackbar, latency chip, rematch counter, Ready toggle, Start cooking (host, enabled when all ready), Leave, help, theme | `app/lib/screens/lobby_screen.dart`, `app/lib/widgets/level_preview.dart` | E2E `*-lobby.png` (4 platforms), visual lobby-{ios,android,macos}, server test "hello, create, join, ready, start" |
| route-game | Gameplay | host pressed Start; 3 s countdown | Flame kitchen canvas, HUD (timer, score, combo, stars), ticket rail with draining timers, on-screen joystick + Grab/Action/Dash/Emote (touch), keyboard (WASD/arrows; Space/J/Enter grab; E/K/Shift action; F/L dash; 1–6 emotes, T emote sheet; Esc menu), click/tap-to-move, pause menu (back / switch theme / leave / ping), emote sheet, reconnect banner, overtime banner, countdown overlay | `app/lib/screens/game_screen.dart`, `app/lib/game/*.dart` | E2E `*-gameplay.png`, `*-gameplay-late.png`, `four-way-match.mov` |
| route-results | Results | match finished (`game.results`) | count-up score, star reveal animation, stat tiles (served, tips, best combo, expired, burnt, wrong), dishes served chips, Rematch (host) / waiting text, Leave kitchen | `app/lib/screens/results_screen.dart` | E2E `*-results.png` and `resultsMatch` assertion; visual results-{ios,android,macos} |

Navigation edges: home →(Host)→ lobby; home →(Join code)→ lobby | error toast;
home/lobby →(help)→ how-to-play →(Got it / back)→ previous; lobby →(Start)→ game;
game →(timer + overtime)→ results; results →(Rematch)→ lobby; any →(Leave)→ home;
game →(Esc / menu)→ pause overlay →(Leave match)→ home. Screen transitions are
animated (`AnimatedSwitcher`); the outgoing screen keeps its own room/results model
so a theme or viewport change during the fade cannot dereference a cleared room
(regression found and fixed by `test/ui-smoke.sh`, check "web console has no errors").
There are no URL routes:
the app is a single-window state machine (`main.dart:_screen`), and the web build
reads its configuration from the query string (`server`, `room`, `name`, `level`,
`auto`) — documented in README and verified by the E2E web launch.

## Features

| ID | Documented source behaviour | Panic Pantry implementation | Test |
| --- | --- | --- | --- |
| feature-orders | Orders arrive on a rail with a time bar; two queued at start | `core/lib/src/simulation.dart` (`initialOrders 2`, `maxOrders 4`, expiry −10 and combo reset); HUD rail in `game_screen.dart` | `core/test/simulation_test.dart` "bot rounds are deterministic and score" (expired count), E2E results `expired` field |
| feature-score | +20 per served dish, tip by remaining time, −10 expired, combo up to ×4 | `core/lib/src/scoring.dart` (base 20, tips 8/5/3 × combo, combo 1..4) | `simulation_test.dart` "scoring tiers"; E2E asserts score/tips/bestCombo identical on 4 clients + server + plan |
| feature-stars | 3-star rating from thresholds scaling with player count | `core/lib/src/levels.dart` per-level thresholds × player-count factor; shown in lobby and results | "scoring tiers" test; E2E asserts `stars` identical |
| feature-chop | Raw ingredient chopped on a board while Action is held | `simulation.dart` chop progress per held tick; client `setAction` keeps the held flag on every input tick (keyboard key-up / button release clears it); sprite progress bar | plan-driven E2E serves 11 dishes requiring chopped ingredients; core test "chopping needs the action input held across ticks" |
| feature-cook | Pot on stove cooks with a timer; too long → burnt → fire | `simulation.dart` cook 7 s, burn after 12 s more, ignite | core test (burnt counter), E2E `burnt` field asserted |
| feature-fire | Fire spreads to neighbours; extinguisher sprayed with action | `simulation.dart` fire spread + extinguisher item (`items.dart`) | core test "bot rounds…" covers extinguisher path when fires happen; simulation unit |
| feature-plates | Plate, serve at pass, dirty plates return, sink washes | `simulation.dart` plate stack, return delay 10 s, sink progress | E2E served=11 requires plate cycle (3 plates on Corner Café); core test |
| feature-wrong-serve | (Design choice) serving an unordered dish is refused | `simulation.dart` refuses serve, increments `wrongServes` | E2E asserts `wrongServes` identical (0) |
| feature-floor | Items can be dropped anywhere without penalty | `simulation.dart` drop on floor tile | core test (bots drop/pick) |
| feature-dash | Dash for speed | `simulation.dart` dash impulse; Shift / Dash button | core determinism test uses dash in bot plan |
| feature-emote | Quick communication | `input.emote` (six emotes: `1`–`6` keys, `T`/smile button sheet, `emote` test command); bubbles rendered by `kitchen_game.dart` | server test harness test (client test channel `emote`) |
| feature-levels | Kitchens with distinct gimmicks | 5 hand-designed levels: training, corner-cafe, conveyor-canteen (belts + wall), split-shift (sliding half), drift-deck (ferries) | `simulation_test.dart` "levels parse…", "gimmick levels…", "moving platform tiles…" |
| feature-level-select | World map / level select | Lobby level grid with live previews, host-only, broadcast via `room.setLevel` | server test (setLevel through test channel), lobby screenshots |
| feature-modes | 1–4 player co-op; bots fill seats | rooms of 4 seats, `room.addBot`/`removeBot`, deterministic bot planner | server test "hello, create, join, ready, start, results and rematch" (2 humans + 2 bots via `room.addBot`, host-only check, full round to results); E2E ran 4 human-equivalent clients + 0 bots |
| feature-timer | Round timer, overtime, results | `levels.dart roundSeconds`, 5 s overtime, `Phase.finished` → results | E2E completes a full round; `four-way-match.mov` |
| feature-lobby | Rooms, join codes, ready/start/rematch | `server/lib/src/room.dart`, 4-letter codes, host controls | server test "hello, create, join, ready, start, results and rematch" |
| feature-reconnect | Disconnected chef keeps seat and resumes | token resume in `room.dart`, client auto-retry + banner | server test "reconnect with token resumes seat mid-match" |
| feature-lag-comp | Late pickup/drop still lands on intended tile | input carries `facing` tile; server applies it | `PROTOCOL.md` `input.facing`; server test harness (scripted input) |
| feature-themes | Dark and light | `tokens.dart` `buildTheme`, toggle on every screen, `theme` test command | visual harness sets theme via command (`run.mjs`), screenshots |
| feature-input | Keyboard + touch + mouse idiomatic per platform | `game_screen.dart` shortcuts, joystick, tap-to-move; on-screen controls auto-shown on touch platforms | E2E: iOS/Android show touch controls, macOS/web keyboard hints (screenshots) |
| feature-tutorial | Tutorial | Training Kitchen level + How to play sheet | level test; sheet inspection |
| feature-bots | Server-side deterministic bots | `core/lib/src/bot.dart`, `server/bin/plan.dart` | "bot rounds are deterministic and score" (two runs equal), E2E plan == server == clients |
| feature-test-channel | Automation hooks | HTTP `/test/rooms…` (room-scoped) and `/test/clients…` (connection-scoped, reaches clients on the home screen), `test.input`, `test.command` (`report`, `ready`, `start`, `rematch`, `addBot`, `setLevel`, `emote`, `clearInput`, `theme`, `join`, `host`, `leave`, `howto`, `dismiss`), `test.report` | server tests "test harness…" and "test harness reaches connected clients outside a room"; E2E, visual and ui-smoke harnesses |

## Journeys

| ID | Journey | Test |
| --- | --- | --- |
| journey-four-platform-match | web + iOS Simulator + Android + macOS join `E2E4`, lobby → countdown → gameplay → overtime → results; final score/stars/served/tips/expired/bestCombo/wrongServes/burnt identical on all four clients, the server and the offline plan | `evidence/e2e/<final>/summary.json`, `e2e.log`, screenshots, `four-way-match.mov` |
| journey-rematch | results → host rematch → lobby → second match in same room (match counter increments, new seed derivation) | server test "…results and rematch" |
| journey-reconnect | drop the socket mid-match, reconnect with token, seat and score resume | server test "reconnect with token resumes seat mid-match" |
| journey-home-loop | auto-host → lobby → leave → home (room closed server-side) → how-to-play → dismiss → bad join code → full-room join → theme toggle → host on Drift Deck → lobby → leave | `test/ui-smoke.sh` → `evidence/tests/ui-smoke/summary.json` (9/9), `smoke.log`, screenshots `01-lobby-light` … `08-lobby-dark` |
| journey-solo-with-bots | one client hosts, adds a bot, readies, starts, finishes | server test "hello, create, join, ready, start, results and rematch" (host adds two bots, all ready, start, results with `served > 0`, results identical on both sockets and via HTTP); "test harness…" test creates a room with `bots: 1` through `/test/rooms` |

## Visual cases (normalized cross-client parity)

Nine pairs: states `home`, `lobby`, `results` × clients `ios`, `android`, `macos`, each
against the web build sized to that client's logical viewport and pixel ratio. Method,
bounds and pixel metrics: `evidence/diffs/visual-parity.json` (+ `.log`); sensitivity
proof: `evidence/diffs/visual-selftest.log`. Raw captures: `evidence/reference/<state>-web-for-<platform>.png`,
`evidence/clone/<state>-<platform>.png`; normalized pairs `*.normalized.png`; heat-maps
`evidence/diffs/<state>-<platform>{,.normalized,.core}.png`.

## Assets

| ID | Requirement | Provenance |
| --- | --- | --- |
| asset-fonts | Typography scale | Nunito (SIL OFL) and JetBrains Mono (SIL OFL) bundled in `app/pubspec.yaml`; no proprietary fonts |
| asset-sprites | Chefs, tiles, ingredients, pots, plates, fire, particles | drawn procedurally in `app/lib/game/sprites.dart`, `particles.dart`; original |
| asset-icons | UI iconography | Material Symbols (Apache 2.0) via `Icons.*_rounded` |
| asset-copy | Product name, dish names, chef names, level names | original strings in `core/lib/src/levels.dart`, `items.dart`, screens; no source trademarks |
| asset-launcher-icons | Launcher icons (iOS, Android, macOS, web + favicon) and web manifest identity | generated by `app/tool/make_icons.swift` (original pot/steam/checker mark, CoreGraphics); `app/web/manifest.json`, `index.html`, `Info.plist` carry the Panic Pantry name; verified by `evidence/discovery/audit-rebrand.md` |

## Integrations

| ID | Requirement | Verification |
| --- | --- | --- |
| integration-server-ws | JSON-over-WebSocket protocol v1 between clients and the authoritative server | `PROTOCOL.md`; server tests; E2E (four platforms speak it) |
| integration-test-http | HTTP API: `/health`, `/levels` always; `/test/rooms…` and `/test/clients…` only with `--test-harness` (unauthenticated automation channel, off by default) | server tests "test harness…", "test harness reaches connected clients outside a room" and "test harness routes are absent unless enabled"; E2E, visual and ui-smoke harnesses start the server with the flag |
