# Manual (human-style) UI testing — web + native macOS

Performed by an independent testing agent driving the real UI with mouse and
keyboard (Chrome on this Mac + the native `Voxelhearth.app`), against a normal
(non test-mode) server on :8787. Recordings and screenshots are kept out of git
and attached to the PR / final report instead.

## Run 1 — pre-fix (commit 56c639b)

Passed: create Survival room, host/code/rules/chat/add-bot UI, 3-player roster,
native ready toggle, lobby chat sync, shared gameplay + HUD, drag-to-look,
shared block placement/breaking across clients, crafting log -> 4 planks,
cross-client chat, settings persistence, identical results/scores/fingerprints,
back to lobby.

Findings (all addressed in commits 0e8a140 and b3b09b7):

| # | Finding | Fix |
| --- | --- | --- |
| 1 | Native edited name briefly joined under the previous name | Home create/join await the new `hello`; `Room.join` renames an existing player on rejoin |
| 2 | Full web reload mid-match returned Home | Per-server session token persisted in settings and restored on launch |
| 3 | Right-click placed a block but also opened Chrome's context menu | `BrowserContextMenu.disableContextMenu()` on web |
| 4 | Click + move did not look around (only drag did) | Browser Pointer Lock / native macOS cursor capture on first click |
| 5 | Torch rendered with a black rectangular backing | Shader samples only the painted stick strip of the torch tile |
| 6 | Light-theme non-host rules were faint (disabled controls) | Non-host sees readable summary rows |
| 7 | Chat overlay could open scrolled to old messages | Panel opens at the newest message |
| 8 | Digit hotbar keys "did not respond" | Not a product defect: verified working via Playwright keyboard (`press 3 -> selected 2`); the GUI harness could not deliver main-row digits |

## Run 2 — post-fix (commit 0e8a140)

Passed: web click-to-capture + plain-move look + Esc release; macOS capture,
Esc and window-blur release; reload recovery to the same room/player with the
same inventory and host controls; native edited identity on immediate Join and
Create; torch rendering on both clients; readable non-host rules; chat opens at
newest message; end match -> lobby regression.

Failed: while pointer-locked on web, right-click / left-hold / wheel did not
reach the game (browser targets all mouse events at the locked element, which
was `documentElement`). Fixed in b3b09b7 by locking the `flutter-view` element.

## Run 3 — locked-input recheck (commit b3b09b7)

Passed on web while pointer-locked: right-click places (torch 8 -> 7, +1 pt),
left-hold breaks (sand removed, +2 pts, drop collected), wheel changes the
hotbar slot both directions, Esc releases and the pause panel is usable.

## Not covered manually

iOS (covered by the automated E2E only), Android (emulator cannot boot on this
host), audible sound, a natural day/night transition, digit keys via a real
keyboard (verified via Playwright only).
