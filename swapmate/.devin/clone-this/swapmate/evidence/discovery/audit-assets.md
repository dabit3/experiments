# Audit: assets — provenance and licences

Game artwork is original. Licensed fonts and Flutter icons are listed below:

| Asset | Origin | Licence |
| --- | --- | --- |
| Chess pieces | `app/lib/src/widgets/piece_painter.dart` — vector `CustomPainter` glyphs drawn from geometric primitives | Project code |
| Swapmate mark / logo | `SwapmateMark` widget (`piece_painter.dart`), two interlocking half-boards | Project code |
| Launcher icons (Android mipmaps, iOS AppIcon set, macOS AppIcon set, web icons + favicon) | Rendered from `SwapmateMark` by `app/tool/icons/generate_icons_test.dart` | Project code |
| Colour tokens, gradients, board textures | `app/lib/src/theme/tokens.dart` | Project code |
| Arena illustration, team treatment, result medal, textured backdrop | `app/lib/src/widgets/arcade.dart`, original geometry with Flutter Material symbols | Project code / Flutter icon license |
| Barlow Condensed ExtraBold | `app/assets/fonts/`, Google Fonts `ofl/barlowcondensed` | SIL Open Font License 1.1 (`BarlowCondensed-LICENSE.txt`) |
| Inter font (Regular / Medium / SemiBold / Bold) | `app/assets/fonts/`, from github.com/rsms/inter | SIL Open Font License 1.1 (`Inter-LICENSE.txt` shipped alongside) |
| Material icons | Flutter's bundled `Icons` | Apache 2.0 via Flutter |

No image, audio, sprite, font or text was copied from any commercial chess
product; no trademarked names appear in UI copy (the generic variant name
"Bughouse" is used only in documentation to describe the rules). No audio
assets exist (see states audit). The Wikipedia / chess.com / chessvariants
captures under `evidence/reference/` are research evidence only and are
excluded from git by `swapmate/.gitignore`.
