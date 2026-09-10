# Audit: navigation — routes and application structure

Swapmate is a single-window game client; its "routes" are the four screens
selected from the room phase reported by the server (`app/lib/main.dart`,
`AnimatedSwitcher` over the phase):

| Screen | Selected when | Entry / exit |
| --- | --- | --- |
| `home` | `room == null` | Create a room, Play with bots, Join by 4-letter code (also `?room=CODE` deep link on web, `SWAPMATE_ROOM` env / launch argument on native) |
| `lobby` | `room.phase == lobby` | Seat cards for both teams, time-control picker, bots, ready, Start (host), spectator list, Leave |
| `game` | `room.phase == playing` | Two boards, reserves, clocks, move list, chat sheet/panel, resign / draw, Escape clears selection |
| `results` | `room.phase == finished && game.isOver` | Result card, per-board summary, move list, Copy BPGN, Rematch, Leave |

Deep links and parameters (`app/lib/src/app_config.dart`): `server`, `name`,
`room`, `theme`, `autoconnect`, `testId` from the web query string, from
`SWAPMATE_*` environment variables, from iOS `simctl launch` / Android `adb`
extras (native method channel) or from `--dart-define`s.

Overlays: promotion picker dialog, resign confirmation dialog, phone chat
bottom sheet (dismiss by tap-out / Escape), toast snackbars for copy/join
errors, reconnect banner (top, safe-area aware). No not-found route exists:
an unknown room code produces the `room_not_found` error toast on `home`.

Back / refresh: reloading the web client with a stored resume token reclaims
the seat (server `reconnectGraceMs` grace); leaving via the Leave button
returns to `home`. Verified live in the four-platform run (lobby → game →
results → leave → spectate relaunch) — `evidence/tests/<final>/e2e.log`.
