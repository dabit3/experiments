# Audit: responsive — layouts, safe areas, input

Breakpoints (`app/lib/src/screens/game_screen.dart`, `home_screen.dart`):

| Width | Layout |
| --- | --- |
| Otherwise (portrait/compact) | Single primary board with the partner board as a compact thumbnail, stacked player bars, chat as a bottom sheet behind a FAB, dense chips |
| `>= 700 && landscape` (tablet / phone landscape) | Two boards side by side, compact player bars |
| `>= 1024` (desktop, web, macOS window) | Two full boards + right rail with move list, chat panel and quick-chat strip |
| home `>= 760` | Two-column hero + form; below that a single column |

Every screen wraps content in `SafeArea`; the reconnect banner also respects
the top inset. Text scales with the platform text factor (Inter body and
Barlow Condensed display type in `theme.dart`). Themes: dark (default) and light,
switchable from the home screen and via `theme` parameter; both are captured
in the visual matrix (`*-spec-home-dark`, `*-spec-home-light`).

Input: touch (tap-tap and drag on boards), mouse / trackpad (hover cursor,
click, drag), keyboard (Escape clears selection / closes the chat sheet; text
fields for name, room code, chat), native menus / window chrome on macOS.

Verified captures: web 1180x800 (Playwright), iPhone 17 simulator (portrait,
notch safe area), Android 540x1200 @ 240 dpi, macOS 1180x800 window — see the
final run's `*-lobby.png`, `*-game.png`, `*-results.png` and the cropped
phone comparisons in `visual/`.

## Re-audit after the compact partner-row fix (final revision)

A live iPhone + web session showed the phone layout's partner-board row
(`_miniBoardRow`) overflowing by ~12 px once both compact player bars held
reserve pieces: the row was pinned to a fixed 104 px. The row now sizes
itself (`IntrinsicHeight`, player bars `mainAxisSize: min`) and the square
partner board fits that height; the main board keeps the remaining
`Expanded` space. Re-verified on the iPhone 17 simulator in run
`e2e-20260910T152718Z` (`ios-game.png`: no overflow banner, partner board,
both bars with reserves and clocks fully visible). The phone-landscape and
desktop layouts are untouched; their captures in the same run are unchanged
in geometry.

## Arcade redesign layout pass

`arcade_layout_test.dart` sets both physical viewport size and DPR, loads
the local display/body/icon fonts, and renders every screen at 320×640,
390×844, 800×600 and 1180×800 in dark and light mode. Full five-piece reserves
and long names stress player bars. All 32 renders are exception-free in
`evidence/tests/arcade-quality.log`; captures are under `arcade-layout/`.
Manual image inspection caught the small result title breaking inside
"VICTORY"; the title now scales as one line. Lobby/result headers compact
at narrow widths, medium game bars use smaller clocks, and compact reserve
trays scroll horizontally rather than overflow. This supplements the
live iOS/Android/macOS/web capture matrix.

The SafeArea backdrop alignment was rechecked in
`partial-visual-current`: all three iOS comparisons and all four macOS
comparisons normalize to zero under the unchanged bounds; the three negative
controls remain nonzero. Android's current visual rows remain pending because
its guest operating system crashed during the four-client run. Sustained 60
fps has not been measured on all targets and remains an explicit pending item.
