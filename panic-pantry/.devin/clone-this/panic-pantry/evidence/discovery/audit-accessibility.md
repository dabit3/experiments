# Audit: accessibility

| Requirement | Status | Evidence / location |
| --- | --- | --- |
| Buttons expose semantics | every custom button wraps `Semantics(button: true, label)` (`widgets/ui.dart`); on-screen game buttons and the joystick have labels (`game_screen.dart`) | `flutter analyze` clean; source |
| Icon buttons have tooltips | help, theme, menu, emote, bot add/remove, disabled Start explains why | `lobby_screen.dart`, `home_screen.dart`, `game_screen.dart` |
| Keyboard operability | gameplay shortcuts; custom buttons use FocusableActionDetector with Enter/Space and a focus border | widget tests in `unit-tests.log`; real UI pass `evidence/tests/arcade-ui/report.md` |
| Touch targets | on-screen controls 64-72 px, buttons >= 48 px tall (`PPSize`) | iOS/Android gameplay screenshots |
| Contrast | light/dark rendering inspected; light lobby thresholds use darker gold and unlit dark HUD stars use translucent white | ui-smoke captures and `arcade-ui/report.md`; no blanket WCAG compliance claim |
| Safe areas | home/lobby/results in `SafeArea`; HUD offsets by padding | iOS captures (notch + home indicator respected) |
| Text scaling | Material text theme, no fixed-height text boxes on menus | not screenshot-verified at 200 % - recorded as an open, non-blocking deviation |
| Reduced motion | staggered Enter respects disableAnimations; other animations retain their timings | whole-app reduced-motion behavior not verified |
| Colour-only information | ready state uses chip text + icon, not colour alone; timers show bars and seconds | lobby / gameplay screenshots |

Deviations above are recorded rather than claimed; none of them blocks the
documented journeys.

Arcade pass: both iOS landscape notches and portrait HUD geometry verified
through real touch. Long washing coach and combo/stars are separate from the
clock. Host button labels scale down within narrow bounds. Touch geometry
and entrance/keyboard regressions also pass five widget tests.
