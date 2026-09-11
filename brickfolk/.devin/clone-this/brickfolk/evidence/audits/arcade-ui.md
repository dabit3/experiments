# Arcade design convergence and UI verification

## Scope

Original Brickfolk art direction: navy shell, electric blue navigation, tactile
marigold actions, illustrated world cards, dimensional avatars, experience lobby
art, brighter game environments, trophy results and deterministic confetti.
This is an original redesign requested by the user; the commercial reference was
not run or purchased. Cross-client visual comparison uses Brickfolk web as the
baseline. It does not establish pixel parity with the commercial reference.

## Manual UI passes

The persistent UI testing agent rebuilt and drove web and native macOS clients.
The initial arcade pass covered hub navigation, search match/empty/clear, Details,
themes, avatar/profile, daily reward, filtered chat, cross-platform Obby,
Tycoon building and Tag. It found two phone issues: search was unavailable at
320px and Tag's arena shrank the player/labels too far. A subsequent pass verified
the added phone search row and readable tracking camera/minimap, including
1.5x text, direct hero launch, Continue-card keyboard activation and Tag results.

The follow-up deliberately moved beyond spawn points to the actual arena top
wall and found the local avatar/name clipped by the playfield. Camera clamps now
reserve 48 logical pixels around the arena (bounded for small viewports).
Automated regression tests cover avatar/name clearance at all actual arena
corners at 320px and 390px, in addition to spawn, desktop and enlarged-text hub
tests.

## Final focused retest, after the camera fix

Rebuilt web and native macOS Release:

- Manual joystick input reached actual top, left and bottom-right arena walls.
  The avatar and name remained visible; the IT badge was visible at bottom-right.
- Native Release arrow keys moved the player upward, then right.
- Tab focused the recommended Skyline world card; Enter opened its Details.
- Frozen intervals were excluded from movement assertions.
- The tester stopped its clients/services before the multiplayer harness.

Evidence: `evidence/clone/arcade-ui/boundary-final-edited.mp4`,
`tag-top-wall-final.png`, `tag-left-wall-final.png`,
`tag-bottom-right-wall-final.png`, `native-keyboard-after.png` and
`recommended-card-details.png` in the same directory. The recording is a
61-second annotated edit. The full multiplayer harness and visual comparison
run independently; see the final manifest's `evidence_runs`.

## Host limitation

A native macOS Debug Tag pass hit an AppleParavirtCommandBuffer assertion in
the virtual graphics stack. Native Release completed the same game and passed
the final keyboard check. This is consistent with a Debug virtual-Metal host
issue, but no claim is made that Debug passed that manual run.
Diagnostic: `evidence/clone/arcade-ui/native-debug-crash.txt`.
