# Final arcade UI regression

Fresh production server on port 8790; web, native iOS Simulator and native
macOS clients. Three human players and one server bot shared room NVCK.
The testing agent rebuilt all three clients from the corrected UI source.
This pass predates the final SafeArea backdrop alignment and test-capture
diagnostics. The later `partial-visual-current` run verifies the final
web/iOS/macOS rendering; this report records the input and multiplayer
workflows exercised here.

## Passed

- iOS preserved GWYD rather than autocorrecting it to GETS.
- Invalid-room errors cleared on successful joining and stayed cleared after
  match completion and leaving.
- Web A-white, Mac A-black and iOS B-black synchronized legal moves.
- Qxd4 passed a pawn to iOS; P@e6 consumed it and appeared on every client.
- Narrow desktop move panels stacked the two boards and kept SAN on one line.
- Partner quick chat displayed the requesting player's name and message.
- Mac resignation produced matching 1-0, web/iOS Victory and Mac Defeat.
- Clipboard BPGN included all players, captures, drops and resignation.
- Rematch waited for 1/3, then 2/3 votes. The third vote restarted all clients
  with swapped colors; a new Mac e4 synchronized.
- All three Leave actions returned to clean Online Home.
- No browser runtime errors; existing Intl.v8BreakIterator deprecation only.

Native keyboard automation initially truncated NVCK to NVK; corrected input
joined successfully. This was not an application defect.

## Evidence and limits

The `web-*`, `ios-*` and `macos-*` PNGs are full desktop screenshots for Home,
Lobby, Game and Results. `recording.mp4` records this three-platform pass.
It is not a four-platform test or a pixel comparison. Android is absent.

The earlier pass also covered dark/light screens, 320px layouts, reduced-motion
web rendering and the fixed phone Home header. The shell regression suite
covers the full width/theme matrix and preservation of an error across
unrelated updates in the same lobby. Reconnection is covered by server tests;
full browser reload seat restoration remains unimplemented.
