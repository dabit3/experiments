import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the Brickfolk theme. Uses the bundled Inter font so every
/// platform renders identical text metrics (no platform fonts).
ThemeData brickTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final palette = dark ? BrickPalette.dark : BrickPalette.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: BrickColors.sky,
    onPrimary: Colors.white,
    primaryContainer: dark ? BrickColors.skyDark : const Color(0xFFDCE6FF),
    onPrimaryContainer: dark ? Colors.white : BrickColors.skyDark,
    secondary: BrickColors.brick,
    onSecondary: Colors.white,
    secondaryContainer: dark ? BrickColors.ink4 : BrickColors.paper3,
    onSecondaryContainer: palette.textPrimary,
    tertiary: BrickColors.sun,
    onTertiary: BrickColors.ink,
    error: palette.danger,
    onError: Colors.white,
    surface: palette.surface0,
    onSurface: palette.textPrimary,
    surfaceContainerHighest: palette.surface3,
    surfaceContainerHigh: palette.surface2,
    surfaceContainer: palette.surface1,
    surfaceContainerLow: palette.surface1,
    surfaceContainerLowest: palette.surface0,
    onSurfaceVariant: palette.textSecondary,
    outline: palette.outline,
    outlineVariant: palette.outline,
    shadow: palette.shadow,
    inverseSurface: dark ? BrickColors.paper : BrickColors.ink,
    onInverseSurface: dark ? BrickColors.ink : BrickColors.paper,
    inversePrimary: BrickColors.skyDark,
    scrim: Colors.black,
  );

  const family = 'Inter';
  final base = Typography.material2021(platform: TargetPlatform.android).black
      .apply(fontFamily: family);
  final textTheme = base
      .copyWith(
        displayLarge: const TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.w800,
          letterSpacing: -2,
          height: 1.05,
        ),
        displayMedium: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          height: 1.1,
        ),
        displaySmall: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          height: 1.15,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        headlineSmall: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        titleSmall: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        labelMedium: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      )
      .apply(
        fontFamily: family,
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.surface0,
    canvasColor: palette.surface0,
    fontFamily: family,
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    extensions: [palette],
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
    appBarTheme: AppBarTheme(
      backgroundColor: palette.surface0,
      foregroundColor: palette.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall,
    ),
    cardTheme: CardThemeData(
      color: palette.surface1,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: palette.outline),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: palette.outline,
      space: 1,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface2,
      hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textTertiary),
      labelStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: palette.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: BrickColors.sky, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: palette.danger, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        textStyle: textTheme.labelLarge,
        foregroundColor: palette.textPrimary,
        side: BorderSide(color: palette.surface3, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(40, 40),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.textSecondary,
        minimumSize: const Size(40, 40),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surface2,
      selectedColor: scheme.primaryContainer,
      labelStyle: textTheme.labelMedium?.copyWith(color: palette.textPrimary),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? BrickColors.paper : BrickColors.ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: dark ? BrickColors.ink : BrickColors.paper,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface1,
      indicatorColor: scheme.primaryContainer,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : palette.textSecondary,
          size: 22,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.surface1,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
      unselectedIconTheme: IconThemeData(color: palette.textSecondary),
      selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
        color: palette.textPrimary,
      ),
      unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
        color: palette.textSecondary,
      ),
      labelType: NavigationRailLabelType.all,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      titleTextStyle: textTheme.headlineSmall,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: palette.textSecondary,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface1,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: dark ? BrickColors.paper : BrickColors.ink,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      textStyle: textTheme.bodySmall?.copyWith(
        color: dark ? BrickColors.ink : BrickColors.paper,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: palette.textSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? BrickColors.sky
            : palette.surface3,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: BrickColors.sky,
      linearTrackColor: Colors.transparent,
    ),
  );
}
