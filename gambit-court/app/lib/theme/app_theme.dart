import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tokens.dart';

extension GcThemeX on BuildContext {
  GcColors get gc => Theme.of(this).extension<GcColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

ThemeData buildGcTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? GcColors.dark : GcColors.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.brass,
    onPrimary: c.brassInk,
    secondary: c.verdigris,
    onSecondary: c.bg,
    error: c.danger,
    onError: c.bg,
    surface: c.surface,
    onSurface: c.text,
    surfaceContainerHighest: c.surfaceRaised,
    outline: c.border,
    outlineVariant: c.borderStrong,
    shadow: c.shadow,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    fontFamily: GcFonts.body,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
  );
  return base.copyWith(
    extensions: [c],
    textTheme: base.textTheme.apply(
      bodyColor: c.text,
      displayColor: c.text,
      fontFamily: GcFonts.body,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.brass,
      selectionColor: c.brassSoft,
      selectionHandleColor: c.brass,
    ),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: c.text, borderRadius: GcRadius.smAll),
      textStyle: GcType.body(c.bg, size: 12),
      waitDuration: const Duration(milliseconds: 500),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.surfaceRaised,
      contentTextStyle: GcType.body(c.text),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: GcRadius.mdAll,
        side: BorderSide(color: c.borderStrong),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceSunken,
      hintStyle: GcType.body(c.textFaint),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: GcSpace.lg,
        vertical: GcSpace.md,
      ),
      border: OutlineInputBorder(
        borderRadius: GcRadius.mdAll,
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: GcRadius.mdAll,
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: GcRadius.mdAll,
        borderSide: BorderSide(color: c.brass, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: GcRadius.mdAll,
        borderSide: BorderSide(color: c.danger),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: GcRadius.lgAll,
        side: BorderSide(color: c.borderStrong),
      ),
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
