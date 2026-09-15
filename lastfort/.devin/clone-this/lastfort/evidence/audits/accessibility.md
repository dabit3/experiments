# Audit: accessibility (2026-09-10T02:05:00Z, git 11a8115)

Semantics: nav items, buttons and toggles carry `Semantics`/labels (21 explicit Semantics
nodes in `client/lib`); icon buttons have tooltips ("Copy code", "Change name", "Dismiss").
Keyboard: full gameplay and hub are keyboard-operable on web/macOS (controls table in the
Settings screen, `evidence/screens/web-desktop-light-settings.png`); focus rings use the
ember accent. Touch targets ≥ 44 pt on phone layouts; on-screen joystick/fire/build buttons
(`client/lib/screens/touch_controls.dart`). Reduced motion and haptics toggles in Settings.
Deviation recorded: Flutter web exposes the semantics tree only after the user opts in via the
"enable accessibility" placeholder (framework behaviour, not overridden).
