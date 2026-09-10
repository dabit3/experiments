# Audit: accessibility

| Requirement | Status | Evidence / location |
| --- | --- | --- |
| Buttons expose semantics | every custom button wraps `Semantics(button: true, label)` (`widgets/ui.dart`); on-screen game buttons and the joystick have labels (`game_screen.dart`) | `flutter analyze` clean; source |
| Icon buttons have tooltips | help, theme, menu, emote, bot add/remove, disabled Start explains why | `lobby_screen.dart`, `home_screen.dart`, `game_screen.dart` |
| Keyboard operability | full game playable with keyboard (move, grab, action, dash, emote, menu); lobby/home use standard focusable Material controls | README controls table; E2E macOS/web seats are keyboard-hinted (`macos-gameplay.png`) |
| Touch targets | on-screen controls 64-72 px, buttons >= 48 px tall (`PPSize`) | iOS/Android gameplay screenshots |
| Contrast | tokens chosen for >= 4.5:1 body text on both themes (`tokens.dart`); dark and light verified | ui-smoke dark/light captures |
| Safe areas | home/lobby/results in `SafeArea`; HUD offsets by padding | iOS captures (notch + home indicator respected) |
| Text scaling | Material text theme, no fixed-height text boxes on menus | not screenshot-verified at 200 % - recorded as an open, non-blocking deviation |
| Reduced motion | not honoured (`PPMotion` durations are constant) | recorded deviation; animations are short (<= 320 ms) and never gate input |
| Colour-only information | ready state uses chip text + icon, not colour alone; timers show bars and seconds | lobby / gameplay screenshots |

Deviations above are recorded rather than claimed; none of them blocks the
documented journeys.
