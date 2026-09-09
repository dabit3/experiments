import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Voxelhearth design tokens: a warm "hearth" palette on deep slate, with
/// Fraunces for display type and Outfit for UI text.
class VhColors {
  static const ember = Color(0xffff8a3d);
  static const emberDeep = Color(0xffd9541e);
  static const gold = Color(0xffffc857);
  static const moss = Color(0xff7bb661);
  static const sky = Color(0xff6cc3ff);
  static const danger = Color(0xffe0524b);

  // dark
  static const slate950 = Color(0xff0b0f17);
  static const slate900 = Color(0xff121826);
  static const slate800 = Color(0xff1b2334);
  static const slate700 = Color(0xff283245);
  static const slate500 = Color(0xff56627a);
  static const slate300 = Color(0xffaab4c8);
  static const slate100 = Color(0xffeef1f7);

  // light
  static const parchment = Color(0xfff7f1e6);
  static const parchment2 = Color(0xffefe6d6);
  static const bark = Color(0xff3b2f26);
}

class VhSpace {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0, xxxl = 48.0;
}

class VhRadius {
  static const sm = 8.0, md = 12.0, lg = 18.0, xl = 28.0;
}

class VhMotion {
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 420);
  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubicEmphasized;
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: VhColors.ember,
    onPrimary: const Color(0xff1a0c04),
    primaryContainer: dark ? const Color(0xff4a2410) : const Color(0xffffe1cc),
    onPrimaryContainer: dark ? const Color(0xffffd9c2) : const Color(0xff4a2410),
    secondary: VhColors.gold,
    onSecondary: const Color(0xff2a1e00),
    secondaryContainer: dark ? const Color(0xff3d2f0a) : const Color(0xfffff0c2),
    onSecondaryContainer: dark ? const Color(0xffffe9a8) : const Color(0xff3d2f0a),
    tertiary: VhColors.moss,
    onTertiary: const Color(0xff0e1f08),
    tertiaryContainer: dark ? const Color(0xff233d1a) : const Color(0xffdcf2cf),
    onTertiaryContainer: dark ? const Color(0xffcdeebd) : const Color(0xff233d1a),
    error: VhColors.danger,
    onError: Colors.white,
    errorContainer: dark ? const Color(0xff4a1a17) : const Color(0xffffdad6),
    onErrorContainer: dark ? const Color(0xffffb4ad) : const Color(0xff4a1a17),
    surface: dark ? VhColors.slate900 : VhColors.parchment,
    onSurface: dark ? VhColors.slate100 : VhColors.bark,
    onSurfaceVariant: dark ? VhColors.slate300 : const Color(0xff6b5d52),
    surfaceContainerLowest: dark ? VhColors.slate950 : Colors.white,
    surfaceContainerLow: dark ? const Color(0xff161d2b) : const Color(0xfffaf6ee),
    surfaceContainer: dark ? VhColors.slate800 : VhColors.parchment2,
    surfaceContainerHigh: dark ? const Color(0xff222c3e) : const Color(0xffe6dccb),
    surfaceContainerHighest: dark ? VhColors.slate700 : const Color(0xffddd1bd),
    outline: dark ? VhColors.slate500 : const Color(0xff9a8c7c),
    outlineVariant: dark ? const Color(0xff33405a) : const Color(0xffd6c9b5),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: dark ? VhColors.slate100 : VhColors.slate900,
    onInverseSurface: dark ? VhColors.slate900 : VhColors.slate100,
    inversePrimary: VhColors.emberDeep,
  );

  final display = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Fraunces',
      fontSize: 56,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.5,
      height: 1.0,
      color: scheme.onSurface,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Fraunces',
      fontSize: 44,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      height: 1.05,
      color: scheme.onSurface,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Fraunces',
      fontSize: 34,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.1,
      color: scheme.onSurface,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Fraunces',
      fontSize: 30,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      color: scheme.onSurface,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Fraunces',
      fontSize: 26,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: scheme.onSurface,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Fraunces',
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: scheme.onSurface,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: scheme.onSurface,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: scheme.onSurface,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: scheme.onSurface,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: scheme.onSurface,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: scheme.onSurfaceVariant,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: scheme.onSurface,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      color: scheme.onSurfaceVariant,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: scheme.onSurfaceVariant,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: display,
    fontFamily: 'Outfit',
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VhRadius.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        textStyle: display.labelLarge?.copyWith(fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VhRadius.md)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: display.labelLarge?.copyWith(fontSize: 15),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VhRadius.md)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        textStyle: display.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VhRadius.md)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VhRadius.md),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VhRadius.md),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VhRadius.md),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      labelStyle: display.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      hintStyle: display.bodyMedium?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      thumbColor: scheme.primary,
      inactiveTrackColor: scheme.surfaceContainerHighest,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : scheme.outline,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHighest,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.outline,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
        textStyle: display.labelLarge,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VhRadius.md)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: display.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VhRadius.md)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(VhRadius.sm)),
      textStyle: display.bodySmall?.copyWith(color: scheme.onInverseSurface),
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

/// Platform badge colours used in rosters and results.
Color platformColor(String platform) => switch (platform) {
  'web' => VhColors.sky,
  'ios' => const Color(0xffb28cff),
  'android' => VhColors.moss,
  'macos' => VhColors.gold,
  'bot' => VhColors.slate300,
  _ => VhColors.slate500,
};

IconData platformIcon(String platform) => switch (platform) {
  'web' => Icons.language_rounded,
  'ios' => Icons.phone_iphone_rounded,
  'android' => Icons.android_rounded,
  'macos' => Icons.laptop_mac_rounded,
  'bot' => Icons.smart_toy_rounded,
  _ => Icons.devices_other_rounded,
};

String platformLabel(String platform) => switch (platform) {
  'web' => 'Web',
  'ios' => 'iOS',
  'android' => 'Android',
  'macos' => 'macOS',
  'bot' => 'Bot',
  _ => platform,
};
