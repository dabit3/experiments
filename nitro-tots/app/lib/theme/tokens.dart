import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Nitro Tots design tokens: "toy box" palette, 4pt spacing, chunky radii.
abstract final class NtColors {
  static const nitro = Color(0xFFFF6B35); // primary
  static const nitroDeep = Color(0xFFD94E1F);
  static const bubblegum = Color(0xFFFF5DA2);
  static const sky = Color(0xFF3DB7FF);
  static const skyDeep = Color(0xFF1C86D6);
  static const lime = Color(0xFF8BE04A);
  static const sunny = Color(0xFFFFD23F);
  static const grape = Color(0xFF9B6DFF);
  static const mint = Color(0xFF4FE3C1);

  static const inkDark = Color(0xFF241E3A);
  static const ink = Color(0xFF3B3355);
  static const inkSoft = Color(0xFF6E6689);
  static const cream = Color(0xFFFFF8F0);
  static const creamDeep = Color(0xFFF6EADB);
  static const night = Color(0xFF16122A);
  static const nightRaised = Color(0xFF221C3D);
  static const nightRaised2 = Color(0xFF2E2650);

  static const gold = Color(0xFFFFC53D);
  static const silver = Color(0xFFC9D1E0);
  static const bronze = Color(0xFFD9925B);

  /// Per-character accent colors (also used for kart bodies).
  static const characterColors = <String, Color>{
    'pip': Color(0xFFFF6B35),
    'bea': Color(0xFFFF5DA2),
    'juno': Color(0xFF3DB7FF),
    'ozzie': Color(0xFF8BE04A),
    'mabel': Color(0xFF9B6DFF),
    'kiki': Color(0xFFFFD23F),
    'rocco': Color(0xFF4FE3C1),
    'tank': Color(0xFF7B8AA0),
  };

  static Color forCharacter(String id) => characterColors[id] ?? nitro;

  static const platformColors = <String, Color>{'web': sky, 'ios': grape, 'android': lime, 'macos': bubblegum, 'bot': inkSoft};
  static Color platform(String id) => platformColors[id] ?? inkSoft;
}

abstract final class NtSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;
}

abstract final class NtRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;
}

abstract final class NtMotion {
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 240);
  static const normal = base;
  static const slow = Duration(milliseconds: 420);
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const bounce = Curves.easeOutBack;
}

abstract final class NtElevation {
  static List<BoxShadow> soft(Color base) => [
    BoxShadow(color: base.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 8)),
    BoxShadow(color: base.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> chunky(Color base) => [BoxShadow(color: base.withValues(alpha: 0.18), blurRadius: 0, offset: const Offset(0, 5))];

  static List<BoxShadow> glow(Color c) => [BoxShadow(color: c.withValues(alpha: 0.45), blurRadius: 24, spreadRadius: 2)];
}

/// Type scale (Fredoka display / Nunito body).
abstract final class NtType {
  static const displayFont = 'Fredoka';
  static const bodyFont = 'Nunito';

  static TextStyle hero(Color c) => TextStyle(fontFamily: displayFont, fontSize: 56, height: 1.0, fontWeight: FontWeight.w700, color: c, letterSpacing: -1);
  static TextStyle h1(Color c) => TextStyle(fontFamily: displayFont, fontSize: 36, height: 1.05, fontWeight: FontWeight.w700, color: c, letterSpacing: -0.5);
  static TextStyle h2(Color c) => TextStyle(fontFamily: displayFont, fontSize: 26, height: 1.1, fontWeight: FontWeight.w600, color: c);
  static TextStyle h3(Color c) => TextStyle(fontFamily: displayFont, fontSize: 20, height: 1.15, fontWeight: FontWeight.w600, color: c);
  static TextStyle label(Color c) => TextStyle(fontFamily: displayFont, fontSize: 15, height: 1.2, fontWeight: FontWeight.w600, color: c, letterSpacing: 0.4);
  static TextStyle body(Color c) => TextStyle(fontFamily: NtType.bodyFont, fontSize: 15, height: 1.45, fontWeight: FontWeight.w600, color: c);
  static TextStyle small(Color c) => TextStyle(fontFamily: NtType.bodyFont, fontSize: 13, height: 1.4, fontWeight: FontWeight.w700, color: c);
  static TextStyle caption(Color c) =>
      TextStyle(fontFamily: NtType.bodyFont, fontSize: 11.5, height: 1.3, fontWeight: FontWeight.w800, color: c, letterSpacing: 0.8);
  static TextStyle mono(Color c, {double size = 15}) => TextStyle(
    fontFamily: NtType.bodyFont,
    fontSize: size,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: c,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static TextStyle hud(Color c, {double size = 28}) => TextStyle(
    fontFamily: displayFont,
    fontSize: size,
    height: 1,
    fontWeight: FontWeight.w700,
    color: c,
    shadows: const [Shadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
  );
}

/// Semantic colors that differ between the light and dark themes.
class NtScheme extends ThemeExtension<NtScheme> {
  const NtScheme({
    required this.bg,
    required this.bgAlt,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.outline,
    required this.accent,
    required this.accentInk,
    required this.success,
    required this.danger,
    required this.shadow,
    required this.isDark,
  });

  final Color bg;
  final Color bgAlt;
  final Color surface;
  final Color surfaceRaised;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color outline;
  final Color accent;
  final Color accentInk;
  final Color success;
  final Color danger;
  final Color shadow;
  final bool isDark;

  static const light = NtScheme(
    bg: NtColors.cream,
    bgAlt: NtColors.creamDeep,
    surface: Colors.white,
    surfaceRaised: Colors.white,
    ink: NtColors.inkDark,
    inkSoft: NtColors.inkSoft,
    inkFaint: Color(0xFFA39CB8),
    outline: Color(0xFFE9DFD2),
    accent: NtColors.nitro,
    accentInk: Colors.white,
    success: Color(0xFF3AAE5C),
    danger: Color(0xFFE5484D),
    shadow: NtColors.inkDark,
    isDark: false,
  );

  static const dark = NtScheme(
    bg: NtColors.night,
    bgAlt: Color(0xFF1D1834),
    surface: NtColors.nightRaised,
    surfaceRaised: NtColors.nightRaised2,
    ink: Color(0xFFF7F2FF),
    inkSoft: Color(0xFFB8B0D2),
    inkFaint: Color(0xFF7D759A),
    outline: Color(0xFF3B335C),
    accent: NtColors.nitro,
    accentInk: Colors.white,
    success: Color(0xFF63D68A),
    danger: Color(0xFFFF6B70),
    shadow: Colors.black,
    isDark: true,
  );

  @override
  NtScheme copyWith() => this;

  @override
  NtScheme lerp(NtScheme? other, double t) {
    if (other == null) return this;
    return NtScheme(
      bg: Color.lerp(bg, other.bg, t)!,
      bgAlt: Color.lerp(bgAlt, other.bgAlt, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension NtThemeX on BuildContext {
  NtScheme get nt => Theme.of(this).extension<NtScheme>() ?? NtScheme.light;
}

ThemeData buildTheme(Brightness brightness) {
  final s = brightness == Brightness.dark ? NtScheme.dark : NtScheme.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: NtColors.nitro,
    onPrimary: Colors.white,
    secondary: NtColors.sky,
    onSecondary: Colors.white,
    tertiary: NtColors.bubblegum,
    onTertiary: Colors.white,
    error: s.danger,
    onError: Colors.white,
    surface: s.surface,
    onSurface: s.ink,
    outline: s.outline,
    surfaceContainerHighest: s.bgAlt,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: s.bg,
    fontFamily: NtType.bodyFont,
    splashFactory: InkSparkle.splashFactory,
    extensions: [s],
    textTheme: TextTheme(
      displayLarge: NtType.hero(s.ink),
      headlineLarge: NtType.h1(s.ink),
      headlineMedium: NtType.h2(s.ink),
      headlineSmall: NtType.h3(s.ink),
      titleMedium: NtType.h3(s.ink),
      labelLarge: NtType.label(s.ink),
      bodyMedium: NtType.body(s.ink),
      bodySmall: NtType.small(s.inkSoft),
      labelSmall: NtType.caption(s.inkSoft),
    ),
    dividerColor: s.outline,
    sliderTheme: SliderThemeData(
      activeTrackColor: NtColors.nitro,
      inactiveTrackColor: s.outline,
      thumbColor: Colors.white,
      overlayColor: NtColors.nitro.withValues(alpha: 0.15),
      trackHeight: 8,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Colors.white : s.inkFaint),
      trackColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? NtColors.nitro : s.bgAlt),
      trackOutlineColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? NtColors.nitro : s.outline),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: s.ink,
      contentTextStyle: NtType.body(s.isDark ? NtColors.night : Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NtRadius.md)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: s.ink, borderRadius: BorderRadius.circular(NtRadius.sm)),
      textStyle: NtType.small(s.isDark ? NtColors.night : Colors.white),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
