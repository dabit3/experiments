# Responsive audit

Breakpoints (`app/lib/src/theme/tokens.dart`): phone < 600 dp, tablet < 960 dp,
desktop >= 1280 dp; content is centred with `ContentWidth` on wide layouts.

| Target | Size class | Layout observed |
|---|---|---|
| iOS Simulator (phone) | phone | bottom navigation bar, single-column place list, touch joystick + jump |
| Android emulator (phone AVD, software GPU) | phone | same as iOS; system insets respected |
| macOS window 1180x792 | desktop | side rail, wide hub layout, keyboard controls |
| Web 1180x760 viewport | desktop | identical to macOS below the title bar (visual items) |

Safe areas: `SafeArea` wraps scaffold bodies and the HUD; the room controls sit
inside the bottom inset on phones.

Evidence: `ios-lobby.png`, `android-lobby.png`, `macos-lobby.png`, `web-lobby.png`
and the corresponding gameplay/results captures.
