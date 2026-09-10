# Voxelhearth pixel GUI — live Web + iOS manual test

Completed the manual procedure on a5c4cbd with functional and visual failures; this is not an all-pass result.

## Environment and method

- Branch: `devin/1788988153-voxelhearth`; repo `/Users/devin/repos/experiments`.
- Rebuilt release Web and iOS Simulator clients with `VH_SERVER=ws://localhost:8787/ws`.
- Normal, non-test Dart server on 8787: seed 1234, save directory `/tmp/vh-saves-manual`.
- Python static server on 8790; plain Chrome URL `http://localhost:8790`.
- iPhone 17 Simulator `113E2F1A-A37A-4546-A7AE-8A9CA23C7F89`, bundle `com.voxelhearth.voxelhearth`.
- Real UI only, side-by-side Chrome and landscape Simulator. No director channel or synthetic multiplayer API actions. No source changes.
- Room `8HCJ8`, Survival/Open, creatures enabled. Entered requested names through UI; visible display names were lowercase `web` and `ios`. Exact capitalization was not established.

## Per-check results

| Check | Result | Observation |
|---|---|---|
| Home name entry and Web Create World | PASS with visual defects | Web became host; room code and seed displayed. Exact name capitalization remains unconfirmed. |
| iOS Join, two rosters, Ready, Web Start | PASS | Both showed exactly two players and 2/2 ready, then entered the shared world. |
| Web click capture, no-drag look, Esc release | PASS | View rotated while captured; Esc opened pause; UI clicks worked after release. |
| Web movement | PASS, limited coverage | Movement exercised while finding shared landmarks; full independent W/A/S/D matrix not established. |
| Web left-hold break and right-click place | PASS | Grass removed/Dirt obtained; Torch 8→7; same hole and torch observed on iOS. No Chrome context menu. |
| Web wheel hotbar | PASS | Selected slot changed with wheel. |
| Web digit shortcuts | UNTESTED | Main-row digit attempt did not establish reliable event delivery through the computer harness; not classified as a product failure. |
| iOS joystick and look-drag | PASS | Moved around the tree and rotated to shared edits. |
| iOS hotbar tap and Place | PASS | Torch selected and placed on chopped stump, count 8→7; visible from Web. |
| iOS stationary hold-to-break | FAIL | Stationary hold did not break the targeted log. Tiny movement while continuing to hold caused the break. |
| iOS Jump | UNTESTED / inconclusive | Attempted button hold; viewpoint changed, but jump motion was not isolated from concurrent look/movement. |
| Shared edits in both directions | PASS with workaround | Each client placed one and broke one; matching world geometry observed. iOS break required the tiny-movement workaround. |
| In-game chat both directions | PASS | Both feeds showed `web pixel hello` and `ios pixel hello`. |
| Web E and iOS inventory button | PASS | Pixel recipe/crafting/inventory panels opened and closed, legible at tested sizes. |
| Inventory tap-move and persistence | PASS | Web Dirt moved from hotbar to inventory top-left and persisted; iOS log/planks tap-move worked. Drag-and-drop was not separately tested. |
| Craft planks | PASS on iOS | One log consumed, four planks produced. Web had no log; Web craft action not tested. |
| Pause, Options, slider, toggle, Back | PASS with visual concern | Sensitivity changed while held: iOS 100→186%, Web 100→179%; Sound OFF persisted when reopened on both. Sound restored ON; sensitivity moved back near original. Audibility and other controls not exhaustively tested. |
| Web Tab roster | PASS with visual defect | Exactly two players; uncaptured capture hint overlaps roster footer. |
| Full Web reload/session token | PASS | Automatically returned to same room/name/location, score 2, Torch ×7, Apple ×3 and moved Dirt, with exactly two roster entries and host controls. No Home/rejoin form. |
| End Match / results | PASS | Host pause/end action reached results on both. Both tables: ios placed 1, broken 1, crafted 1, kills 0, score 5; web placed 1, broken 1, crafted 0, kills 0, score 2. World/chat fingerprints identical. Death messages appeared near match end; paused multiplayer simulation continued. |
| Back to Lobby | PASS | Both returned to `8HCJ8`, same two players. |
| Pixel GUI visual completeness | FAIL | Issues below. Inventory/results fit and HUD stayed outside the island in tested landscape orientation. Exact pixel dimensions and all integer scale factors were not exhaustively measured. |

## Issues and reproductions

1. **iOS stationary hold does not start breaking.** Aim at a reachable Oakheart Log; press and hold without moving. No break occurs. Move approximately one screen pixel while still held: the log breaks. Raw recording around 230–265 seconds contains failure and workaround. Screenshot `08-ios-log-broken.png` shows the workaround outcome, not proof of the stationary failure by itself.
2. **iOS title footer overlaps buttons and itself.** Open Home in iPhone 17 landscape: version/Connected/legal text crosses Options and How to Play. Evidence: `01-ios-home.png`.
3. **Web title footer collision at the side-by-side window width.** Connected and legal text overlap. Evidence: `01-web-home.png`. Not tested at every width.
4. **iOS keyboard causes layout overflow.** Home → Player Name → focus Name with software keyboard visible. Yellow/black `BOTTOM OVERFLOWED BY 90 PIXELS` strip crosses the form; Server Address is obscured and buttons shift over the input. Evidence: `03-ios-name-keyboard-overflow.png`.
5. **Web roster/capture hint overlap.** With pointer released, press Tab (also reproduced after reload). `Click to look around · Esc to pause` crosses the roster footer. Evidence: `22-web-roster-hint-overlap.png`.
6. **Options background readability concern on both clients.** Pause → Options leaves the underlying pause-menu labels visible through the overlay, visually competing with current options. Controls remained usable. Evidence: `18-web-options-drag.png` (Web) and `17-ios-options-slider-drag.png` (iOS). Treat as polish concern, not a functional blocker.

## Key visual evidence

| Shared edits — Web | Shared edits — iOS |
|---|---|
| ![Web sees iOS stump and torch](https://app.devin.ai/attachments/3ea3e626-0c64-4005-8926-af61a1db5720/10-web-ios-edits-synced.png) | ![iOS shared stump and torch](https://app.devin.ai/attachments/b02f0a0b-e36f-428d-87a9-a74553fb8ea9/10-ios-ios-edits-synced.png) |

| Both chat messages | iOS crafted four planks |
|---|---|
| ![Both chat messages](https://app.devin.ai/attachments/16ca482f-e277-46fd-8f02-a47cda8fdf03/12-web-chat-both-messages.png) | ![iOS crafted planks](https://app.devin.ai/attachments/a03a0af6-5877-426e-9b88-01372214c025/15-ios-inventory-crafted.png) |

| Results — Web | Results — iOS |
|---|---|
| ![Web results](https://app.devin.ai/attachments/1a857d9e-5076-4f6c-bce9-6da787d918e9/24-web-results.png) | ![iOS results](https://app.devin.ai/attachments/6aad049b-f2d6-4128-9186-279f856a2e35/24-ios-results.png) |

| iOS title/footer defect | iOS keyboard overflow defect |
|---|---|
| ![iOS footer overlap](https://app.devin.ai/attachments/ab999528-7560-46e3-beea-f2d8ab1bb1e7/01-ios-home.png) | ![iOS keyboard overflow](https://app.devin.ai/attachments/6dde50ad-b5bb-40ec-a6d7-088a307f1cb7/03-ios-name-keyboard-overflow.png) |

| Web title/footer defect | Web roster/hint defect |
|---|---|
| ![Web footer collision](https://app.devin.ai/attachments/7e55a14e-f49b-4ba1-a076-99fdade801e5/01-web-home.png) | ![Roster hint overlap](https://app.devin.ai/attachments/936a277c-d76a-4341-a9c0-1963a98042ab/22-web-roster-hint-overlap.png) |

| Options underlying-menu concern | iOS break workaround outcome |
|---|---|
| ![Options background labels](https://app.devin.ai/attachments/2b74c3c7-184d-4ee9-b1b7-ac844bdd6b98/18-web-options-drag.png) | ![Log broken after tiny movement](https://app.devin.ai/attachments/abe98c64-ed78-4c68-9c5a-88aeb211cb6f/08-ios-log-broken.png) |

## Artifacts and limits

- Full raw footage for cutting: `/Users/devin/screencasts/vh-pixel-web-ios-manual/vh-pixel-web-ios-manual-raw.mp4`.
- Condensed annotated playback: `/Users/devin/screencasts/vh-pixel-web-ios-manual/vh-pixel-web-ios-manual-edited.mp4`.
- Structured recording annotations: `/Users/devin/screencasts/vh-pixel-web-ios-manual/vh-pixel-web-ios-manual-annotations.json`.
- Evidence folder: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/manual-20260910/`.
- `markers.json`: 25 step/check markers. Times are approximate raw-footage seconds, aligned to the first raw segment file creation (about ±1 second); do not use them against condensed playback. Screenshots captured at each marker; some markers describe a check outcome rather than the action start.
- 41 numbered screenshots; Web screenshots include the whole desktop pair. iOS simctl screenshots were rotated 90° for landscape readability; no content was altered.
- Setup/builds preceded recording; the full live UI test was recorded. Simulator software-keyboard overflow required working around the layout to finish name entry.
- No Android or native macOS testing in this pass. No kiln/chest interaction, exhaustive scale sweep, all-options coverage, physical-device touch or audio validation.
- Exact capitalized names, digit shortcuts, isolated Jump, and a complete directional-key matrix remain unconfirmed.
- Blueprint currently documents only pixel-painter. Suggested additions: the Voxelhearth server/build/static-server/simulator commands above; macOS side-by-side window setup and keyboard/rotation notes. No dependency installation was needed. Pillow was unavailable during screenshot postprocessing; built-in `sips` handled rotation instead.
- Services remain running on 8787 and 8790, clients in the lobby. No user credentials or other user action needed. Lead should fix listed defects and request a focused retest.
