# Audit: roles

There are no user accounts. The only permission boundary is **host vs guest**
inside a room, plus **server bots** as non-human seats.

| Capability | Host | Guest | Bot | Verified by |
| --- | --- | --- | --- | --- |
| Create room / choose level | yes | no (`room.setLevel` rejected) | - | server test "hello, create, join, ready, start, results and rematch" (`evidence/tests/unit-tests.log`) checks the non-host `setLevel`/`addBot`/`start` paths are refused with `error` |
| Add / remove bot | yes | no | - | same test; lobby shows the controls only for the host (`lobby_screen.dart`, `*-lobby.png`: only the host seat has the bot buttons) |
| Start match | yes, once all humans ready | no (button hidden, server refuses) | - | same test; E2E starts via the harness `POST /test/rooms/E2E4/start` |
| Rematch | yes | waits ("Waiting for host") | - | same test (`results_screen.dart`) |
| Ready toggle, emotes, gameplay input | yes | yes | server-driven | E2E: all four human seats send inputs; `feature-emote` test |
| Leave | yes (host migrates to next human) | yes | removed with room | ui-smoke "empty room is closed on leave"; `room.dart` host migration |
| Reconnect with token | yes | yes | - | server test "reconnect with token resumes seat mid-match" |

Automation surface (`/test/*`, `test.command`) is a fourth "role" that is
only available when the server is started with `--test-harness` /
`PP_TEST_HARNESS=1`; without it the routes return 404 (server test "test
harness routes are absent unless enabled").
