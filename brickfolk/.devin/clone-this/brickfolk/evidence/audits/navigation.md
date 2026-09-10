# Navigation audit

Every screen reachable in the clone and how it is reached. Evidence: the visual
tour captures (`visual/web-*.png`, `visual/macos-*.png`) and the match captures
(`<platform>-lobby.png`, `-gameplay.png`, `-results.png`).

| From | To | Trigger |
|---|---|---|
| launch | Sign-in | app start with no saved token |
| launch | Hub | saved token resumes (`resume` message) |
| Sign-in | Hub / Play | valid name -> `hello` -> `welcome` |
| Hub | Play / Avatar / Social / Chat / Profile | bottom bar (phone) or side rail (tablet/desktop) |
| Hub | Daily reward sheet | pips chip / `daily` request |
| Hub / Play | Room lobby | Play on a place card, or party leader launch |
| Hub / Social | Party | create / join by 4-letter code / leave |
| Lobby | Gameplay | countdown reaches zero (server driven) |
| Gameplay | Results | match end (server driven) |
| Results | Lobby | Play again |
| Results / Lobby / Gameplay | Hub | Leave |
| any | Reconnect banner | socket drops; auto-resume on reconnect |

Back navigation: `Navigator.popUntil` to the hub from any room state; the room
route is removed when the server confirms `leave`. Deep programmatic navigation
used by the harness: `AppState.requestScreen` (test/tour mode only).

Discoveries in the final two sweeps: none.
