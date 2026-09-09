import 'package:flutter/material.dart';

/// Gambit Court design tokens.
///
/// Palette: "ink & brass" — a warm, near-black ink for surfaces in dark
/// mode, parchment in light mode, brass as the single accent, verdigris for
/// success/online, and a walnut/linen board that reads well against both.
class GcColors extends ThemeExtension<GcColors> {
  const GcColors({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.brass,
    required this.brassInk,
    required this.brassSoft,
    required this.verdigris,
    required this.verdigrisSoft,
    required this.danger,
    required this.dangerSoft,
    required this.boardLight,
    required this.boardDark,
    required this.boardFrame,
    required this.boardCoord,
    required this.lastMove,
    required this.selected,
    required this.legalDot,
    required this.premove,
    required this.checkGlow,
    required this.pieceWhite,
    required this.pieceWhiteInk,
    required this.pieceBlack,
    required this.pieceBlackInk,
    required this.shadow,
  });

  final Color bg;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color brass;
  final Color brassInk;
  final Color brassSoft;
  final Color verdigris;
  final Color verdigrisSoft;
  final Color danger;
  final Color dangerSoft;
  final Color boardLight;
  final Color boardDark;
  final Color boardFrame;
  final Color boardCoord;
  final Color lastMove;
  final Color selected;
  final Color legalDot;
  final Color premove;
  final Color checkGlow;
  final Color pieceWhite;
  final Color pieceWhiteInk;
  final Color pieceBlack;
  final Color pieceBlackInk;
  final Color shadow;

  static const dark = GcColors(
    bg: Color(0xFF110F0D),
    surface: Color(0xFF1A1714),
    surfaceRaised: Color(0xFF221E1A),
    surfaceSunken: Color(0xFF0C0B09),
    border: Color(0xFF2E2823),
    borderStrong: Color(0xFF443B33),
    text: Color(0xFFF3ECE1),
    textMuted: Color(0xFFA79D90),
    textFaint: Color(0xFF6F665B),
    brass: Color(0xFFD9AC4F),
    brassInk: Color(0xFF221A08),
    brassSoft: Color(0x33D9AC4F),
    verdigris: Color(0xFF5FB59E),
    verdigrisSoft: Color(0x2E5FB59E),
    danger: Color(0xFFE06A5A),
    dangerSoft: Color(0x2EE06A5A),
    boardLight: Color(0xFFE6D3B1),
    boardDark: Color(0xFF8C6746),
    boardFrame: Color(0xFF2A221B),
    boardCoord: Color(0xFFB8A484),
    lastMove: Color(0x8CE2B94F),
    selected: Color(0xB3E2B94F),
    legalDot: Color(0x5C1A1208),
    premove: Color(0x805FB59E),
    checkGlow: Color(0xD9E0453A),
    pieceWhite: Color(0xFFF7EEDF),
    pieceWhiteInk: Color(0xFF3A2C20),
    pieceBlack: Color(0xFF2A221C),
    pieceBlackInk: Color(0xFF0B0908),
    shadow: Color(0x99000000),
  );

  static const light = GcColors(
    bg: Color(0xFFF4EEE4),
    surface: Color(0xFFFCF9F3),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEDE5D8),
    border: Color(0xFFE3D9CA),
    borderStrong: Color(0xFFC9BCA8),
    text: Color(0xFF1E1913),
    textMuted: Color(0xFF6E645A),
    textFaint: Color(0xFFA0958A),
    brass: Color(0xFF9E7524),
    brassInk: Color(0xFFFFF8E8),
    brassSoft: Color(0x269E7524),
    verdigris: Color(0xFF2F8571),
    verdigrisSoft: Color(0x262F8571),
    danger: Color(0xFFC24B3C),
    dangerSoft: Color(0x26C24B3C),
    boardLight: Color(0xFFEEDFC2),
    boardDark: Color(0xFF9E7654),
    boardFrame: Color(0xFF5A4432),
    boardCoord: Color(0xFFEADBC0),
    lastMove: Color(0x8CE0B23F),
    selected: Color(0xB3E0B23F),
    legalDot: Color(0x521A1208),
    premove: Color(0x802F8571),
    checkGlow: Color(0xD9D84A3C),
    pieceWhite: Color(0xFFFBF5EA),
    pieceWhiteInk: Color(0xFF3A2C20),
    pieceBlack: Color(0xFF2A221C),
    pieceBlackInk: Color(0xFF0B0908),
    shadow: Color(0x2E2A1A08),
  );

  @override
  GcColors copyWith() => this;

  @override
  GcColors lerp(GcColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return GcColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      textFaint: l(textFaint, other.textFaint),
      brass: l(brass, other.brass),
      brassInk: l(brassInk, other.brassInk),
      brassSoft: l(brassSoft, other.brassSoft),
      verdigris: l(verdigris, other.verdigris),
      verdigrisSoft: l(verdigrisSoft, other.verdigrisSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      boardLight: l(boardLight, other.boardLight),
      boardDark: l(boardDark, other.boardDark),
      boardFrame: l(boardFrame, other.boardFrame),
      boardCoord: l(boardCoord, other.boardCoord),
      lastMove: l(lastMove, other.lastMove),
      selected: l(selected, other.selected),
      legalDot: l(legalDot, other.legalDot),
      premove: l(premove, other.premove),
      checkGlow: l(checkGlow, other.checkGlow),
      pieceWhite: l(pieceWhite, other.pieceWhite),
      pieceWhiteInk: l(pieceWhiteInk, other.pieceWhiteInk),
      pieceBlack: l(pieceBlack, other.pieceBlack),
      pieceBlackInk: l(pieceBlackInk, other.pieceBlackInk),
      shadow: l(shadow, other.shadow),
    );
  }
}

/// Spacing scale (4pt base).
class GcSpace {
  GcSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class GcRadius {
  GcRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double xl = 26;
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

class GcMotion {
  GcMotion._();
  static const Duration micro = Duration(milliseconds: 140);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration piece = Duration(milliseconds: 240);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve spring = Curves.easeOutBack;
}

/// Layout breakpoints (logical pixels).
class GcBreakpoints {
  GcBreakpoints._();
  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

class GcFonts {
  GcFonts._();
  static const display = 'Fraunces';
  static const body = 'Manrope';
  static const mono = 'IBMPlexMono';
}

/// Typography scale. Display uses Fraunces (optical size + softness axes),
/// UI text uses Manrope, and anything tabular (clocks, notation, codes)
/// uses IBM Plex Mono.
class GcType {
  GcType._();

  static TextStyle display(Color color, {double size = 40}) => TextStyle(
    fontFamily: GcFonts.display,
    fontSize: size,
    height: 1.05,
    letterSpacing: -0.02 * size,
    fontWeight: FontWeight.w500,
    fontVariations: const [
      FontVariation('wght', 520),
      FontVariation('opsz', 72),
      FontVariation('SOFT', 30),
    ],
    color: color,
  );

  static TextStyle displayItalic(Color color, {double size = 40}) =>
      display(color, size: size).copyWith(
        fontStyle: FontStyle.italic,
        fontVariations: const [
          FontVariation('wght', 480),
          FontVariation('opsz', 72),
          FontVariation('SOFT', 60),
          FontVariation('WONK', 1),
        ],
      );

  static TextStyle title(Color color, {double size = 22}) => TextStyle(
    fontFamily: GcFonts.display,
    fontSize: size,
    height: 1.15,
    letterSpacing: -0.01 * size,
    fontWeight: FontWeight.w600,
    fontVariations: const [
      FontVariation('wght', 600),
      FontVariation('opsz', 36),
      FontVariation('SOFT', 20),
    ],
    color: color,
  );

  static TextStyle heading(Color color, {double size = 16}) => TextStyle(
    fontFamily: GcFonts.body,
    fontSize: size,
    height: 1.3,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation('wght', 700)],
    letterSpacing: -0.1,
    color: color,
  );

  static TextStyle body(
    Color color, {
    double size = 14,
    FontWeight weight = FontWeight.w500,
    double height = 1.45,
  }) => TextStyle(
    fontFamily: GcFonts.body,
    fontSize: size,
    height: height,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', _wght(weight, 520))],
    color: color,
  );

  static TextStyle label(Color color, {double size = 12}) => TextStyle(
    fontFamily: GcFonts.body,
    fontSize: size,
    height: 1.2,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation('wght', 720)],
    letterSpacing: 0.08 * size,
    color: color,
  );

  static TextStyle button(Color color, {double size = 14}) => TextStyle(
    fontFamily: GcFonts.body,
    fontSize: size,
    height: 1.2,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation('wght', 700)],
    letterSpacing: 0.1,
    color: color,
  );

  /// Variable-font weight axis value for a [FontWeight]; the medium default
  /// is nudged slightly heavier than 500 so body text reads crisply on dark.
  static double _wght(FontWeight weight, double medium) =>
      weight == FontWeight.w500 ? medium : weight.value.toDouble();

  static TextStyle mono(
    Color color, {
    double size = 14,
    FontWeight weight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: GcFonts.mono,
    fontSize: size,
    height: 1.2,
    fontWeight: weight,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color,
  );
}
