# Reference audit — 13 September 2026

## Access and evidence

Reference: **beatmania IIDX**, especially the 2006 DistorteD era and later charge
notes. Only public pages and legitimately published photos were consulted.
No game binaries, ROMs, music, or KONAMI artwork are redistributed.

- [Official KONAMI screen guide](https://p.eagate.573.jp/game/2dx/33/howto/play/game_screen.html):
  read before implementation. Describes NOTES, CHORD, PEAK, CHARGE, SCRATCH and
  SOF-LAN chart traits, score graphs and gauge variations.
- [RemyWiki gameplay guide](https://remywiki.com/What_is_beatmania_IIDX):
  seven keys (four white, three black/blue), eighth scratch lane, descending bars,
  red judgment line, GREAT/GOOD/BAD/POOR, 22% starting gauge and 80% clear border.
- [Charge note guide](https://iidx.org/beginner/cn):
  press at the head and release at the tail, with both endpoints judged.
  BSS requires sustained spin and reversal; this app implements ordinary scratch
  notes and key charge notes, not BSS/HCN/MSS.
- [Contemporary DistorteD photo index](https://www2u.biglobe.ne.jp/hiro-p/list/besqubm2dx13_distorted.htm):
  documents black as the 2006 theme color, high-speed controls and difficulty.
- [Gameplay detail photo, directly inspected](https://www2u.biglobe.ne.jp/hiro-p/photo/bm2dx13/bm2dx13_beginner_02.jpg):
  observed luminous cyan beveled frame, dark lanes, alternating ivory/dark key
  faces, scarlet judgment line, tightly segmented red/cyan gauge and blue digital
  score. Photo is 350 × 250, partial and photographed at an angle.
- [Selection photo, directly inspected](https://www2u.biglobe.ne.jp/hiro-p/photo/bm2dx13/bm2dx13_seiryuu_01.jpg):
  observed dense technical labels, angular panels, large central abstract art,
  difficulty strip and score metadata.

## Design decisions and limits

Native iPhone landscape. At the baseline 852 × 393 logical viewport, the seven
keys each occupy about 55 points and the scratch wheel is about 106 points.
The player can place the phone flat and use multiple fingers. iPad is supported
by proportional layout. The blue/monochrome illuminated deck is authored vector
art actually rendered in gameplay, not an unused promotional image.

Observed elements retained: alternating narrow dark/light vertical lanes, wider
scratch lane, compact note bars, red target line, emphatic judgment text, EX score,
combo, groove gauge, turntable, animated background and dense music metadata.

Inferred/our design: geometric orbital club visualizer, modern native lobby,
guest room networking, two-player live EX race, chart, song, timing windows and
calibration. Our windows are ±25/55/95/140 ms and do not claim to reproduce any
specific arcade hardware's timing. Multitouch replaces physical cabinet keys.
Original 128 BPM track “AFTERIMAGE / 03:17” is synthesized from authored drums,
bass, arpeggio and pads, with a fixed musically structured chart.

The original arcade program is inaccessible here. No matching live reference
state can be captured, and the public photo has a different viewport. Literal
pixel parity and original game's interactive parity are **unverified**.
The clone-this research, inventory, evidence and convergence workflow is used;
its zero-pixel gate is not asserted as passed, per the user's approximation
permission. The scoped acceptance inventory is below.

## Acceptance inventory

| ID | Requirement | Verification |
|---|---|---|
| R01 | Seven touch/keyboard keys + scratch gesture | Native two-device test, manual controls |
| R02 | Authored audible song and coherent fixed chart | WAV analysis + playback/recording |
| R03 | Tap, chord, hold head/tail and misses | Server judgment tests + real app driver |
| R04 | Timing calibration and speed adjustment | Controls + protocol timing checks |
| R05 | Distinct peers, room code, readiness, common start | Real WebSocket integration + native test |
| R06 | EX/combo/gauge/live opponent results | Native match assertions |
| R07 | Rematch and disconnected peer recovery | Integration + native recorded rematch/rejoin |
| R08 | Native release build and lint | xcodebuild + swift-format |
| R09 | Moving two-device evidence and outcome | Simultaneous recording + ffprobe + inspection |
| R10 | Reference visual parity | Approximation only; original executable inaccessible |
