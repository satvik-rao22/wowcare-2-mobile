import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';

/// Maps the tokens onto [ThemeData].
///
/// This exists so that stray Material widgets and the text cursor land in the
/// right colours. It is not where screens get their look: they compose
/// `AppSurfaces` and read `context.colours`, and almost nothing in the app is
/// a stock Material widget.
///
/// Light only. The D1 midnight-navy colourway is fully designed but
/// deliberately not applied, so there is no dark [ThemeData] here — when D1
/// lands it is one more [Colourway] const and one more factory below.
abstract final class AppTheme {
  /// L4 "warm tray, cool cards".
  static ThemeData get light => _from(Colourway.l4);

  static ThemeData _from(Colourway c) {
    final textTheme = _textTheme(c);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: c.page,
      canvasColor: c.page,
      dividerColor: c.divider,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[c],
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: c.pink,
        onPrimary: c.onPink,
        primaryContainer: c.pinkBg,
        onPrimaryContainer: c.onPinkTint,
        secondary: c.ink,
        onSecondary: c.onImpact,
        secondaryContainer: c.altWell,
        onSecondaryContainer: c.ink2,
        tertiary: c.student,
        onTertiary: c.onImpact,
        tertiaryContainer: c.studentBg,
        onTertiaryContainer: c.student,
        error: c.danger,
        onError: c.onImpact,
        errorContainer: c.dangerBg,
        onErrorContainer: c.dangerFg,
        surface: c.card,
        onSurface: c.ink,
        surfaceContainerLowest: c.card,
        surfaceContainerLow: c.sub,
        surfaceContainer: c.altWell,
        surfaceContainerHigh: c.well,
        surfaceContainerHighest: c.deepWell,
        onSurfaceVariant: c.ink2,
        outline: c.cardBorder,
        outlineVariant: c.divider,
        shadow: c.ambient,
        scrim: c.scrim,
        inverseSurface: c.impact,
        onInverseSurface: c.onImpact,
      ),

      // The press in this design is a sink, not a splash. Material's ripple
      // would fight it, so it is off everywhere rather than suppressed one
      // widget at a time.
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,

      appBarTheme: AppBarTheme(
        backgroundColor: c.bar,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.moduleTitle.copyWith(color: c.ink),
      ),

      // The pink cursor and selection are the one place Material's own
      // text-field chrome shows through the redesign's well-backed fields.
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.pink,
        selectionColor: c.pinkBg,
        selectionHandleColor: c.pink,
      ),

      // The design draws its own toasts. This only catches a stray call.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.impact,
        contentTextStyle: AppTextStyles.body.copyWith(color: c.onImpact),
        behavior: SnackBarBehavior.floating,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.pink,
        linearTrackColor: c.track,
        circularTrackColor: c.track,
      ),

      iconTheme: IconThemeData(color: c.ink),
    );
  }

  /// The type ladder, coloured with its default ink.
  ///
  /// Roles are mapped onto the nearest Material slot so that a stock widget
  /// picks up something sensible. Screens name the style they want from
  /// [AppTextStyles] instead of reaching through [TextTheme].
  static TextTheme _textTheme(Colourway c) {
    TextStyle ink(TextStyle s) => s.copyWith(color: c.ink);
    TextStyle ink3(TextStyle s) => s.copyWith(color: c.ink3);

    return TextTheme(
      displayLarge: ink(AppTextStyles.headlineCount),
      headlineLarge: ink(AppTextStyles.moduleTitle),
      headlineMedium: ink(AppTextStyles.detailTitle),
      titleLarge: ink(AppTextStyles.moduleTitle),
      titleMedium: ink(AppTextStyles.cardTitle),
      titleSmall: ink(AppTextStyles.rowName),
      bodyLarge: ink(AppTextStyles.fieldText),
      bodyMedium: ink(AppTextStyles.body),
      bodySmall: ink3(AppTextStyles.subLine),
      labelLarge: ink(AppTextStyles.keyLabel),
      labelMedium: ink3(AppTextStyles.rowSub),
      labelSmall: ink3(AppTextStyles.navLabel),
    );
  }
}
