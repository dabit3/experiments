# Final discovery sweep 2 — clone walk (iteration 7)

Method: start from the clone, not the reference. Enumerate every screen/widget class in
`app/lib`, every message constant in `core/lib/src/protocol.dart`, every HTTP route in
`server/lib/src/server.dart`, every client test command in `app/lib/net/client.dart` and
`app/lib/main.dart`, every shipped asset under `app/assets` and the platform folders, and
match each back to an inventory item. Anything without an owning item would be a new
discovery. Independent of sweep 1.

Audits re-read during this walk: source, navigation, roles, states, responsive, data,
assets, accessibility, reliability, rebrand (`audit-*.md`).

## Screens and widgets (`app/lib`)

| Class | Item |
| --- | --- |
| `HomeScreen` (host / join / how to play / server / theme / connection chip) | route-home |
| `_HowToPlaySheet` | route-how-to-play, feature-tutorial |
| auto-join busy panel in `main.dart` (`PP_AUTO`, `?auto=1`) | route-joining |
| `LobbyScreen` (roster, add/remove bot, level grid, code, ready/start, leave) | route-lobby, feature-lobby, feature-level-select, feature-modes |
| `GameScreen`, `_Banners` (countdown, overtime, reconnect), pause overlay, emote sheet | route-game, feature-timer, feature-reconnect, feature-emote |
| `KitchenGame`, `sprites.dart`, `particles.dart` | route-game, asset-sprites |
| `ResultsScreen` (count-up, stars, tiles, rematch/leave) | route-results, feature-stars, journey-rematch |
| `ToastHost` (join errors, viewport report) | route-home (error toast), feature-test-channel |
| `LevelPreview`, `PlatformMark` | feature-level-select, feature-input |
| `theme/tokens.dart` light + dark | feature-themes |

## Protocol constants (`core/lib/src/protocol.dart`)

`hello`, `room.create`, `room.join`, `room.leave`, `room.ready`, `room.setLevel`,
`room.addBot`, `room.removeBot`, `room.start`, `room.rematch`, `input`, `ping`,
`test.report`, `welcome`, `room.state`, `game.snapshot`, `game.results`, `pong`, `error`,
`test.input`, `test.command` — all documented in `PROTOCOL.md` and owned by
integration-server-ws / feature-lobby / feature-modes / feature-reconnect /
feature-test-channel. `ping`/`pong` drives the RTT chip (route-home, route-game).

## HTTP routes (`server/lib/src/server.dart`)

Always: `GET /health`, `GET /levels`, `GET /ws` → integration-server-ws,
integration-test-http. Only with `--test-harness`: `/test/rooms*`,
`/test/rooms/<code>/{start,rematch,bots}`, `/test/rooms/<code>/players/<id>/{input,command}`,
`GET /test/clients`, `POST /test/clients/<id>/command` → feature-test-channel,
integration-test-http (regression test proves absence without the flag).

## Client test commands

`report ready start rematch addBot setLevel emote clearInput` (client) and
`theme join host leave howto dismiss` (app) → feature-test-channel, journey-home-loop.

## Launch parameters (`app/lib/config.dart`)

`PP_SERVER PP_ROOM PP_NAME PP_LEVEL PP_AUTO` via `--dart-define`, URL query,
`simctl launch` env, or `am start --es` extras → route-joining, feature-test-channel.

## Assets and identity

`app/assets/fonts` (Nunito, JetBrains Mono + OFL licences) → asset-fonts. Launcher
icons, web manifest/favicon, iOS/macOS/Android display names and bundle ids →
asset-launcher-icons, asset-copy (audit-rebrand.md). No audio files present — matches the
recorded limitation, not a missing item.

Result: every enumerated surface maps to an existing verified item. No new item
discovered. Frontier empty. `new_items: 0`.
