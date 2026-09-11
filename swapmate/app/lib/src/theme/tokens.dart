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
    canvas: Color(0xFF101E29),
    surface: Color(0xFF1B303D),
    surfaceRaised: Color(0xFF27424F),
    surfaceSunken: Color(0xFF122630),
    outline: Color(0xFF385260),
    outlineStrong: Color(0xFF607A83),
    text: Color(0xFFFFF5DF),
    textMuted: Color(0xFFBCCCD0),
    textFaint: Color(0xFF91A8AF),
    accent: Color(0xFFDFFF80),
    onAccent: Color(0xFF182C29),
    accentSoft: Color(0x28DFFF80),
    teamOne: Color(0xFF64DDC8),
    teamOneSoft: Color(0x2864DDC8),
    teamTwo: Color(0xFFFF8B71),
    teamTwoSoft: Color(0x28FF8B71),
    success: Color(0xFF9BE5A0),
    warning: Color(0xFFFFD17A),
    danger: Color(0xFFFF5D5D),
    dangerSoft: Color(0x33FF5D5D),
    boardLight: Color(0xFFE8EDD7),
    boardDark: Color(0xFF78A8A1),
    boardFrame: Color(0xFF203F45),
    boardCoord: Color(0xB3FFFFFF),
    highlightMove: Color(0x90DFFF80),
    highlightSelect: Color(0xCCDFFF80),
    highlightPremove: Color(0x804FB3FF),
    highlightCheck: Color(0xB3FF3B3B),
    highlightTarget: Color(0x66101010),
    pieceWhite: Color(0xFFFFF6DD),
    pieceWhiteOutline: Color(0xFF263E45),
    pieceBlack: Color(0xFF203844),
    pieceBlackOutline: Color(0xFFD7F0DB),
    shadow: Color(0x99000000),
  );

  static const light = SwapColors(
    brightness: Brightness.light,
    canvas: Color(0xFFF3EEDA),
    surface: Color(0xFFFFFAEB),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFE9E8D5),
    outline: Color(0xFFCFD5C4),
    outlineStrong: Color(0xFF8A9F91),
    text: Color(0xFF173D3C),
    textMuted: Color(0xFF4B6763),
    textFaint: Color(0xFF60776D),
    accent: Color(0xFF22594C),
    onAccent: Color(0xFFF2FFC7),
    accentSoft: Color(0x2522594C),
    teamOne: Color(0xFF087F73),
    teamOneSoft: Color(0x25087F73),
    teamTwo: Color(0xFFB8442C),
    teamTwoSoft: Color(0x25B8442C),
    success: Color(0xFF1F9D5A),
    warning: Color(0xFFC98A0B),
    danger: Color(0xFFD53838),
    dangerSoft: Color(0x2ED53838),
    boardLight: Color(0xFFFFF4D7),
    boardDark: Color(0xFF8FB8A3),
    boardFrame: Color(0xFF325C52),
    boardCoord: Color(0xCCFFFFFF),
    highlightMove: Color(0x80E5A21B),
    highlightSelect: Color(0x99F2E23D),
    highlightPremove: Color(0x801D7FD1),
    highlightCheck: Color(0xB3FF3B3B),
    highlightTarget: Color(0x55101010),
    pieceWhite: Color(0xFFFFF6DD),
    pieceWhiteOutline: Color(0xFF263E45),
    pieceBlack: Color(0xFF203844),
    pieceBlackOutline: Color(0xFFD7F0DB),
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
