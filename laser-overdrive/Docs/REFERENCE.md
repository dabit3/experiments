# Reference research — 13 September 2026

Reference: **Sound Voltex (2012–)**. This is an original, reference-inspired iPhone
game, not an official port. No Konami art, music, character assets or extracted
game software are bundled.

## Accessible evidence

- [Official current how-to](https://p.eagate.573.jp/game/sdvx/vii/howto/play.html)
- [Official PC/III how-to](https://p.eagate.573.jp/game/eacsdvx/iii/p/common/info/sdvx_howto.html)
- [Official gameplay image](https://eacache.s.konaminet.jp/game/sdvx/vii/images/howto/play/02_1.webp)
- [Official controller image](https://eacache.s.konaminet.jp/game/sdvx/vii/images/howto/play/03_1_1.webp)
- [Official laser action image](https://eacache.s.konaminet.jp/game/sdvx/vii/images/howto/play/03_1_2.webp)

The official gameplay and controller images were downloaded and visually inspected
before implementation. They show a steep perspective track, thin lane separators,
cyan and magenta track edges, white rectangular BT notes, warm orange FX notes, a
bright near-bottom critical line, central combo, a tall right-edge effective-rate
meter, angular instrument panels and two illuminated rotary controllers. These
are the visual priorities of the authored renderer.

The official text explicitly describes four BT buttons, two FX buttons, white
taps/holds, orange taps/holds, blue-left and red-right analog laser lines, gradual
rotation on slopes and quick rotation on right angles. It specifies CRITICAL/ERROR
judgments and a 70% effective-rate clear threshold. These mechanics are implemented
as separate scoring systems rather than treating all objects as taps.

## Adaptation and inferences

- Cyan/magenta gestures use two independent relative horizontal swipe pads with
  rotary visual feedback. A rapid swipe follows a laser slam. This is an iPhone
  adaptation of physical knobs, not a claim of identical arcade hand feel.
- The portrait screen retains the perspective highway, score, opponent, combo,
  effective-rate rail and bottom controller. No character portrait is copied:
  the original geometric “photon core” provides the track artwork.
- Original track **ION / AFTERBURN**, 144 BPM, E minor, has composed sections
  (ignition, voltage, crossover, overdrive), aligned notes, holds, paired FX and
  continuous laser paths. Difficulty is authored for a compact touch surface.
- Timing windows, score weights, chart, laser tolerance, network protocol,
  lobby, result layout and guest identities are original implementation choices.
- Multiplayer is a synchronous score duel with live opponent data; it is not a
  reconstruction of Konami's private matching service.

## Evidence boundary

The original cabinet and executable were not available for interactive comparison.
The accessible images include annotation overlays and are not matching-resolution
runtime captures. Literal pixel parity, original charts/audio and exact cabinet
latency cannot be verified. The clone-this research/evidence workflow was read and
used; its zero-pixel-difference completion gate is intentionally **not claimed**.
User-approved approximation and the requested PR/evidence delivery take precedence.
