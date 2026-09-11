# Arcade redesign: UI verification

Source commit: `921cef2` (the final formatting-only change followed the native
spot-check). The main shared-match run preceded only the selected-touch-control
contrast fix. That fix was checked separately using a fresh iOS build.

The testing agent rebuilt the web and iOS clients, drove both interfaces, and
recorded the following observations. These are UI observations, separate from
the deterministic automated match report.

## Shared room and gameplay

- WebArcade and IosArcade created/joined room `LY8NN`, started the same 16-player
  Solo match, and reached results. Winner: Morrow; web placement #5; iOS #4.
  Both scoreboards contained the same 16 players and winner.
- Keyboard and native touch movement/drop worked. Web keys 1–6 selected their
  matching hotbar slots. Harvesting changed wood from 0 to 30; placing a wall
  changed it from 30 to 20.
- Both clients displayed the shared storm and eliminations. Native terrain,
  tree canopies, resource rocks and armored player silhouettes painted.
- Solo spectating displayed positive placements, without `#0`. Results and
  return-to-room navigation worked; the same room supported another match.
- Native weapon acquisition and held right-stick firing consumed ammo
  30 → 23 → 0.

Evidence: `manual-match.mp4`, `same-room-ready-{web,ios}.png`,
`shared-bus-{web,ios}.png`, `shared-ground-{web,ios}.png`,
`results-1-{web,ios}.png`, `scoreboard-{dark-web,light-ios}.png`,
`returned-same-room-{web,ios}.png`, `native-fire-held-ios.png`.

## Presentation and fixes

- Desktop and phone hub layouts, light/dark themes, Locker, Pass and Settings
  were inspected. The native scout body/visor and party labels painted.
- Light-theme empty party cards and JOIN controls have readable surfaces.
- Narrow gameplay HUD panels remained separated.
- Web lobby motion changed 3,612 pixels between normal captures; reduced-motion
  captures 1.2 seconds apart were identical.
- Native logs reviewed by the agent contained no Flutter painting exception.
- A fresh iOS build verified the final selected SPRINT and BUILD/COMBAT states:
  opaque light/wood fills with navy icon/text. Toggling off restored the dark
  unselected controls and removed the build controls. No new defect was found.

Evidence: `desktop-play-dark-fixed-web.png`, `phone-play-light-fixed-web.png`,
`play-light-join-fixed-ios.png`, `motion-*.png`, `ios-unified-log.txt`,
`touch-contrast.mp4`, `touch-fixed-{unselected,selected,toggled-off}-ios.png`.

## Coverage limits

- Actual human-to-human damage was not conclusively observed.
- The Duos teammate-alive `SQUAD STILL IN` branch was not exercised.
- Native results-animation timing and gameplay storm-pulse timing were not
  conclusively compared. Human victory/confetti was not observed in the manual
  run; automated squad results are separate evidence.
- This UI pass did not exercise Android or macOS. Android cannot boot on this
  host; macOS retains earlier runtime evidence and receives a fresh clean build.
- This is not a claim of literal parity with the inaccessible commercial game,
  or zero-difference cross-renderer pixels.
