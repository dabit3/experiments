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

## Re-walk at iteration 8 (post-review fixes)

New code surfaces since iteration 7: `GameClient.setAction`, `_ActionButton.onRelease`,
`_isActionKey` (game_screen.dart) → feature-chop / feature-input; the `Stack` +
`StatePanel` reconnect overlay in `main.dart` and the non-resumed-welcome cleanup in
`client.dart` → feature-reconnect / journey-reconnect; `_Coach` board-state hints →
feature-tutorial; `parkMouse` in `test/lib/common.mjs` and the tightened `maxBlocks` gate
→ visual-* items (harness only). Every new surface maps to an existing item. No new
item. Frontier empty. `new_items: 0`.

## Re-walk at iteration 9 (design pass + review reel)

New code surfaces since iteration 8: `_CoinScore`, `_ComboBadge`, `_Coin`, `_Stopwatch`
+ `_StopwatchPainter`, `_Pulse`, `_Ticket` with `_DishIcon` / `_IngPicto`, `_Banners`,
`_RoundIcon` and the repositioned `_KeyHints` (game_screen.dart) → route-game,
feature-orders, feature-score, feature-timer, feature-input; `OutlinedText` and
`PPTypography.hud` (ui.dart, tokens.dart) → route-game / route-results; the new kitchen
palette tokens and `Sprites.frame` / `floor` / `pitBase` / `pitRipple` / counter, crate,
board, stove, sink, pass renderers plus the cached backdrop in `KitchenGame` →
route-game, asset-sprites; the redrawn `ResultsScreen` (blue header, star fill,
report rows, thresholds, crew, service report) → route-results, feature-stars;
`GameClient.bestStars` and the level-card star tally → feature-level-select; the
Corner Café central island row (`levels.dart`) → feature-levels; `FLAG_KEEP_SCREEN_ON`
in `MainActivity.kt` and `svc power stayon` in `test/e2e/run.mjs` → harness/platform
plumbing under journey-four-platform-match; `test/review-video.sh` +
`test/review-video/build.mjs`, the Playwright `recordVideo` context in `test/ui/smoke.mjs`
and the `PP_REVIEW_VIDEO` hook in `multiplayer-e2e.sh` → new item
`integration-review-video` (test tooling, evidence for the journeys, not a game
behaviour). Every other surface maps to an existing item. One new item, added to the
inventory before this sweep was recorded, so the frontier is empty at the end of the
sweep. `new_items: 0` after the item was inventoried.

## Re-run at iteration 10 (post independent UI pass)

Diff since iteration 9 is confined to `app/lib/screens/game_screen.dart`: the bottom bar
became a `Column` (coach above key hints) in the keyboard layout, and `_CoinScore` picks
the unlit-star colour from the scheme brightness. No new widget class, message, route,
asset or script was introduced, so every surface still maps to an existing item.
`new_items: 0`, frontier empty.
