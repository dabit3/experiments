# Audit: responsive (2026-09-10T02:05:00Z, git 11a8115)

Layout families: phone (bottom nav, stacked cards, touch controls), tablet (compact rail),
desktop/web (full rail). Themes: light and dark, system-following. Density: safe-area aware
(iPhone notch/home indicator in `evidence/tests/e2e-20260909-184420/ios-lobby.png`).
Captured: desktop 1280x800 @2x light+dark, phone 390x844 @2x light+dark for all four hub
tabs (`evidence/screens/`); in-match HUD at 770x473 (web), 770x532 (macOS content) and
1206x2622 (iPhone 17) in `evidence/tests/e2e-20260909-184420/all-gameplay.png`, `all-matchover.png`.
Typography: Rajdhani (OFL) at a fixed scale; tokens in `client/lib/app/theme.dart`
(spacing s1-s8, radii, elevation, motion durations). Reduced motion toggle honoured.
Cross-platform pixel comparison web→macOS recorded in `evidence/visual/README.md`
(non-zero differences from renderer rasterisation — unresolved, disclosed).

Narrow HUD (390 px phones): the compass stacks under the storm/player column and the
vitals card stacks above the materials/hotbar column when they do not fit side by side
(`compassFits` / `bottomFits` in `match_screen.dart`); the iPhone 17 pane of
`evidence/tests/e2e-20260909-184420/all-midgame.png` shows the stacked layout with no overlap.
