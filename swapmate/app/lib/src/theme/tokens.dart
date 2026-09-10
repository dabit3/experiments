import 'package:flutter/material.dart';
import 'package:swapmate_core/swapmate_core.dart';

/// Swapmate design tokens. Everything visual derives from these so the four
/// platform builds render identically.
class Space {
  Space._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class Radii {
  Radii._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

class Motion {
  Motion._();
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 360);
  static const pass = Duration(milliseconds: 620);
  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubicEmphasized;
}

/// Semantic colour set, one instance per theme brightness.
class SwapColors extends ThemeExtension<SwapColors> {
  const SwapColors({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.outline,
    required this.outlineStrong,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.teamOne,
    required this.teamOneSoft,
    required this.teamTwo,
    required this.teamTwoSoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.dangerSoft,
    required this.boardLight,
    required this.boardDark,
    required this.boardFrame,
    required this.boardCoord,
    required this.highlightMove,
    required this.highlightSelect,
    required this.highlightPremove,
    required this.highlightCheck,
    required this.highlightTarget,
    required this.pieceWhite,
    required this.pieceWhiteOutline,
    required this.pieceBlack,
    required this.pieceBlackOutline,
    required this.shadow,
  });

  final Brightness brightness;
  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color outline;
  final Color outlineStrong;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color teamOne;
  final Color teamOneSoft;
  final Color teamTwo;
  final Color teamTwoSoft;
  final Color success;
  final Color warning;
  final Color danger;
  final Color dangerSoft;
  final Color boardLight;
  final Color boardDark;
  final Color boardFrame;
  final Color boardCoord;
  final Color highlightMove;
  final Color highlightSelect;
  final Color highlightPremove;
  final Color highlightCheck;
  final Color highlightTarget;
  final Color pieceWhite;
  final Color pieceWhiteOutline;
  final Color pieceBlack;
  final Color pieceBlackOutline;
  final Color shadow;

  bool get isDark => brightness == Brightness.dark;

  static const dark = SwapColors(
    brightness: Brightness.dark,
    canvas: Color(0xFF0F1216),
    surface: Color(0xFF171B21),
    surfaceRaised: Color(0xFF1F242C),
    surfaceSunken: Color(0xFF0B0E12),
    outline: Color(0xFF2B323C),
    outlineStrong: Color(0xFF3D4653),
    text: Color(0xFFF2F4F7),
    textMuted: Color(0xFFA5AEBB),
    textFaint: Color(0xFF6B7482),
    accent: Color(0xFFF2B33D),
    onAccent: Color(0xFF1A1305),
    accentSoft: Color(0x33F2B33D),
    teamOne: Color(0xFF4FB3FF),
    teamOneSoft: Color(0x334FB3FF),
    teamTwo: Color(0xFFFF7A59),
    teamTwoSoft: Color(0x33FF7A59),
    success: Color(0xFF3DD68C),
    warning: Color(0xFFF2B33D),
    danger: Color(0xFFFF5D5D),
    dangerSoft: Color(0x33FF5D5D),
    boardLight: Color(0xFFD9C4A3),
    boardDark: Color(0xFF8B6A4A),
    boardFrame: Color(0xFF2A2119),
    boardCoord: Color(0xB3FFFFFF),
    highlightMove: Color(0x80F2B33D),
    highlightSelect: Color(0x99F2E23D),
    highlightPremove: Color(0x804FB3FF),
    highlightCheck: Color(0xB3FF3B3B),
    highlightTarget: Color(0x66101010),
    pieceWhite: Color(0xFFF8F4EC),
    pieceWhiteOutline: Color(0xFF2B2420),
    pieceBlack: Color(0xFF23201E),
    pieceBlackOutline: Color(0xFFE9E1D3),
    shadow: Color(0x99000000),
  );

  static const light = SwapColors(
    brightness: Brightness.light,
    canvas: Color(0xFFF4F1EA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFECE7DD),
    outline: Color(0xFFE1DBCE),
    outlineStrong: Color(0xFFC9C1B1),
    text: Color(0xFF1B1A17),
    textMuted: Color(0xFF615C52),
    textFaint: Color(0xFF9A937F),
    accent: Color(0xFFC98A0B),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x2EC98A0B),
    teamOne: Color(0xFF1D7FD1),
    teamOneSoft: Color(0x2E1D7FD1),
    teamTwo: Color(0xFFDD5A36),
    teamTwoSoft: Color(0x2EDD5A36),
    success: Color(0xFF1F9D5A),
    warning: Color(0xFFC98A0B),
    danger: Color(0xFFD53838),
    dangerSoft: Color(0x2ED53838),
    boardLight: Color(0xFFEBDCC0),
    boardDark: Color(0xFFA8845F),
    boardFrame: Color(0xFF5B4632),
    boardCoord: Color(0xCCFFFFFF),
    highlightMove: Color(0x80E5A21B),
    highlightSelect: Color(0x99F2E23D),
    highlightPremove: Color(0x801D7FD1),
    highlightCheck: Color(0xB3FF3B3B),
    highlightTarget: Color(0x55101010),
    pieceWhite: Color(0xFFFCFAF5),
    pieceWhiteOutline: Color(0xFF2B2420),
    pieceBlack: Color(0xFF2A2624),
    pieceBlackOutline: Color(0xFFF1EBDD),
    shadow: Color(0x40000000),
  );

  Color team(Team team) => team == Team.one ? teamOne : teamTwo;
  Color teamSoft(Team team) => team == Team.one ? teamOneSoft : teamTwoSoft;

  @override
  SwapColors copyWith() => this;

  @override
  SwapColors lerp(SwapColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SwapColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      outline: l(outline, other.outline),
      outlineStrong: l(outlineStrong, other.outlineStrong),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      textFaint: l(textFaint, other.textFaint),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentSoft: l(accentSoft, other.accentSoft),
      teamOne: l(teamOne, other.teamOne),
      teamOneSoft: l(teamOneSoft, other.teamOneSoft),
      teamTwo: l(teamTwo, other.teamTwo),
      teamTwoSoft: l(teamTwoSoft, other.teamTwoSoft),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      boardLight: l(boardLight, other.boardLight),
      boardDark: l(boardDark, other.boardDark),
      boardFrame: l(boardFrame, other.boardFrame),
      boardCoord: l(boardCoord, other.boardCoord),
      highlightMove: l(highlightMove, other.highlightMove),
      highlightSelect: l(highlightSelect, other.highlightSelect),
      highlightPremove: l(highlightPremove, other.highlightPremove),
      highlightCheck: l(highlightCheck, other.highlightCheck),
      highlightTarget: l(highlightTarget, other.highlightTarget),
      pieceWhite: l(pieceWhite, other.pieceWhite),
      pieceWhiteOutline: l(pieceWhiteOutline, other.pieceWhiteOutline),
      pieceBlack: l(pieceBlack, other.pieceBlack),
      pieceBlackOutline: l(pieceBlackOutline, other.pieceBlackOutline),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension SwapColorsX on BuildContext {
  SwapColors get colors => Theme.of(this).extension<SwapColors>()!;
  TextTheme get type => Theme.of(this).textTheme;
}
