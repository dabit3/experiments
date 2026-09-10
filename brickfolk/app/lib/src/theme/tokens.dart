import 'package:flutter/material.dart';

/// Brickfolk design tokens. Every screen composes from these rather than
/// hard-coding numbers so all four platforms render identically.
///
/// Neutral ramps follow the near-black / cool-grey convention of modern game
/// platform shells (dark `#191A1F` base, `#2A2B32` / `#35363D` raised
/// surfaces, `#F2F4F5` light base) with one vivid blue system accent.
abstract final class BrickColors {
  static const brick = Color(0xFFFF6B4A);
  static const brickDark = Color(0xFFD94E31);
  static const sky = Color(0xFF335FFF);
  static const skyDark = Color(0xFF2A4FD6);
  static const mint = Color(0xFF00B06F);
  static const sun = Color(0xFFF5C04A);
  static const grape = Color(0xFF8C5CF6);
  static const cherry = Color(0xFFE8455C);
  static const ink = Color(0xFF191A1F);
  static const ink2 = Color(0xFF232529);
  static const ink3 = Color(0xFF2A2B32);
  static const ink4 = Color(0xFF35363D);
  static const paper = Color(0xFFF2F4F5);
  static const paper2 = Color(0xFFFFFFFF);
  static const paper3 = Color(0xFFE3E5E8);
  static const paper4 = Color(0xFFD1D4D8);
  static const slate = Color(0xFF606162);
  static const slateLight = Color(0xFF8F9092);

  /// The app chrome (top bar, bottom tabs) stays near-black in both themes.
  static const chrome = Color(0xFF191A1F);
  static const chromeRaised = Color(0xFF232529);
  static const onChrome = Color(0xFFFFFFFF);
  static const onChromeMuted = Color(0xFFBDBEBE);
}

abstract final class Space {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

abstract final class Radii {
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const pill = 999.0;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 420);
  static const springy = Curves.easeOutBack;
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubicEmphasized;
}

/// Responsive breakpoints (logical pixels).
abstract final class Breakpoints {
  /// Small phones (320-400 logical px): single-purpose header rows.
  static const compact = 400.0;
  static const phone = 600.0;
  static const tablet = 960.0;
  static const desktop = 1280.0;
}

enum FormFactor { phone, tablet, desktop }

FormFactor formFactorOf(double width) {
  if (width < Breakpoints.phone) return FormFactor.phone;
  if (width < Breakpoints.tablet) return FormFactor.tablet;
  return FormFactor.desktop;
}

extension FormFactorX on BuildContext {
  FormFactor get formFactor => formFactorOf(MediaQuery.sizeOf(this).width);
  bool get isPhone => formFactor == FormFactor.phone;
  bool get isDesktop => formFactor == FormFactor.desktop;
}

/// Semantic colors that change with brightness.
class BrickPalette extends ThemeExtension<BrickPalette> {
  const BrickPalette({
    required this.surface0,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.outline,
    required this.success,
    required this.warning,
    required this.danger,
    required this.shadow,
  });

  final Color surface0;
  final Color surface1;
  final Color surface2;
  final Color surface3;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color outline;
  final Color success;
  final Color warning;
  final Color danger;
  final Color shadow;

  static const dark = BrickPalette(
    surface0: BrickColors.ink,
    surface1: BrickColors.ink2,
    surface2: BrickColors.ink3,
    surface3: BrickColors.ink4,
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFBDBEBE),
    textTertiary: Color(0xFF8B8D90),
    outline: Color(0x1AFFFFFF),
    success: BrickColors.mint,
    warning: BrickColors.sun,
    danger: BrickColors.cherry,
    shadow: Color(0x66000000),
  );

  static const light = BrickPalette(
    surface0: BrickColors.paper,
    surface1: BrickColors.paper2,
    surface2: BrickColors.paper3,
    surface3: BrickColors.paper4,
    textPrimary: Color(0xFF191A1F),
    textSecondary: Color(0xFF606162),
    textTertiary: Color(0xFF8F9092),
    outline: Color(0x14000000),
    success: Color(0xFF00A061),
    warning: Color(0xFFCB9A1C),
    danger: Color(0xFFD1364C),
    shadow: Color(0x1F1B2233),
  );

  @override
  BrickPalette copyWith() => this;

  @override
  BrickPalette lerp(BrickPalette? other, double t) {
    if (other == null) return this;
    return BrickPalette(
      surface0: Color.lerp(surface0, other.surface0, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension PaletteX on BuildContext {
  BrickPalette get palette => Theme.of(this).extension<BrickPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
