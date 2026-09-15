# PR 229 — fresh native tablet and three-device UI verification

Completed the real-UI procedure on **8400c43627b0737b55ba09a45837154b3f8c0337**, with Chrome Web, native iPhone and native iPad connected simultaneously to one normal authoritative room. The primary lobby keyboard fix and scoped lifecycle assertions passed. An unresolved Simulator-only keyboard-dismissal observation and coverage limits are documented below; this is not a claim that every feature or platform is defect-free.

PR: https://github.com/dabit3/experiments/pull/229
Session: https://app.devin.ai/sessions/c461fcfd36ac4a6bb64ade73b52c5520
[2:32 programmatic review](https://app.devin.ai/attachments/f75a388f-4158-4960-b25d-7ea072ce6748/review-video.mp4) · [4:14 builtin processed recording](https://app.devin.ai/attachments/29ed0a03-0343-4a70-bd3a-2dd30e976f99/vh-three-device-8400c436-edited.mp4)

## Observations and incomplete coverage

- **Simulator observation, not an established product defect:** Hiding the iPad **gameplay** keyboard with Simulator **Cmd+K** left an unused black lower strip while chat retained focus. Composer and Send remained usable. Closing chat restored the full HUD. The lead requested a comparison: using the native keyboard's normal **Hide Keyboard** button restored the full-height chat/world with no strip. No normal action was blocked and no layout remained broken after closing chat. Root cause of the Cmd+K-only behavior was not investigated; no source edits.
- **Web placement scope:** Web visibly removed the tablet's torch and placed a replacement nearby, visible on all three clients. Exact-coordinate replacement was **not established**. Native log removal and placement were visibly cross-checked across all three cameras.
- **Untested in this fresh pass:** Android, native macOS client, physical devices, universal FPS, authoritative final-server parity, server-restart persistence, inventory/crafting/reload, isolated Jump, exhaustive four-way/yaw input matrices, and Home/Results keyboard matrices. The phone/tablet movement regression here specifically covers approach/recede and release. Prior evidence is not substituted for fresh coverage.
- **Procedure deviations:** Some rapid window changes needed a separate activation click and settling delay; a Simulator window was repositioned after an accidental titlebar drag. Native wheel scrolling did not move results; actual touch swipes did. An initial keyboard-shortcut assumption was corrected using Simulator's I/O → Keyboard menu, and actual hide/show was subsequently verified with retained text. The first sample-sheet helper attempted unavailable Pillow; it was corrected to use installed FFmpeg, with no dependency installation.

| Cmd+K dismissal — unresolved Simulator observation | Normal on-screen Hide Keyboard — full view restored |
|---|---|
| ![iPad gameplay chat after Simulator keyboard toggle](https://app.devin.ai/attachments/018c73aa-e06e-43ca-b39a-846c089e356e/12-three-way-game-chat-ipad.png) | ![iPad gameplay chat after native Hide Keyboard](https://app.devin.ai/attachments/83fa7808-e311-42a2-9251-bc09deb14713/14-normal-keyboard-hide-ipad.png) |

## Environment and setup

- **Chrome Web:** 153.0.8010.37, plain http://localhost:8790.
- **Native iPhone:** iPhone 17 Simulator, iOS 26.5 (23F73), UDID `113E2F1A-A37A-4546-A7AE-8A9CA23C7F89`.
- **Native iPad:** iPad Pro 11-inch (M5) Simulator, iOS 26.5 (23F73), UDID `1EB4C963-D960-4E49-9082-E259096367FB`. Actual iPad target, not browser emulation.
- **Host:** macOS 26.5.2 (25F84).
- Installed/relaunched the supplied current native build on both preserved devices; hard-reloaded the current supplied Web build. This tester did not independently recompile those already updated artifacts in this handoff.
- Restarted normal Dart server on 8787 with seed 1234 and fresh run-local saves; setup health confirmed `testMode:false` and zero rooms. Static Web server on 8790. No director-input actions or authenticated backend shortcuts.
- Fresh room **54ZSP**, `tablet verified`, distinct identities `web`, `iPhone`, `iPad`; Survival, creatures OFF, bots 0. Apps and servers remain running in that lobby.
- Existing native devices were reused without erasing data. Earlier sequential Simulator recovery and bounded reclamation of an unused isolated build directory preceded this handoff; neither was repeated as a product change here. No isolated clean-build checkout was used.
- Disk remained above the agreed 1 GiB stop threshold: approximately 3.9 GiB before setup, 3.1 GiB before final processing, 2.9 GiB after review generation.

## Assertions

- **PASS — Shared room:** All three joined 54ZSP through real menus, with three distinct humans and matching rules.
- **PASS — Primary iPad keyboard fix:** `pad` survived actual software keyboard hide/show and appended to `pad ok`; composer, Send and footer remained reachable without the prior 23-pixel overflow.
- **PASS — iPad Send/focus/scroll:** `pad ok` appeared in all histories; another draft was typed without refocusing. Real touch scrolling reached Ready Up, Options and Leave while the keyboard was open.
- **PASS — Phone regression:** `phone ok` survived keyboard toggling, appeared in all feeds, and a new focused draft remained usable above the keyboard.
- **PASS — Ready/start:** Native players readied and Web started the shared world on all three clients.
- **PASS — Native movement:** Both native clients approached and receded relative to facing terrain/avatar under actual joystick drags; release stopped movement.
- **PASS — Native stationary edits:** Each native client held still to remove an oak log and placed a torch. The same gaps and both torches were visible on all three cameras.
- **PASS, scoped — Web edit:** Web removed the tablet torch and placed a nearby replacement visible on all three clients; exact-coordinate replacement not proven.
- **PASS — Three-way game chat:** Distinct `web game`, `phone` and `pad` messages were readable in every history.
- **PASS — Tablet menu:** Menu → Options → Done → Back to Game was accessible, with fitting controls/helper text and restored HUD. Normal on-screen keyboard dismissal also restored the full gameplay view.
- **PASS — Results:** All three scoreboards showed web/iPhone/iPad **2 points each**, each with one placed and one broken, zero crafted and zero kills. Native touch scrolling revealed matching world/chat fingerprints. This proves client agreement only.
- **PASS — Return:** Host Back to Lobby returned all three to 54ZSP with the same roster and `Match over. web takes the crown!` visible in all lobby histories.
- **PASS — Evidence processing:** Builtin processing completed. Programmatic review is **152.416667 seconds**, with title, 11 chapter cards, captions, device-position labels, timeline and scoped check summary. Title, every chapter card/segment sample and summary were inspected. Full output decoded with FFmpeg without errors. It was **not watched end-to-end**.

| iPad draft and footer above keyboard | Message sent, new draft retains focus |
|---|---|
| ![iPad pad ok draft with composer Send and footer](https://app.devin.ai/attachments/fefdfd7a-9849-49f1-87b3-59f77a3c2af7/03-ipad-draft-ipad.png) | ![iPad sent message and new focused draft](https://app.devin.ai/attachments/be1e0339-0872-41f2-80e4-8aaf663790da/04-ipad-sent-focus-ipad.png) |

| Shared native edits visible on three cameras | Matching three-client fingerprints |
|---|---|
| ![Both native edits synchronized](https://app.devin.ai/attachments/cecd5c2d-6102-48d1-b5e0-6a5e095ff598/10-both-native-edits-desktop.png) | ![Three-client results agreement](https://app.devin.ai/attachments/c755b587-66a0-4645-8402-f482752ab62f/16-three-client-fingerprints-desktop.png) |

## Preserved artifacts

Run directory:
`/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/three-device-8400c436/`

- `REPORT.md` — this report.
- `review-video.mp4` — 152.416667 seconds, 1920×1080, 24 FPS; 10,124,561 bytes.
- `review-script.json`, `review-video.edl.json` — reproducible review instructions and EDL.
- `markers.json`, `recording-start.txt`, `capture.py`, `plan.md` — capture timing and acknowledged plan.
- `01` through `17` desktop/phone/tablet screenshots — 51 numbered PNGs; native screenshots normalized upright and inspected.
- `video-samples.py`, `source-*.png`, `source-times.txt`, `review-*.png`, `review-times.txt`, `review-validation.json` — source and final review validation samples/contact sheets.
- `server.log`, `review-render.log`, `review-decode.log` — normal server and processing logs. Empty decode log corresponds to successful no-error decoding.
- `saves/` — fresh normal-server run data.

Builtin recording directory:
`/Users/devin/screencasts/vh-three-device-8400c436/`

- `vh-three-device-8400c436-edited.mp4` — 253.541667 seconds, processed builtin recording.
- `vh-three-device-8400c436-annotations.json` — structured setup/test/assertion events and source/edited times.
- Ten `vh-three-device-8400c436-raw-000.mkv` through `...-raw-009.mkv` files, total probed duration **1173.534 seconds**, plus clean video/processed segments/FFmpeg log.
- Review cuts intentionally use builtin **edited_time_s**, not wall-clock marker times; idle compression makes these different timelines.

Earlier failure evidence remains preserved and is diagnostic only:
`/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/three-device-414c03f-20260915/`.

## Reusable setup guidance

Updated existing skill draft, not product code:
`/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/arcade-manual-af9795d/SKILL.md`
Exec directory: `/Users/devin/repos/experiments`. Adds native iPad setup, bounded Simulator/disk recovery, true touch scrolling, normal keyboard dismissal comparison and edited-time sampling.

Blueprint rechecked: current repository blueprint documents only pixel-painter; it does not cover this setup. Suggested additions: Voxelhearth normal Dart/static Web servers with isolated save data, supplied-artifact install/relaunch or Flutter build commands as applicable, sequential native device startup, landscape/upright capture and disk gates, plus existing FFmpeg/Playwright review workflow. No dependencies were installed during this handoff.

Still needed from user: **none**. Cmd+K-only Simulator behavior remains documented for optional investigation; no normal-UI blocking defect was established.
