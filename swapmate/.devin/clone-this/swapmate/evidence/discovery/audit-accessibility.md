# Audit: accessibility

Inspected `app/lib` for semantics, focus, contrast and target sizes.

- Semantics: `Semantics` labels on the connection pill ("Connection Online ·
  12 ms"), clocks ("white clock 4:59"), reserve tiles ("Drop knight, 2 in
  hand", `button: true`), time-control chips (`selected`), seat cards and both
  boards ("Board A"). Icon buttons carry `tooltip`s (Game menu, Leave room,
  Copy code, Add bot, Light/Dark theme, Send), which double as accessibility
  labels.
- Targets: `IconButton` / `FilledButton` themes set `minimumSize: Size(48,
  48)`; the primary home CTA is 52 px tall; board squares are >= 44 px on every
  captured device.
- Keyboard: Escape (`DismissIntent`) clears the current selection or closes the
  chat sheet; text fields submit with Enter (`TextInputAction.done/send`);
  the game screen holds focus via `Focus(autofocus: true)`.
- Contrast: token pairs in `tokens.dart` were chosen for >= 4.5:1 body text on
  surfaces in both themes (`text` on `bg`/`surface`, `textMuted` for
  secondary); light and dark captures are part of the visual matrix.
- Motion: all animations use the shared `Motion` durations (<= 620 ms) and
  none loop indefinitely except the reconnect progress indicator.
- Colour is never the only channel: check state is shown by a ring + haptic,
  the side to move by text ("to move") and a highlighted clock, team by badge
  text.
- Not verified: screen-reader traversal on device (no VoiceOver/TalkBack run
  in the automated harness) — recorded as a limitation, not a claim.
