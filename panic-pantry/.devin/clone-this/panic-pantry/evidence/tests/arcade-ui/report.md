# Arcade redesign: independent UI verification

Tested freshly rebuilt web, native macOS and iOS Simulator clients through
real pointer, keyboard and touch input. The final targeted pass rebuilt web
and iOS after the shared button and reconnect Material fixes. No server
state injection was used for manual gameplay. Android's scripted match and
normalized screenshot evidence are recorded separately.

After these interaction passes, the automated visual gate found that the
decorative results confetti used the full device area while the content used
the safe area. The final change aligns the backdrop's motifs to the safe
area while keeping its gradient full bleed. It changes no input or room
behavior. Selected level and shared panel borders were also aligned to the
pixel grid, and the results score size changed from 62 to 64. Final clean
builds and the complete scripted verification matrix were rerun after these
decorative changes; these manual recordings precede them. A final tablet
clock-alignment correction also postdates these recordings. Its regression
first failed at a right edge of 643.6 instead of 1012 logical pixels, then
passed after the footer distributed the remaining horizontal space. The
six widget tests cover this correction and the existing phone safe areas.

## Design and interaction coverage

- Home: original kitchen hero, light/dark palettes, desktop, 900px and
  800×520 layouts; form controls and host/join navigation.
- Keyboard: Tab focus, Enter opens Help, Space activates Host.
- Lobby: all five cards finish fully opaque; selection updates details;
  bot add/remove/re-add, chef portraits, ready/start gating and roster.
- Web/macOS/iOS joined the same room and matched 231 points, 2 stars and
  6 serves in a manually observed match.
- Web WASD/Space/held-E completed chopping, cooking, plating and serving.
  Dirty plate return and held-E washing increased the clean rack count.
- Native iOS joystick, Grab and held Action chopped a tomato without bots.
  Releasing the joystick stopped movement.
- Portrait and both landscape orientations kept the long washing coach,
  score, x2–x4 combo, stars and stopwatch separate and clear of the notch.
  Artificial 9999-point geometry is covered by the widget tests, not this
  manual pass.
- Natural final-seconds red clock, overtime while holding a plated dish,
  results, rematch and leaving were exercised.
- A zero-star round followed by Rematch displays `best 0/3`.
- Transient network loss resumes the same room. Full server restart
  returns Home with the kitchen-closed toast; hosting again succeeds.
- Final desktop demonstration completed a bot-assisted Training round at
  340 points / 3 stars / 7 serves / 200 tips, then rematched and left.

## Final targeted regression

`panic-pantry-two-polish-fixes-edited.mp4` is a 21-second annotated proof:

- Portrait host Ready/Start labels fit in both disabled and enabled states;
  tapping Start enters gameplay.
- Reconnecting title/body have normal text styling without yellow
  underlines; connectivity restoration resumes room XNGK and Ready works.

Full screenshots: `polish-fixed-ios-host-ready.png`,
`polish-fixed-ios-host-not-ready.png`, `polish-fixed-ios-started.png`,
`ss_063bcb6e.png` (reconnect) and `ss_91ee254a.png` (restored room).

## Other evidence and limits

- `panic-pantry-polished-desktop-edited.mp4`: 22-second product demonstration.
- `panic-pantry-final-ui-edited.mp4`: 99-second footer/overtime/zero-star/restart pass.
- `panic-pantry-native-touch-final-edited.mp4`: solo touch proof; contains the
  host-button finding that was subsequently fixed in the targeted regression.
- `panic-pantry-final-state-flows-edited.mp4`: transient reconnect proof.
- Full coach screenshots cover portrait and both landscape orientations.
- Browser console had the existing Intl deprecation and expected errors
  during intentional disconnects. Final automated smoke separately rejects
  application console errors.
- Full 200% text scaling and Android manual touch gameplay were not tested.
- The first reconnect proxy experiment stalled; the direct server-restart
  retry passed. Small joystick deflections were needed for precise alignment.
