# States audit (empty / loading / error / offline)

| Surface | Empty | Loading | Error | Offline / reconnect |
|---|---|---|---|---|
| Sign-in | placeholder hint | busy indicator while connecting | inline `invalid_name` / `name_taken` message | banner |
| Hub / Play | bundled place definitions shown with 0 players until `places` arrives (never blank) | pull-to-refresh | error toast | global reconnect banner |
| Avatar | — | preview paints from local state | `not_enough_pips`, `already_owned` toasts | banner |
| Social | `EmptyState` "No friends yet"; empty requests section hidden | — | `not_found` for a bad party code, `room_full` | banner |
| Chat | `EmptyState` "Say hi! Messages are filtered..." per channel | — | `rate_limited` toast; blocked words shown masked | banner |
| Profile | empty inventory note; locked badges dimmed | — | — | banner |
| Daily reward | — | — | `cooldown` state with next-claim time | banner |
| Lobby | open seats drawn as placeholders | countdown | — | grace period keeps the seat (server test) |
| Gameplay | — | first frame interpolates from the initial snapshot | — | resume re-sends `room` state |
| Results | — | — | — | banner |

Evidence: `harness.log` (state transitions per client), `server-test.log`
(`reconnect within grace keeps the seat and re-sends room state`, error codes).
