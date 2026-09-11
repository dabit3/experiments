# Round 3 focused UI retest — 2026-09-10

Executed through Chrome and the iPhone 17 Simulator UI, using the supplied rebuilt Web and installed iOS clients. Existing normal server on 8787 and Python static server on 8790 were retained unchanged. Web was hard-reloaded and iOS relaunched. No application source changes or synthetic multiplayer/director API calls.

## Results

| Requested check | Result | Observation |
|---|---|---|
| iOS Home SafeArea footer | PASS | Legal text is fully below Options/How to Play with visible separation; version/status uses a separate lower line. |
| iOS host lobby compact footer/chat | PASS | iOS created room Y9XE7. Start Match, Add Bot, Remove Bot, Options, Leave fit in one row. Chat input and Send are fully visible; no BOTTOM OVERFLOWED stripe. Remove Bot correctly appears disabled with zero bots. |
| iOS Options helper | PASS | Entire “Auto graphics lowers render resolution when the frame rate drops.” is visible above Done without scrolling. Done returns to the host lobby. |
| Regression: Web+iOS join | PASS | Web Play Online → Refresh → selected ios’s world → Join World. Both clients show Y9XE7 with exactly ios (host) and web; iOS host chat/footer remain overflow-free. |

No new defects or blocked requested checks. Foregrounded clients before interaction; the first Refresh click brought Chrome into focus, then the next refreshed the list normally. No gameplay, bot operations, chat sending, keyboard-open layout, physical-device coverage, or exhaustive viewport-size regression was requested or performed in this short pass.

## Visual evidence

| iOS Home — separated footer | iOS host lobby — one-row controls |
|---|---|
| ![iOS Home](https://app.devin.ai/attachments/704e8ed3-1d73-4724-a85d-04752063d81a/60-ios-home-safearea.png) | ![iOS host lobby](https://app.devin.ai/attachments/0bbec2f5-275f-440f-92bb-2654c8202e16/61-ios-host-lobby-fixed.png) |

| iOS Options — complete helper | Web+iOS — matching room and players |
|---|---|
| ![iOS Options](https://app.devin.ai/attachments/28505eb5-24b4-4804-96ce-e609b06c2fc1/62-ios-options-helper-fixed.png) | ![Shared lobby](https://app.devin.ai/attachments/710aa003-8588-424c-ab9b-3a176ab181eb/63-both-shared-lobby.png) |

[Full-resolution iOS shared lobby](https://app.devin.ai/attachments/3527bacf-c3d7-4d79-8168-cab0ffab599c/63-ios-shared-lobby.png)

## Local artifacts

- Recording: `/Users/devin/screencasts/vh-pixel-fixes-round3/vh-pixel-fixes-round3-edited.mp4`
- Screenshots: `60-ios-home-safearea.png`, `61-ios-host-lobby-fixed.png`, `62-ios-options-helper-fixed.png`, `63-both-shared-lobby.png`, `63-ios-shared-lobby.png` in this report’s directory.
- Simulator screenshots rotated to landscape with built-in `sips`.
- Clients remain together in the lobby; servers untouched.

## Setup and follow-up

- No dependency installs or service restarts.
- Existing environment blueprint was checked: it only documents pixel-painter. Suggested addition: Voxelhearth client hard-reload/simctl relaunch, landscape side-by-side arrangement, and simctl screenshot rotation.
- New SKILL.md suggestions: none.
- Suggested PR comment: none, per lead instruction.
- Still needed from user: none.
