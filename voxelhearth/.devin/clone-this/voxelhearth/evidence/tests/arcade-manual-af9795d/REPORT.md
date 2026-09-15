# Voxelhearth af9795d — fresh real-UI Web + iOS verification

Rebuilt and relaunched normal Chrome Web and iPhone 17 Simulator clients from the main checkout, then executed the requested shared-room lifecycle using real menus, mouse, keyboard and touch gestures.

- Revision: `af9795d`
- Frozen source fingerprint supplied for this run: `sha256:3b6df07fc2b5f62efab566427037ee8c37e88f116eb167e2e9710e86e1bfdc6d`
- PR: https://github.com/dabit3/experiments/pull/42
- Session: https://app.devin.ai/sessions/c461fcfd36ac4a6bb64ade73b52c5520
- Environment: normal localhost Web `8790`, Dart multiplayer `8787`, `testMode:false`; iPhone 17 Simulator in landscape, approximately 874×402 logical pixels. Chrome and upright phone visible together.
- No application source edits, director input, isolated-checkout access or automated e2e during this manual run.

## Escalations and limitations

No new product defect observed within the exercised flow. This is not proof that all code/platforms are correct.

- **Untested:** Android (known host virtualization limitation), native macOS client, physical devices, universal FPS, authoritative server end-of-match parity, exhaustive keyboard directions/digit shortcuts, isolated Jump, audible sound, and persistence across a server restart.
- **Not freshly repeated:** Help, bot add/remove, iOS-host lobby, hover/focus matrices and additional viewport sizes. Earlier observations are not relabeled as af9795d evidence. Current run briefly exercised Home/name and phone keyboard regressions, then the requested gameplay lifecycle.
- Matching world/chat hashes below are **client UI agreement only**, not independently checked against the authoritative server snapshot.
- Web build emitted an expected-font-family warning mentioning CupertinoIcons. Build completed; no missing glyph/asset was visually observed on the screens exercised. Warning retained in `build-web.log`.
- Setup/evidence deviations: initial relative log redirection failed before a build started; rerun with absolute paths completed. A Pillow-based contact-sheet helper failed, then was replaced with FFmpeg without installing Pillow. Some window-focus/timing clicks needed repetition; one accidental Chrome maximization was restored. These are not treated as product failures.
- Video validation was **sampled**, not watched end-to-end: title, each chapter/card/midpoint and summary were inspected; the entire file decoded without errors. Two initial chapter cuts were tightened before the final render so name/chat captions align with visible evidence.

## Runtime assertions

- **PASS — Corrected iOS movement:** Up approached the facing oak/Web avatar; down receded; right moved the landmark left and left moved it right. Released joystick returned to center and viewpoint stopped drifting. This specifically distinguishes the corrected forward sign from the prior inverted behavior. See screenshots 01–03 and raw movement sequence.
- **PASS — Regression, phone name:** Name draft survived keyboard hide/show; touch scrolling exposed Server Address and Done above the keyboard, without an overflow stripe.
- **PASS — Regression, lobby focus:** Fresh room `BRU2K` showed exactly Web host and iOS, Survival/Open with creatures OFF. Phone draft survived keyboard resizing, sent to both histories, and accepted a new draft without refocusing. Ready/start entered the shared match.
- **PASS — Stationary touch break:** A completely still phone hold showed break progress and removed the oak log. Both cameras showed the same gap and phone inventory received a log. No drag workaround.
- **PASS — Shared phone placement:** iOS Place reduced torches **8 → 7**; both cameras visibly showed the same torch in front of the stump.
- **PASS — Shared Web edits:** Pointer-locked left hold removed that torch on both cameras (**Web 8 → 9**). Locked right-click replaced it on both (**9 → 8**), without a browser context menu.
- **PASS — Gameplay controls:** Real look/movement, Web capture/wheel selection/Esc and phone action/hotbar controls were usable during the shared-edit sequence. This is not an exhaustive movement-key matrix.
- **PASS — Two-way gameplay chat:** `web game hello` and `iOS game hello` appeared in both game histories.
- **PASS — Inventory/crafting:** Web's eight torches moved into a nondefault upper-right inventory slot. Phone consumed **one log → four planks**, moved its seven torches, and retained state after reopening.
- **PASS — Pause/Options:** Held sliders changed sensitivity; reopened values were **Web 121% / iOS 151%**, with Sound OFF retained. No pause-label bleed, clipped phone helper or overflow observed. Sound ON was restored afterward, with final cleanup outside the recording.
- **PASS — Plain Web reload:** Nondefault stump viewpoint, room `BRU2K`, identity `web`, score **2**, exactly two players and eight moved torches survived reload/reconnect. Esc/Tab remained usable.
- **PASS — Results/final chat:** Both results showed **iOS 5 / Web 2**, matching visible world and chat fingerprints; world fingerprint was `629922f4`. Phone scrolling exposed its hash fields. Final `Match over. iOS takes the crown!` remained readable.
- **PASS — Return to lobby:** Host return moved both clients to `BRU2K`, retaining the two-player roster and final chat without visible overflow.
- **PASS — Review artifact:** Final programmatic video is **123.83 seconds**, with title, 11 chapter cards, captions, Web/iOS labels, timeline and an explicitly scoped eight-check summary.

## Key visual evidence

| 🔴 Before upward joystick drag | 🟢 After upward drag and release |
|---|---|
| ![Facing oak before movement](https://app.devin.ai/attachments/36265f2d-f8b5-4c19-8222-c445193cfcc3/01-movement-baseline-ios.png) | ![Oak approached after upward gesture](https://app.devin.ai/attachments/a63f54d6-b8ec-4107-943a-40296838af7f/02-up-release-ios.png) |

| Shared placement — both cameras | Results fingerprints — both clients |
|---|---|
| ![Phone torch visibly shared](https://app.devin.ai/attachments/b900a8b0-6791-4d05-8793-35ef63690f94/08-shared-phone-torch-both.png) | ![Client result fingerprints](https://app.devin.ai/attachments/b1a579b3-7b9e-4386-9494-8c92a9e808ed/19-result-hashes-both.png) |

| Phone lobby focus | Phone Options layout |
|---|---|
| ![Sent message and new focused draft](https://app.devin.ai/attachments/9a891535-3899-4f7b-85c3-7bbbdd455d65/05-lobby-focus-ios.png) | ![Settings retained and helper visible](https://app.devin.ai/attachments/610bd624-8b53-4e21-ad5a-dfc9ac9838ee/14-options-persist-ios.png) |

## Artifacts

[Watch the final 2:04 review](https://app.devin.ai/attachments/e31489b5-9ccd-4e63-94f9-3645077f5e53/review-video.mp4)

All relative paths below are under:

`/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/arcade-manual-af9795d/`

- `REPORT.md` — this report.
- `review-video.mp4` — final programmatic review, 123.83 seconds.
- `review-script.json`, `review-video.edl.json`, `review-render.log` — reproducible editor input/output metadata.
- `raw-footage.mkv` — concatenated raw footage, **1008.466 seconds**.
- `markers.json` — 20 screenshot milestones on approximate raw timeline.
- `markers-capture-clock.json`, `timeline-notes.json` — original capture clock and normalization details. Raw marker time is approximate; editor cuts use the idle-shortened clean-video clock, not raw seconds.
- `recording-annotations.json` — structured runtime assertions.
- **60 numbered screenshots**, `01-movement-baseline-{both,ios,web}.png` through `20-return-lobby-{both,ios,web}.png`.
- `review-validation-contact-sheet.png`, `review-validation-00.png` through `review-validation-23.png`, `review-validation.json` — final review samples and full-decode outcome.
- `build-web.log`, `build-ios.log`, `server.log`, `web-server.log`.
- `plan.md`, `capture.py`, `prepare-review.py`, `validate-review.py`, `finalize-evidence.py` — persistent plan/evidence helpers.

Additional recorder files:

- `/Users/devin/screencasts/vh-arcade-af9795d/vh-arcade-af9795d-edited.mp4`
- `/Users/devin/screencasts/vh-arcade-af9795d/vh-arcade-af9795d-clean.mp4`
- `/Users/devin/screencasts/vh-arcade-af9795d/vh-arcade-af9795d-annotations.json`
- Raw segments: `/Users/devin/screencasts/vh-arcade-af9795d/vh-arcade-af9795d-raw-000.mkv` through `-raw-008.mkv`.

## Suggested setup documentation

- SKILL suggestion: `/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/arcade-manual-af9795d/SKILL.md`.
- Exec directory: `/Users/devin/repos/experiments`.
- Rationale: preserve normal Web/iOS setup, true gesture/focus testing, two-camera synchronization evidence, reload baselines and review-video validation. This is an updated persistent suggestion replacing the earlier temporary skill draft, not an application source edit.
- Blueprint was rechecked: only pixel-painter is documented. Add Voxelhearth normal Dart server, Flutter Web/iOS builds/dependency resolution, static server, simctl install/relaunch, macOS landscape arrangement/upright capture and FFmpeg/editor workflow. Existing tooling was reused; no new manual dependency installation.
- Still needed from user: **none**.

## Handoff state

Both clients were returned to the BRU2K lobby, Sound ON, and Simulator left booted. At the lead's explicit request after testing, owned normal server processes on **8787/8790 were stopped and GUI/port ownership released** for independent automated pair/trio runs. No later GUI actions were performed by this tester. Those automated results are outside this report.
