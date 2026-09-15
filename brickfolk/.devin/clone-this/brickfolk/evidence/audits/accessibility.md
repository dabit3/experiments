# Accessibility audit

Arcade redesign: `arcade-ui.md` records 1.5x text, phone search, Tab/Enter on
world cards, native arrow-key movement and joystick movement at arena walls.

- Token contrast (recomputed from `theme/tokens.dart`): ink on paper 16.76:1,
  slate on paper 5.61:1, ink on mint 8.91:1, slateLight on ink 5.81:1,
  white on sky 4.28:1 and brand coral on white 2.60:1. These are token-pair
  measurements, not a claim that every text placement meets WCAG contrast.
- Semantics: touch controls expose `Semantics` labels (joystick, jump, avatar
  preview); icon buttons carry tooltips (leave, chat, send, theme, settings,
  decline, join, turn around).
- Keyboard: web/macOS gameplay uses WASD/arrows + space; the hub is traversable
  with Tab; the sign-in field autofocuses and submits on Enter.
- Motion: entrance animations are short (140-420 ms, `Motion` tokens).
- Text scaling: podium and lobby tags use `Flexible`/`FittedBox` so larger text
  does not overflow.
- Touch targets: filled/tonal buttons have a 48x48 minimum (`theme.dart`);
  Material icon buttons use the 48 dp default.

Known limits (recorded honestly): no screen-reader pass was run on a device;
`disableAnimations` is not consulted; the Flame canvas is not described to
assistive technology beyond the HUD text widgets.

Evidence: `app-test.log` (widget tests including theme tests).
