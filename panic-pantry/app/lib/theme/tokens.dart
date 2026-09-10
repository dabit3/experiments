import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Panic Pantry design tokens.
///
/// Everything visible derives from these: a warm "pantry" palette, a 4pt
/// spacing grid, a small type scale, three elevation levels and a handful of
/// motion durations. Both themes share the same brand hues so the four
/// clients look identical modulo platform text rendering.
abstract final class PPColor {
  // Brand.
  static const paprika = Color(0xFFE8563F); // primary action / fire
  static const paprikaDark = Color(0xFFB83A27);
  static const butter = Color(0xFFF7C948); // highlights, stars, tips
  static const basil = Color(0xFF3FAF6E); // success / serve
  static const blueberry = Color(0xFF3F7FE8); // info / links
  static const plum = Color(0xFF6E4AB5); // accent

  // Chef colours by slot.
  static const chefs = [Color(0xFFE8563F), Color(0xFF3F7FE8), Color(0xFF3FAF6E), Color(0xFFF7C948)];

  // Neutrals.
  static const ink = Color(0xFF1B1A22);
  static const ink2 = Color(0xFF2A2833);
  static const ink3 = Color(0xFF3A3846);
  static const cream = Color(0xFFFFF8EC);
  static const cream2 = Color(0xFFF6EBD6);
  static const cream3 = Color(0xFFE9DBC1);
  static const mute = Color(0xFF8B8797);

  // Kitchen surfaces (shared by both themes for cross-client parity).
  static const floorA = Color(0xFFF3E4C8);
  static const floorB = Color(0xFFEBD8B6);
  static const counterTop = Color(0xFFD9C3A0);
  static const counterSide = Color(0xFFA98B62);
  static const steel = Color(0xFFB9C4CE);
  static const steelDark = Color(0xFF7E8B96);
  static const water = Color(0xFF3F9FE8);
  static const wood = Color(0xFF8C5A34);
  static const pit = Color(0xFF16222E);
}

abstract final class PPSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
}

abstract final class PPRadius {
  static const sm = Radius.circular(8);
  static const md = Radius.circular(14);
  static const lg = Radius.circular(22);
  static const pill = Radius.circular(999);
  static final BorderRadius card = BorderRadius.circular(18);
  static final BorderRadius button = BorderRadius.circular(14);
  static final BorderRadius chip = BorderRadius.circular(999);
}

abstract final class PPMotion {
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 420);
  static const stagger = Duration(milliseconds: 70);
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const bounce = Curves.easeOutBack;
}

/// Shadows for the three elevation levels.
abstract final class PPElevation {
  static List<BoxShadow> low(Brightness b) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: b == Brightness.dark ? 0.45 : 0.10),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> mid(Brightness b) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: b == Brightness.dark ? 0.55 : 0.14),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> high(Brightness b) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: b == Brightness.dark ? 0.65 : 0.20),
      blurRadius: 36,
      offset: const Offset(0, 18),
    ),
  ];
}

/// Type scale. One display face (rounded, heavy) and one text face.
abstract final class PPType {
  static const family = 'Nunito';
  static const monoFamily = 'JetBrains Mono';
  static const _display = TextStyle(fontFamily: family);
  static TextStyle display(Color c) =>
      _display.copyWith(fontSize: 44, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -1.2, color: c);
  static TextStyle h1(Color c) =>
      _display.copyWith(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.6, color: c);
  static TextStyle h2(Color c) =>
      _display.copyWith(fontSize: 22, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.3, color: c);
  static TextStyle h3(Color c) => _display.copyWith(fontSize: 17, fontWeight: FontWeight.w700, height: 1.2, color: c);
  static TextStyle body(Color c) => _display.copyWith(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4, color: c);
  static TextStyle small(Color c) =>
      _display.copyWith(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3, color: c);
  static TextStyle caption(Color c) =>
      _display.copyWith(fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: 0.6, color: c);
  static TextStyle mono(Color c) =>
      TextStyle(fontFamily: monoFamily, fontSize: 15, fontWeight: FontWeight.w500, color: c);
  static TextStyle numeric(Color c, {double size = 28}) => _display.copyWith(
    fontSize: size,
    fontWeight: FontWeight.w900,
    height: 1,
    color: c,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Semantic colours resolved per brightness.
class PPScheme extends ThemeExtension<PPScheme> {
  const PPScheme({
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.surface2,
    required this.outline,
    required this.text,
    required this.text2,
    required this.text3,
    required this.brightness,
  });

  final Color bg;
  final Color bg2;
  final Color surface;
  final Color surface2;
  final Color outline;
  final Color text;
  final Color text2;
  final Color text3;
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  static const light = PPScheme(
    bg: PPColor.cream,
    bg2: PPColor.cream2,
    surface: Colors.white,
    surface2: PPColor.cream2,
    outline: PPColor.cream3,
    text: PPColor.ink,
    text2: Color(0xFF55515F),
    text3: PPColor.mute,
    brightness: Brightness.light,
  );

  static const dark = PPScheme(
    bg: PPColor.ink,
    bg2: PPColor.ink2,
    surface: PPColor.ink2,
    surface2: PPColor.ink3,
    outline: Color(0xFF4A4858),
    text: PPColor.cream,
    text2: Color(0xFFCFC9BE),
    text3: PPColor.mute,
    brightness: Brightness.dark,
  );

  @override
  PPScheme copyWith() => this;

  @override
  PPScheme lerp(PPScheme? other, double t) => t < 0.5 ? this : (other ?? this);

  static PPScheme of(BuildContext context) => Theme.of(context).extension<PPScheme>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final s = brightness == Brightness.dark ? PPScheme.dark : PPScheme.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: PPColor.paprika,
    brightness: brightness,
    primary: PPColor.paprika,
    secondary: PPColor.butter,
    surface: s.surface,
    onSurface: s.text,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: s.bg,
    extensions: [s],
    splashFactory: InkSparkle.splashFactory,
    // Same control metrics on every platform (the adaptive defaults are
    // compact density / shrink-wrapped tap targets on desktop and web,
    // standard density / 48px padded tap targets on phones).
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    fontFamily: PPType.family,
    textTheme: TextTheme(
      displayLarge: PPType.display(s.text),
      headlineLarge: PPType.h1(s.text),
      headlineMedium: PPType.h2(s.text),
      titleMedium: PPType.h3(s.text),
      bodyMedium: PPType.body(s.text),
      bodySmall: PPType.small(s.text2),
      labelSmall: PPType.caption(s.text3),
    ),
    dividerColor: s.outline,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: s.surface2,
      border: OutlineInputBorder(borderRadius: PPRadius.button, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: PPRadius.button,
        borderSide: const BorderSide(color: PPColor.paprika, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: PPSpace.x4, vertical: PPSpace.x4),
      hintStyle: PPType.body(s.text3),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: s.text, borderRadius: BorderRadius.circular(8)),
      textStyle: PPType.small(s.bg),
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
