import 'package:flutter/material.dart';

/// Brickfolk design tokens. Every screen composes from these rather than
/// hard-coding numbers so all four platforms render identically.
///
abstract final class BrickColors {
  static const brick = Color(0xFFFF7856);
  static const brickDark = Color(0xFFD94E31);
  static const sky = Color(0xFF526BFF);
  static const skyDark = Color(0xFF2A4FD6);
  static const mint = Color(0xFF21CB9C);
  static const sun = Color(0xFFFFD454);
  static const grape = Color(0xFF8C5CF6);
  static const cherry = Color(0xFFE8455C);
  static const ink = Color(0xFF0D1226);
  static const ink2 = Color(0xFF171F39);
  static const ink3 = Color(0xFF222D4C);
  static const ink4 = Color(0xFF334064);
  static const paper = Color(0xFFF1F3FC);
  static const paper2 = Color(0xFFFFFFFF);
  static const paper3 = Color(0xFFE6EAF7);
  static const paper4 = Color(0xFFCCD4EB);
  static const slate = Color(0xFF606162);
  static const slateLight = Color(0xFF8F9092);

  /// The app chrome (top bar, bottom tabs) stays near-black in both themes.
  static const chrome = Color(0xFF10172E);
  static const chromeRaised = Color(0xFF222C4B);
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
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
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
    textSecondary: Color(0xFFBCC8E5),
    textTertiary: Color(0xFF9CAACA),
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
