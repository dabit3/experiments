# Reference audit — 13 September 2026

Research preceded implementation. Public SEGA instruction illustrations were downloaded and visually inspected; no ROM, arcade binary, licensed song or character was extracted.

## Sources

- https://chunithm.sega.com/play/ — official illustrated gameplay sequence.
- https://chunithm.sega.com/assets/img/play/game/06_pc.png — observed tapered black highway, cyan rails, gold horizontal judgment line, red luminous notes, huge central white combo, gold score strip and character at left.
- https://chunithm.sega.com/assets/img/play/game/08_pc.png — observed broad yellow sustain ribbon, green dimensional upward chevron, hand-raising instruction.
- https://chunithm.sega.com/assets/img/play/game/04_pc.png — observed yellow/white angular music selection, square jacket cards, difficulty blocks and BPM metadata.
- https://argw.miraheze.org/wiki/Chunithm — documented red taps, gold EX taps, tick-based holds that can be recovered, cyan slides with moving position, green air motion notes, timing judgments.
- https://chunithm.fandom.com/wiki/Game_Mechanics — supplementary description of slider and infrared air sensing.
- https://www.sega.jp/arcade/detail/chunithm-air/ — official history of the AIR update.

## Adaptation decisions

**Observed:** recognizable perspective geometry, horizontal broad notes, gold/black/white HUD, contrasting colored trails, combo typography, character side art and jacket selection. Recreated in original native graphics.

**Documented, not independently played:** timing classifications and sustaining across moving slider positions. Implemented with independent server judgments; exact arcade timing windows and score formula are not asserted.

**Original / inferred:** Aria, the sky courier, two composed electronic tracks, charts, sky-city theme, two-player competitive score battle, guest rooms, and mobile timing settings. Character illustration was generated specifically for this app and appears in gameplay and selection.

**Platform:** native iPad landscape. Sixteen slider segments and broad changing touch regions need space for simultaneous fingers and upward gestures. iPad preserves the wide touch surface while keeping character art, opponent scores and the perspective field legible. Air notes use a real upward touchscreen gesture rather than cabinet infrared sensors.

**Inaccessible:** live original arcade software, physical air hardware, private networking, full song/character catalog. No literal or normalized pixel parity claim. The clone-this workflow's source audit, inventory and evidence discipline are used; its zero-pixel gate cannot pass for this authorized original-art adaptation and is not reported as passing.

## Acceptance inventory

| ID | Requirement | Evidence |
|---|---|---|
| V1 | Tapered luminous highway, 16 segments, broad colored notes, side art, gold HUD | Two-device screenshot/recording |
| G1 | Tap timing and miss/combo/accuracy | Engine tests, native touch test |
| G2 | Hold ticks, release penalty and recovery | Engine tests, automated match |
| G3 | Moving slide positions and tail | Engine tests, automated match |
| G4 | Upward gesture air, stationary press insufficient | Engine tests, native input test |
| A1 | Audible authored music aligned to charts and common clock | Composition validation, recording with audio |
| N1 | Two distinct real WebSocket peers, lobby, ready, shared song/start | Protocol tests, two-device recording |
| N2 | Live opponent scoring, common result and rematch | Protocol tests, two-device recording |
| N3 | Capacity, invalid room/input, disconnect and token-based rejoin | Protocol tests, reconnect test |
| U1 | Song selection, guest names, editable LAN address, timing offset, controls guide | Native UI test |

No comparison image is manufactured from the new app. Downloaded reference illustrations remain in the local excluded research evidence directory.
