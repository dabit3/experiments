import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? SwapColors.dark : SwapColors.light;
  const family = 'Inter';

  TextStyle t(
    double size,
    FontWeight w, {
    double? height,
    double? spacing,
    Color? color,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: w,
    height: height,
    letterSpacing: spacing,
    color: color ?? c.text,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  final text = TextTheme(
    displayLarge: t(
      76,
      FontWeight.w800,
      height: 0.95,
      spacing: -1,
    ).copyWith(fontFamily: 'BarlowCondensed'),
    displayMedium: t(
      48,
      FontWeight.w800,
      height: 1,
      spacing: 0.2,
    ).copyWith(fontFamily: 'BarlowCondensed'),
    headlineLarge: t(
      36,
      FontWeight.w800,
      height: 1.05,
    ).copyWith(fontFamily: 'BarlowCondensed'),
    headlineMedium: t(
      28,
      FontWeight.w800,
      height: 1.1,
      spacing: 0.4,
    ).copyWith(fontFamily: 'BarlowCondensed'),
    headlineSmall: t(
      22,
      FontWeight.w800,
      height: 1.15,
      spacing: 0.3,
    ).copyWith(fontFamily: 'BarlowCondensed'),
    titleLarge: t(16, FontWeight.w600, height: 1.3),
    titleMedium: t(14, FontWeight.w600, height: 1.35),
    titleSmall: t(12, FontWeight.w600, height: 1.35, spacing: 0.2),
    bodyLarge: t(16, FontWeight.w400, height: 1.45),
    bodyMedium: t(14, FontWeight.w400, height: 1.45),
    bodySmall: t(12, FontWeight.w400, height: 1.4, color: c.textMuted),
    labelLarge: t(14, FontWeight.w600, height: 1.2, spacing: 0.1),
    labelMedium: t(12, FontWeight.w600, height: 1.2, spacing: 0.4),
    labelSmall: t(
      11,
      FontWeight.w600,
      height: 1.2,
      spacing: 0.6,
      color: c.textMuted,
    ),
  );

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.teamOne,
    onSecondary: Colors.white,
    error: c.danger,
    onError: Colors.white,
    surface: c.surface,
    onSurface: c.text,
    outline: c.outline,
    surfaceContainerHighest: c.surfaceRaised,
    onSurfaceVariant: c.textMuted,
  );

  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.md),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: family,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.canvas,
    canvasColor: c.canvas,
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    // Same hit-target geometry on every platform so layouts are identical.
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: [c],
    dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: c.textMuted, size: 20),
    appBarTheme: AppBarTheme(
      backgroundColor: c.canvas,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.headlineSmall,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: c.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        disabledBackgroundColor: c.surfaceRaised,
        disabledForegroundColor: c.textFaint,
        textStyle: text.labelLarge,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        shape: shape,
        elevation: 4,
        shadowColor: c.shadow,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        side: BorderSide(color: c.outlineStrong),
        textStyle: text.labelLarge,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.textMuted,
        textStyle: text.labelLarge,
        minimumSize: const Size(40, 40),
        padding: const EdgeInsets.symmetric(horizontal: Space.md),
        shape: shape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.textMuted,
        minimumSize: const Size(40, 40),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceSunken,
      hintStyle: text.bodyLarge?.copyWith(color: c.textFaint),
      labelStyle: text.labelMedium?.copyWith(color: c.textMuted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: c.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: c.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: c.outline),
      ),
      textStyle: text.bodySmall?.copyWith(color: c.text),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.surfaceRaised,
      contentTextStyle: text.bodyMedium,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: c.outline),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      titleTextStyle: text.headlineSmall,
      contentTextStyle: text.bodyMedium,
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
