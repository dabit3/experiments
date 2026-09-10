# Audit: assets (2026-09-10T02:05:00Z, git 11a8115)

All assets are original or openly licensed: Rajdhani font (SIL OFL, licence file
`client/assets/fonts/OFL-Rajdhani.txt`), Material icons via Flutter, programmatic avatars,
gradient "storm" backdrop, original cosmetic names (Recruit, Ember Scout, Tide Runner, Null
Knight, Aurum Warden, Moss Sentinel; tools Splinter/…; gliders Kite Wing/…; banners Fort Mark/…)
in `core/lib/src/cosmetics.dart`. Bot names are original (Juniper, Gale, Rook, Ashfall,
Marrow…). No proprietary logos, characters, audio or trademarked copy are used; the victory
banner reads "Victory" / "Victory. Placed number 1." (no trademarked phrase). Copy reviewed for long-name overflow (16-char name cap
enforced server-side) and large values (XP bar clamps).
Evidence: `evidence/screens/web-desktop-light-locker.png`, `evidence/tests/e2e-20260909-184420/all-results.png`.
