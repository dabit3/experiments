# Gambit Court — current pass4 runtime report

Source: `703c987a67be76cd88e14fafddd00318fddb096d`.
Supplied fingerprint: `sha256:c4ab07ded4212875064fd8201f8a3fbd9584f47279a1d315c029b2c61e654bbc`.

Completed local manual Chromium UI regression and the native macOS-versus-web multiplayer harness, with iOS Simulator spectating. No app/server/harness source was edited.

## Exceptions and coverage limits

- Built-in recording processing was faulty: the raw 83.267-second capture was compressed to 11.792 seconds. The recommended video is a transparent real-time re-encode at 15fps, 80 seconds, with eight postprocessed captions in an added 50px strip. No gameplay speed changes. Final 3.267 seconds are trimmed to exclude the transition into parity lobbies. Raw evidence is preserved.
- Simulator unified logs contain CoreAudio output-device/volume errors (`560947818`, `-66680`, missing `dOut` device). No gameplay/visual failure accompanied them; actual audio output is unverified.
- Manual browser recorded three script-injection debug messages and no pageerror events. Harness does not persist the web console, so a separate full network-browser console audit is unavailable. Server/static-web/macOS logs were inspected without application exceptions or HTTP failures.
- Android runtime is intentionally untested: external host hardware virtualization blocker.
- Prior room U6WXK8 had expired; a fresh invite was used. This was not an application defect.
- Earlier promotion, premove, keyboard flip, offers and Quick pair/error checks are previous-revision supplemental coverage, not freshly rerun on this fingerprint. No extra scope was added after the token-only change.
- Network gameplay is driven through the automation bridge with frozen clocks; this does not prove human/native pointer input or real-time clock countdown. Manual invite and bot gameplay used real UI actions.

## Current assertions

- **Passed:** Rebuilt current web release, macOS debug and iOS Simulator debug clients; all exited 0.
- **Passed:** Fresh 1440×900 dark/light desktop and exact 375×812 phone lobby captures show the crown brand, full-width arena hero, visible primary actions and legible contrast. Settings expanded for White/unlimited invite creation; Import reached through the lobby.
- **Passed:** Fresh six-character invite **JULPAM**, Ada White and Ben Black; UI moves `1. f3 e5 2. g4 Qh4#` produce checkmate **0–1**.
- **Passed:** Checkmate results at 375×812 in both themes retain fixed card border/background and contain content while scrolling. Offer rematch, Review, Copy PGN and Back to lobby are fully visible; neither scoreboard is covered.
- **Passed:** Review shows current opaque navy coordinates on both square colors; light/dark board and notation remain legible.
- **Passed — Regression:** Play the bot creates room **GWCGRQ**; Ada's `e4` receives Club bot `Nf6`; confirmed resignation produces **0–1**. Both-theme 375×812 result cards remain contained.
- **Passed — Regression:** Real Copy PGN → clipboard paste → Import/Open review preserves Ada, Court Bot · Club, `1. e4 Nf6 0-1`, and resignation termination. Up shows the initial board; Down restores the final position.
- **Passed:** Native macOS White versus web Black, iOS spectator, room **U8LZ5W**; **58/58 assertions**, exit **0**, `passed: true`.
- **Passed:** All clients converge through 33 plies to `17. Rd8# 1-0`, with matching FEN, SAN, result, PGN and frozen clocks **3:32 / 3:30**.
- **Passed:** iOS history retains live moves, reconnect resumes the same game, rematch swaps colors and resets the board/clocks.
- **Passed:** Current iOS active midgame and rematch scoreboards show no overflow stripes or clipped second rows. Native shallow macOS and iOS result cards contain their controls. Secondary seat-detail text can ellipsize on narrow desktop sidebars, but player names, clocks and result actions remain readable.
- **Passed:** Four normalized parity comparisons: lobby/review on iOS and macOS, zero differing blocks in each.
- **Passed:** Nine per-platform lobby/game/results screenshots plus rematch and light-theme screenshots were visually inspected. No new visual regression observed.

## Visual evidence

| Current desktop — light | Current desktop — dark |
|---|---|
| ![Light desktop lobby](https://app.devin.ai/attachments/43c6077d-0181-4afe-a4b7-dd9c13312970/web-lobby-light-1440.png) | ![Dark desktop lobby](https://app.devin.ai/attachments/6c38abc2-a406-4195-9447-10ffd08d1f0e/web-lobby-dark-1440.png) |

| Exact375×812 checkmate — light | Exact375×812 checkmate — dark |
|---|---|
| ![Contained light result](https://app.devin.ai/attachments/6c73d637-aa9d-4993-afdc-2fddc2fd0c19/checkmate-light-375.png) | ![Contained dark result](https://app.devin.ai/attachments/d9207c36-f8af-4a13-8f5e-7934d239ae8e/checkmate-dark-375.png) |

![All three clients visibly show checkmate1–0](https://app.devin.ai/attachments/bfaee7ef-ed0c-4d46-b31b-35d0199ce5ec/fullscreen-checkmate.png)

## Recording audit

Recommended video: `../network/arcade-pass4-final-annotated.mp4`.
Verified metadata: **1600×1250,15fps,1200frames,80.000seconds**; original desktop pixels occupy1600×1200 below the caption strip.

The recording begins with separated settled lobbies, contains the complete match and result hold, and ends on the rematch before parity navigation/resizing. Inspected timeline and beginning/result/end frames show no window overlap in the delivered video. No manual window repositioning or harness pauses. The original structured annotations were approximate around the fast rematch; fallback captions were aligned against captured frames and logs. The final caption explicitly labels58/58 and parity as a post-run audit, not a claim that parity was already completed on screen.

`fullscreen-checkmate.png` is the true all-client result frame extracted at raw60seconds. The earlier late screenshot was relabeled `fullscreen-rematch.png` because it captured the reset board, not checkmate.

Current raw: `/Users/devin/screencasts/arcade-pass4-final/arcade-pass4-final-raw-000.mkv`.
No earlier-revision recordings are offered as current proof.

## Commands and files

- Runtime build logs: `../builds/{web,macos,ios}-runtime.log`.
- Harness invocation and recording processing notes: `../network/commands.txt`.
- Harness assertions/result: `../network/result.json`.
- Harness log/exit: `../network/e2e.log`, `../network/exit-status.txt`.
- Runtime logs: `../network/{server,web-server,macos,ios-runtime}.log`.
- Browser manual console: `browser-console.log`; no page-error file generated.
- Required screenshots: `../network/{web,macos,ios}-{lobby,midgame,results}.png`.
- Full desktop: `../network/fullscreen-lobby.png`, `fullscreen-midgame.png`, `fullscreen-checkmate.png`.
- Current phone/desktop manual captures are in this report's directory.

## Previous-revision supplemental evidence

Preserved pass3 manual evidence covers promotion pickerQ/R/B/N → `bxa8=Q`, PGN round-trip and keyboard history; pass2 covers premove, keyboard flip, Quick pair cancellation and invalid invite errors. Earlier evidence also covers offers and live-clock behavior. These are unchanged-path supplemental observations only. Earlier failed startup and interrupted recordings remain preserved, not relabeled as current.

Nothing required from the user to complete this runtime/UI pass. Audio needs a functioning output device if separately requested.
