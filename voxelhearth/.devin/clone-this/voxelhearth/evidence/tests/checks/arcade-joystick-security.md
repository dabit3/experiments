# Final arcade source and dependency review

Source: `af9795d`
Revision: `sha256:3b6df07fc2b5f62efab566427037ee8c37e88f116eb167e2e9710e86e1bfdc6d`

Re-inspected the current server/simulation authorization, dependency declarations,
local assets, native launch paths and source diff after freezing this revision.

- Normal tokens use `Random.secure()`; predictable test tokens and director
  commands require test mode. Director commands also require the director key.
- Match and rule controls check the room host. Display names and chat have
  length bounds; the chat history is bounded.
- No external account collection, integrations or dependencies were added by
  the arcade redesign or touch-axis correction. Fonts retain their OFL files.
- The input correction only aligns the virtual joystick's positive forward
  value with keyboard input. The regression test drives real gestures through
  movement physics at two camera headings, including release reset.
- Result messages include the final system chat in the authoritative hashes.
  Simulator capture normalization selects one of two fixed rotation filters.
- Current `npm audit --json` reports zero vulnerabilities in the test-tool
  dependency tree (`arcade-joystick-npm-audit.json`). This is not a Dart/native
  dependency audit or a penetration test.
- Clean builds and checks use the detached `af9795d` checkout; production
  source, tests, fixtures and lockfiles remain in the fingerprint's file list.

The in-process acceptance probe now follows the server's actual save/rejoin
contract: compare persisted chat before the new join message, then pass
`savedPlayers.remove(id)` to `Room.join`. Its two initial failures were probe
setup mistakes; no persistence implementation was changed. The final run checks
JSON persistence, chests, kiln state, inventory, sleep/daylight, starvation,
submersion, creative immunity and stable results.

The supported deployment remains a trusted LAN/local test environment.
Android live participation and universal 60 FPS remain blocked by the host.
