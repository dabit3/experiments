# Reference audit — 13 September 2026

Reference: **maimai (2012–), SEGA**. New game: **Orbit Encore**.

## Directly observed

- Official instructions: https://maimai.sega.jp/play/howto/
- Official introduction: https://maimai.sega.jp/play/
- Official ring illustration (downloaded and visually inspected):
  https://maimai.sega.jp/play/howto/assets/pc/play_howto01.png
- Official note-types illustration (downloaded and visually inspected):
  https://maimai.sega.jp/play/howto/assets/pc/play_howto02.png
- Historical gameplay description: https://argw.miraheze.org/wiki/Maimai
- Additional slide explanation:
  https://myaimyai.wordpress.com/2020/02/22/secret-to-sliding-well-esp-for-screen-players/

The official images show a round playfield surrounded by eight chunky illuminated
panels, an inner judgment circle, notes moving outward, colorful central artwork,
and large bright judgments. Pink hollow rings are taps; yellow linked rings are
simultaneous notes; elongated pink notes are holds; blue stars lead cyan chevron
slide paths. Sparkling break notes have increased value. The official text says
to tap the button or screen edge when a ring overlaps the line, hold through the
tail, and trace the arrow route after tapping the star. The historical reference
describes 2012 versus mode, per-player achievement percentages, and extra-weight
break notes.

## Translation to this app

iPhone portrait first: a 390-point-wide playfield offers eight ~50-point peripheral
touch regions and continuous interior slide tracking. Native SpriteKit rendering,
UIKit multitouch and SwiftUI menus. Candy pink/cyan/cream panels, stars, rotating
center art and sparks preserve the visual vocabulary. The original cosmic rabbit
jacket is generated specifically for this game and is used in its actual arena.

Two original tracks: **Sugar Satellite**, 128 BPM, 24 bars, approachable; **Neon
Perihelion**, 150 BPM, 32 bars, denser. Both contain deliberate repeating musical
phrases, tap patterns, paired accents, long holds, star heads and traced arcs /
chords. Charts and audio are generated from the same beat grid. Guest versus uses
a shared chart and scheduled server clock with independent real network players.

## Inferred / deliberately different

Exact historical timing windows, cabinet sensor geometry, scoring internals and
latency compensation are not observable from these assets. This implementation
uses explicitly documented windows and scores, continuous holds, ordered slide
checkpoints, and a LAN WebSocket protocol. Touch/EX types introduced in later
versions are outside the 2012-oriented chart vocabulary. No original songs,
characters, logos, ROMs or extracted assets are shipped.

## Evidence boundaries

No working original arcade cabinet/software is available here. The inspected
official graphics describe current maimai DX, supplemented by historical text.
These are visual/mechanics references, not same-state runtime baselines. Literal
pixel parity and the clone-this strict zero-pixel gate are **not claimed**.
The user's authorized reference-inspired approximation and explicit PR/recording
instructions take precedence over incompatible strict-parity guidance.

## Acceptance inventory

1. Guest name, editable LAN address, create/join/leave and invalid-room errors.
2. Host song selection, both ready, common scheduled start, same chart on both peers.
3. Eight touch lanes; timed tap/break/each; maintained holds; ordered trace slides.
4. Audible original track, beat-linked motion, sparkle judgment, combo/accuracy.
5. Live independent rival scores, consistent result/winner, rematch, reconnect.
6. Native build/lint; timing/protocol tests; two-device recorded complete match.
