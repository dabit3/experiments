import 'package:flutter/material.dart';

class GcArcade {
  GcArcade._();
  static const midnight = Color(0xFF101B46);
  static const royal = Color(0xFF254BCB);
  static const sunshine = Color(0xFFFFD34D);
  static const porcelain = Color(0xFFF6F8FF);
  static const aqua = Color(0xFF59E1DD);
}

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
    bg: GcArcade.midnight,
    surface: Color(0xFF172653),
    surfaceRaised: Color(0xFF203465),
    surfaceSunken: Color(0xFF0C173A),
    border: Color(0xFF304576),
    borderStrong: Color(0xFF506698),
    text: GcArcade.porcelain,
    textMuted: Color(0xFFBBC9EB),
    textFaint: Color(0xFF8FA4D1),
    brass: GcArcade.sunshine,
    brassInk: GcArcade.midnight,
    brassSoft: Color(0x26FFD34D),
    verdigris: GcArcade.aqua,
    verdigrisSoft: Color(0x2659E1DD),
    danger: Color(0xFFFF857E),
    dangerSoft: Color(0x2EFF857E),
    boardLight: Color(0xFFE4EAF8),
    boardDark: Color(0xFF6581BA),
    boardFrame: Color(0xFF223B73),
    boardCoord: Color(0xFFD2DEF7),
    lastMove: Color(0xA6FFD34D),
    selected: Color(0xD9FFD34D),
    legalDot: Color(0x73101B46),
    premove: Color(0x9959E1DD),
    checkGlow: Color(0xE6EF625C),
    pieceWhite: Color(0xFFFFF9E6),
    pieceWhiteInk: Color(0xFF485984),
    pieceBlack: Color(0xFF233B70),
    pieceBlackInk: Color(0xFF091737),
    shadow: Color(0x99060D27),
  );

  static const light = GcColors(
    bg: Color(0xFFEDF2FF),
    surface: Color(0xFFF8FAFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFE4EAFA),
    border: Color(0xFFD2DCF1),
    borderStrong: Color(0xFFA8BADD),
    text: GcArcade.midnight,
    textMuted: Color(0xFF4E638A),
    textFaint: Color(0xFF53688F),
    brass: Color(0xFF876100),
    brassInk: GcArcade.midnight,
    brassSoft: Color(0x4DFFD34D),
    verdigris: Color(0xFF086064),
    verdigrisSoft: Color(0x26086064),
    danger: Color(0xFFBB393B),
    dangerSoft: Color(0x26BB393B),
    boardLight: Color(0xFFE4EAF8),
    boardDark: Color(0xFF6581BA),
    boardFrame: Color(0xFF223B73),
    boardCoord: Color(0xFFD2DEF7),
    lastMove: Color(0xA6FFD34D),
    selected: Color(0xD9FFD34D),
    legalDot: Color(0x73101B46),
    premove: Color(0x9959E1DD),
    checkGlow: Color(0xE6EF625C),
    pieceWhite: Color(0xFFFFF9E6),
    pieceWhiteInk: Color(0xFF485984),
    pieceBlack: Color(0xFF233B70),
    pieceBlackInk: Color(0xFF091737),
    shadow: Color(0x26223B73),
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
  static const display = 'Bungee';
  static const body = 'Manrope';
  static const mono = 'IBMPlexMono';
}

class GcType {
  GcType._();

  static TextStyle display(Color color, {double size = 40}) => TextStyle(
    fontFamily: GcFonts.display,
    fontSize: size,
    height: 1.15,
    letterSpacing: -0.01 * size,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle displayItalic(Color color, {double size = 40}) =>
      display(color, size: size);

  static TextStyle title(Color color, {double size = 22}) => TextStyle(
    fontFamily: GcFonts.body,
    fontSize: size,
    height: 1.15,
    letterSpacing: -0.01 * size,
    fontWeight: FontWeight.w800,
    fontVariations: const [FontVariation('wght', 800)],
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
