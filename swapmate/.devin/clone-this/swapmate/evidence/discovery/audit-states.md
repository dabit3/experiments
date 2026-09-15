# Audit: states — loading, empty, error, reconnect, results

Inspected every screen in `app/lib` for each state class; all are implemented
and most are exercised by the four-platform run.

| State | Where | Implementation |
| --- | --- | --- |
| Loading / connecting | `home` | Spinner + "Connecting to server…" while `ConnectionStatus.connecting`; buttons disabled (`_busy`) |
| Offline / error | `home` | `StatusPill` shows Offline / Connecting / Reconnecting / Online; `client.lastError` is rendered inline in the join form (`room_not_found`, `room_full`, …) and via snackbar for local validation ("Enter the 4-letter room code") |
| Empty | lobby / game / results | Empty seat cards read "Open seat · Tap to sit"; move list "No moves yet"; chat "No messages yet."; results rematch shows "Waiting (n/m)" votes |
| Reconnecting | all screens with a room | Top banner "Connection lost — reconnecting…" (`_ReconnectBanner`, safe-area aware); player cards show "Reconnecting…"; server keeps the seat for `reconnectGraceMs`; exponential backoff + resume token in `GameClient` |
| Playing | game | Turn indicator, running clock extrapolated from the last snapshot, check / last-move highlights, legal-move dots, premove badge, reserve trays with counts |
| Promotion | game | Dialog picker (queen / rook / bishop / knight) |
| Confirm destructive | game | Resign confirmation dialog |
| Results | results | Victory / Defeat / Draw card with reason (checkmate, flag, resignation, agreement, stalemate, repetition, abandonment), board summaries, move list, BPGN copy, rematch votes, leave |
| Spectating | lobby / game / results | Spectator chip list, boards read-only, room chat only |

Haptics: `HapticFeedback` on own move / capture / check / game end
(`game_screen.dart`). No audio assets are shipped; this is an intentional
omission recorded in the README (original audio would be created, not copied).

Evidence: lobby / game / results screenshots for all four platforms in the
final `evidence/tests/<run>/`, the widget test `app/test/home_screen_test.dart`
for the home validation state, and the server tests for reconnection.
