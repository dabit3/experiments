# Focused pixel GUI fixes — Web + iOS

Completed the focused real-UI procedure against the supplied rebuilt Web and installed iOS clients. Not all fixes passed.

## Setup

Kept the existing normal server on 8787 and Python static server on 8790 unchanged. Hard-reloaded Chrome and relaunched `com.voxelhearth.voxelhearth` on iPhone 17 Simulator `113E2F1A-A37A-4546-A7AE-8A9CA23C7F89`. Terminate initially reported nothing to terminate; launch succeeded. Same side-by-side window dimensions and landscape phone orientation as the previous pass. No credentials, installs, or source edits.

## Results per requested item

| Item | Result | Visible evidence |
|---|---|---|
| 1. iOS stationary hold breaks | **PASS** | Aimed at Oakheart Log, moved cursor into the world, pressed down, and made no mouse movements until release. Crack/progress marks appeared; log disappeared and entered hotbar. Continued hold also broke dirt behind it. No tiny-movement workaround required. |
| 2a. iOS Home overlap | **FAIL — improved, not eliminated** | Smaller/higher wordmark and stacked footer are present. Legal text still intersects lower bevel/border of Options and How to Play. Button labels are now readable, but the requested no-overlap criterion is not met. |
| 2b. Web Home at side-by-side width | **PASS** | Legal line sits above status/version line; no collision. Menus and footer separate. |
| 3. iOS keyboard form scroll | **PASS** | Enabled software keyboard, focused Name, swiped upward: Server Address and Done/Cancel became visible above keyboard without overflow stripe. Tapped Server Address, then Done; returned Home. |
| 4. Web hint vs Tab roster | **PASS** | With pointer released, two-player Tab roster remained at top while capture hint appeared above hotbar, with no overlap. |
| 5. Pause hidden behind Options, both clients | **PASS for requested behavior** | Game Menu title and pause buttons disappeared while Options was open. Done restored Game Menu and controls on both. Separate iOS Options clipping remains below. |

## Other issues observed

- **iOS host lobby overflow (incidental, not established as newly introduced):** Leaving the previous room from Web promoted iOS to host. Chat input/Send row showed **BOTTOM OVERFLOWED BY 10.0 PIXELS**. Repro: two clients in lobby → Web host Leave → inspect newly hosting iOS. `50-ios-host-lobby-overflow.png`.
- **iOS Options helper text clipped (incidental):** “Auto graphics lowers render resolution…” is almost completely clipped immediately above Done in landscape. The underlying pause labels are correctly gone; this is a separate layout problem. `56-ios-options-fixed.png`.
- **iOS Home remaining collision:** Open Home in this landscape size; inspect legal line against Options/How to Play lower button edges. `51-ios-home-fixed.png`.

## Procedure caveats

- Entering the join code through the simulator did not successfully join; UI showed “Enter a 5-letter code.” Used Refresh and the displayed room row to join instead. This was setup for the fix checks, not a verified regression in joining.
- An initial attempt to disable creatures did not change the resulting room setting; the match retained Creatures ON. It did not block these checks.
- Initially the players spawned co-located, obscuring the iOS view; moving Web away resolved aiming. Both clients participated in the same normal-server room.
- Focus changes sometimes required an additional click. No synthetic input API/director actions or source changes were used.
- Exact 220 ms timing was not instrumented; the verified condition is progress and removal with a completely still held finger.
- No full multiplayer regression, physical-device run, or exhaustive viewport sweep in this short pass.

## Screenshots

| Web Home — PASS | iOS Home — remaining overlap |
|---|---|
| ![Web Home fixed](https://app.devin.ai/attachments/bd42e41b-f666-4363-a5a2-a9d0d17c73d7/51-web-home-fixed.png) | ![iOS Home collision remains](https://app.devin.ai/attachments/db2591b1-c2f5-40cb-8261-cb8c407b8af7/51-ios-home-fixed.png) |

| iOS keyboard scroll — PASS | iOS host lobby — overflow |
|---|---|
| ![Keyboard form scroll](https://app.devin.ai/attachments/90f964e3-f970-4cb5-a7cd-b22d8b33e175/52-ios-keyboard-scroll.png) | ![Host lobby overflow](https://app.devin.ai/attachments/56f302de-6ec3-41fe-aceb-cda222d35c0f/50-ios-host-lobby-overflow.png) |

| 🔴 Before removal — stationary-hold progress | 🟢 After removal — still no pointer movement |
|---|---|
| ![Cracks during still hold](https://app.devin.ai/attachments/bf263a7a-99b9-44db-ace5-5a4a440aa95a/53-ios-still-hold-progress.png) | ![Block removed during still hold](https://app.devin.ai/attachments/63440934-2a0c-49f7-a4ee-299719b9156b/54-ios-still-hold-broken.png) |

| Web Options — no pause labels | iOS Options — no pause labels, helper clipped |
|---|---|
| ![Web Options fixed](https://app.devin.ai/attachments/8c385975-6ce7-42a5-b09f-ec2f62a740d1/56-web-options-fixed.png) | ![iOS Options](https://app.devin.ai/attachments/bc7d5739-52db-4ce4-b0ec-1217ea26cf45/56-ios-options-fixed.png) |

| Web roster/hint separated | Done restores both pause menus |
|---|---|
| ![Roster and capture hint](https://app.devin.ai/attachments/9fc26864-068b-4a64-9817-da876b71db79/55-web-roster-hint-fixed.png) | ![Both pause menus restored](https://app.devin.ai/attachments/349c147b-704f-440c-a261-81a2a21b7616/57-both-options-done-pause.png) |

## Artifacts and follow-up

- Recording: `/Users/devin/screencasts/vh-pixel-fixes/vh-pixel-fixes-edited.mp4`
- Screenshots (10 files, numbered 50–57): `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/manual-20260910/`
- This report: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/manual-20260910/REPORT-fixes.md`
- Existing baseline report and markers were not overwritten. No new markers file requested for this focused run; recording contains structured annotations.
- Suggested PR comment: none, per prior instruction that lead handles the PR.
- New SKILL suggestions: none; previous cross-client skill remains applicable.
- Blueprint gap confirmed: only pixel-painter is documented. Add local Voxelhearth server/static-server commands and iOS simctl relaunch, software keyboard toggle (Simulator Cmd+K), landscape arrangement, and simctl screenshot rotation via `sips`. No installs or server changes this run.
- Still needed from user: none. Lead should address remaining iOS layout issues. Both clients remain in the match's pause menus, servers unchanged.
