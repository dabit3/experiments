# Audit: responsive

The same Flutter widget tree is verified at four very different viewports in
the current revision:

| Client | Logical viewport (inside safe area) | DPR | Layout mode | Evidence |
| --- | --- | --- | --- | --- |
| iOS Simulator (iPhone 17 class) | 402 x 778, safe-area top 62 / bottom 34 | 3 | compact / phone, touch controls | `evidence/clone/*-ios.png`, E2E `ios-*.png` |
| Android emulator (landscape tablet-ish) | 1024 x 696 raw | 1 | wide, touch controls | `evidence/clone/*-android.png`, E2E `android-*.png` |
| macOS window | 960 x 608 | 1 | desktop, keyboard hints | `evidence/clone/*-macos.png`, E2E `macos-*.png` |
| Web (Chromium) | 1280 x 800 for E2E; each native size for parity | 1 / native | desktop + reproduces each native layout | `evidence/reference/*-web-for-*.png`, E2E `web-*.png` |

Breakpoints live in `app/lib/theme/tokens.dart` (`PPBreakpoints`) and are
used by home (single vs two-column), lobby (roster/level grid stacking),
results (tile columns) and the game HUD (compact rail). `SafeArea` wraps
home, lobby and results; the game HUD offsets by `MediaQuery.paddingOf`.

The visual parity gate proves that web laid out at a native client's exact
logical size and DPR renders the same pixels as that native client
(`evidence/diffs/visual-parity.json`, 9/9 pass), i.e. layout depends only on
viewport, not platform. Viewport dimensions and paddings each client
actually used are recorded in the same JSON (`view`, `fullView`) and in the
E2E `summary.json` reports (`viewport`).
