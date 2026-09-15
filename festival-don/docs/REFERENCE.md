# Reference research — September 13, 2026

## Sources actually inspected

1. [Bandai Namco arcade 2023 operator manual](https://www.bandainamco-am.com/Ecommerce/Site/Content/PDFs/taiko_temp_manual.pdf), indexed full text, sections 7-4-1 through 7-4-7. The web fetch returned the manual text; a subsequent direct PDF download returned 404. Do not treat this as a locally playable reference.
2. [Official Drum ’n’ Fun page](https://en.bandainamcoent.eu/taiko-no-tatsujin/taiko-no-tatsujin-drumnfun), including its accessible [publisher gameplay screenshot](https://static.bandainamcoent.eu/high/taiko-no-tatsujin/taiko-no-tatsujin-drum%27n%27fun/02-screenshots/3-dlc/STUDIO%20GHIBLI%20Pack%20Vol2%20%281%29.jpg). Downloaded and visually inspected the full 1568×882 screenshot. This is a later console reference, not proof of the exact 2006 cabinet presentation.
3. [Taiko 12 arcade description](https://www.highwaygames.com/arcade-machines/taiko-no-tatsujin-12-arcade-machine-9998/): simultaneous two-player support, horizontal symbols, varied music categories.
4. [Community control/timing guide](https://taikonc.github.io/en-how.html): center/red, rim/blue, strong/big, rolls, GOOD/OK/BAD, combo and crowns. Supplementary, not an official specification for numerical timing windows.

## Observed

- Right-to-left note travel, a fixed circular hit frame on the left; red center notes and light-blue rim notes have faces, ivory rings and thick dark contours.
- The screenshot has a dark maroon staff, black separators, a left score panel, a huge combo count, a multicolored segmented clear gauge above the lane, a bright gold judgment burst and note syllables beneath the notes.
- Festival artwork occupies substantial space: layered scalloped waves, warm orange/yellow print patterns, dancing smiling drum characters, Mount Fuji forms, fans and clouds. It is energetic and densely illustrated rather than a minimal neon rhythm UI.
- The manual describes a shared one/two-player performance, song and difficulty selection, center/rim sound differences, big notes, and repeated drum strikes.
- Official console description explicitly supports touch controls and local wireless play.

## Festival Don adaptation (authored, not observed parity)

- Landscape iPhone, native SwiftUI/Canvas artwork and a UIKit multi-touch drum surface. Red/orange and turquoise guest mascots wear original festival headbands.
- Main lane plus a compact live rival staff preserves the horizontal shared performance while leaving room for two large touch drums.
- Two original instrumental compositions with fixed authored phrase charts: **Lantern Parade** (112 BPM) and **Moonlit Matsuri** (136 BPM). Generated taiko, rim, shaker, bass and pentatonic melody audio is bundled, never streamed.
- Big notes accept a normal one-hand strike, with a doubled award for matching opposite-hand strikes within 75 ms. This substitutes two fingers for the cabinet's strike-strength sensor.
- GOOD ±45 ms, OK ±100 ms, BAD beyond 100 ms; misses after 140 ms plus a 250 ms network grace. These are explicit design choices, not claims about arcade timing.
- Local guests and a room code replace arcade coins/cards; server-authoritative scores and a common song epoch replace a shared cabinet process.
- No licensed songs, ripped sprites, ROMs, brand marks or original character art are shipped. All graphics in the app are authored vector drawings.

## Evidence boundary and inventory

The `clone-this` research/evidence workflow was read on disk and initialized under `.devin/clone-this/festival-don/`. Exact pixel comparison, interacting with a source cabinet, and exhaustive original-game behavior are inaccessible. The user's explicit allowance for visual approximation supersedes the skill's zero-pixel and no-approximation gates. No strict parity gate is claimed as passed.

Acceptance inventory: lobby/create/join/errors/leave; song selection/preview; difficulty; manual calibration; local and rival staff; center/rim; two-hand big notes; rolls; combo/judgments/gauge; local scheduled audio; live scores; disconnect/rejoin; common results; rematch; two complete simultaneous device displays with genuine network input evidence. Functional outcomes must be tested separately from visual resemblance.
