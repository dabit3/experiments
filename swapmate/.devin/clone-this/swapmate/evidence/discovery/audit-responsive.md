# Audit: responsive — layouts, safe areas, input

Breakpoints (`app/lib/src/screens/game_screen.dart`, `home_screen.dart`):

| Width | Layout |
| --- | --- |
| `< 640` (phones portrait) | Single primary board with the partner board as a compact thumbnail, stacked player bars, chat as a bottom sheet behind a FAB, dense chips |
| `>= 700 && landscape` (tablet / phone landscape) | Two boards side by side, compact player bars |
| `>= 1024` (desktop, web, macOS window) | Two full boards + right rail with move list, chat panel and quick-chat strip |
| home `>= 760` | Two-column hero + form; below that a single column |

Every screen wraps content in `SafeArea`; the reconnect banner also respects
the top inset. Text scales with the platform text factor (Inter font family
with a defined type scale in `theme.dart`). Themes: dark (default) and light,
switchable from the home screen and via `theme` parameter; both are captured
in the visual matrix (`*-spec-home-dark`, `*-spec-home-light`).

Input: touch (tap-tap and drag on boards), mouse / trackpad (hover cursor,
click, drag), keyboard (Escape clears selection / closes the chat sheet; text
fields for name, room code, chat), native menus / window chrome on macOS.

Verified captures: web 1280x860 (Playwright), iPhone 17 simulator (portrait,
notch safe area), Android 540x1200 @ 240 dpi, macOS 1180x800 window — see the
final run's `*-lobby.png`, `*-game.png`, `*-results.png` and the cropped
phone comparisons in `visual/`.
