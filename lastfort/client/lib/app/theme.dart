import 'package:flutter/material.dart' hide Material;
import 'package:lastfort_core/lastfort_core.dart';

/// Lastfort design tokens. Everything visual derives from these so the four
/// clients render identically and both themes stay coherent.
class LfTokens {
  const LfTokens._();

  // Spacing scale (4pt grid).
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;

  // Radii.
  static const double rSm = 6;
  static const double rMd = 12;
  static const double rLg = 20;

  // Motion.
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve ease = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;

  // Brand palette (original Lastfort identity: storm-teal + ember-orange).
  static const Color ember = Color(0xFFFF7A2F);
  static const Color emberDeep = Color(0xFFC94F12);
  static const Color teal = Color(0xFF56F5CB);
  static const Color tealDeep = Color(0xFF087D70);
  static const Color storm = Color(0xFF7B5CFF);
  static const Color stormDeep = Color(0xFF3E2A99);
  static const Color health = Color(0xFF52D273);
  static const Color shield = Color(0xFF4DA3FF);
  static const Color danger = Color(0xFFFF4D5E);
  static const Color warning = Color(0xFFDFFF62);

  static const Color wood = Color(0xFFB07A3C);
  static const Color stone = Color(0xFF9AA3AD);
  static const Color metal = Color(0xFF7FD6E8);

  // Dark surfaces.
  static const Color dBg = Color(0xFF09162E);
  static const Color dSurface = Color(0xFF112648);
  static const Color dSurface2 = Color(0xFF1B365C);
  static const Color dLine = Color(0xFF365578);
  static const Color dText = Color(0xFFEEF3FA);
  static const Color dMuted = Color(0xFF93A0B8);

  // Light surfaces.
  static const Color lBg = Color(0xFFF2F5FA);
  static const Color lSurface = Color(0xFFFFFFFF);
  static const Color lSurface2 = Color(0xFFE6ECF5);
  static const Color lLine = Color(0xFFCBD5E4);
  static const Color lText = Color(0xFF0E1728);
  static const Color lMuted = Color(0xFF5B6880);

  static Color rarity(Rarity r) => Color(r.argb);

  static Color material(Material m) => switch (m) {
    Material.wood => wood,
    Material.stone => stone,
    Material.metal => metal,
  };

  static Color team(int team) {
    const palette = [
      Color(0xFF2FD3C6),
      Color(0xFFFF7A2F),
      Color(0xFF7B5CFF),
      Color(0xFFFFC857),
      Color(0xFFFF4D8D),
      Color(0xFF52D273),
      Color(0xFF4DA3FF),
      Color(0xFFE0E6F0),
      Color(0xFFB86BFF),
      Color(0xFF9AD64A),
      Color(0xFFFF9F9F),
      Color(0xFF6CE6FF),
      Color(0xFFD7A15A),
      Color(0xFF8FA5C8),
      Color(0xFFF2F26A),
      Color(0xFFC96A6A),
    ];
    return palette[team % palette.length];
  }
}

/// Theme extension exposing semantic surfaces to widgets.
class LfColors extends ThemeExtension<LfColors> {
  const LfColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.text,
    required this.muted,
    required this.glass,
    required this.glassStrong,
    required this.isDark,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color text;
  final Color muted;
  final Color glass;
  final Color glassStrong;
  final bool isDark;

  Color readable(Color color) {
    final hsl = HSLColor.fromColor(color);
    return isDark
        ? color
        : hsl.withLightness(hsl.lightness.clamp(0, 0.34)).toColor();
  }

  static const dark = LfColors(
    bg: LfTokens.dBg,
    surface: LfTokens.dSurface,
    surface2: LfTokens.dSurface2,
    line: LfTokens.dLine,
    text: LfTokens.dText,
    muted: LfTokens.dMuted,
    glass: Color(0xB30B1220),
    glassStrong: Color(0xE60B1220),
    isDark: true,
  );

  static const light = LfColors(
    bg: LfTokens.lBg,
    surface: LfTokens.lSurface,
    surface2: LfTokens.lSurface2,
    line: LfTokens.lLine,
    text: LfTokens.lText,
    muted: LfTokens.lMuted,
    glass: Color(0xCCFFFFFF),
    glassStrong: Color(0xF2FFFFFF),
    isDark: false,
  );

  @override
  LfColors copyWith() => this;

  @override
  LfColors lerp(LfColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension LfContext on BuildContext {
  LfColors get lf => Theme.of(this).extension<LfColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final c = dark ? LfColors.dark : LfColors.light;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Rajdhani',
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: LfTokens.teal,
      onPrimary: const Color(0xFF032523),
      secondary: LfTokens.ember,
      onSecondary: const Color(0xFF2B1102),
      error: LfTokens.danger,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.text,
    ),
    scaffoldBackgroundColor: c.bg,
  );
  TextStyle t(double size, FontWeight w, {double? ls, double h = 1.1}) =>
      TextStyle(
        fontFamily: 'Rajdhani',
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        height: h,
        color: c.text,
      );
  return base.copyWith(
    extensions: [c],
    textTheme: TextTheme(
      displayLarge: t(64, FontWeight.w700, ls: -1, h: 1),
      displayMedium: t(44, FontWeight.w700, ls: -0.5, h: 1),
      displaySmall: t(36, FontWeight.w700, ls: -0.5, h: 1),
      headlineLarge: t(32, FontWeight.w700, h: 1.05),
      headlineMedium: t(26, FontWeight.w700, h: 1.05),
      headlineSmall: t(22, FontWeight.w700, h: 1.1),
      titleLarge: t(21, FontWeight.w600),
      titleMedium: t(17, FontWeight.w600),
      titleSmall: t(15, FontWeight.w600, ls: 0.4),
      bodyLarge: t(17, FontWeight.w500, h: 1.3),
      bodyMedium: t(15, FontWeight.w500, h: 1.3),
      bodySmall: t(13, FontWeight.w500, h: 1.25),
      labelLarge: t(15, FontWeight.w700, ls: 1.2),
      labelMedium: t(13, FontWeight.w700, ls: 1.1),
      labelSmall: t(11, FontWeight.w700, ls: 1.2),
    ),
    dividerColor: c.line,
    splashFactory: InkSparkle.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface2,
      hintStyle: TextStyle(color: c.muted),
      labelStyle: TextStyle(color: c.muted, letterSpacing: 1),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LfTokens.s4,
        vertical: LfTokens.s3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LfTokens.rMd),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LfTokens.rMd),
        borderSide: BorderSide(color: c.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LfTokens.rMd),
        borderSide: const BorderSide(color: LfTokens.teal, width: 2),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(LfTokens.rSm),
        border: Border.all(color: c.line),
      ),
      textStyle: TextStyle(color: c.text, fontFamily: 'Rajdhani'),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}

/// Layout breakpoints shared by every screen.
enum LfLayout {
  phone,
  tablet,
  desktop;

  static LfLayout of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 640) return phone;
    if (w < 1100) return tablet;
    return desktop;
  }

  bool get isPhone => this == phone;
  bool get isDesktop => this == desktop;
}
