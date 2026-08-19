import 'package:flutter/material.dart';

import 'skeu_tokens.dart';

/// The Material [ThemeData] the skeuomorphic language sits on.
///
/// The skeu widgets paint their own surfaces, so this theme's job is narrow:
/// put Poppins and the brand ink behind everything Material still draws for us
/// (dialogs, snackbars, pickers, text selection, the cursor), and keep the
/// scaffold transparent enough that [SkeuBackground] shows through.
class SkeuTheme {
  const SkeuTheme._();

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: SkeuColors.teal600,
      onPrimary: SkeuColors.white,
      primaryContainer: SkeuColors.teal100,
      onPrimaryContainer: SkeuColors.teal900,
      secondary: SkeuColors.pink600,
      onSecondary: SkeuColors.white,
      secondaryContainer: SkeuColors.pink100,
      onSecondaryContainer: SkeuColors.pink800,
      tertiary: SkeuColors.sun400,
      onTertiary: SkeuColors.sun800,
      error: SkeuColors.danger500,
      onError: SkeuColors.white,
      errorContainer: SkeuColors.danger50,
      onErrorContainer: SkeuColors.danger600,
      surface: SkeuColors.white,
      onSurface: SkeuColors.ink,
      onSurfaceVariant: SkeuColors.inkSoft,
      outline: SkeuColors.inkFaint,
      outlineVariant: SkeuColors.cream200,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: SkeuText.family,
      scaffoldBackgroundColor: SkeuColors.cream100,
      primaryColor: SkeuColors.teal600,
      canvasColor: SkeuColors.cream100,
      dividerColor: SkeuColors.borderHairline,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      dividerTheme: const DividerThemeData(
        color: SkeuColors.borderHairline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: SkeuColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: SkeuText.family,
          fontSize: 18,
          fontWeight: SkeuText.weightBold,
          color: SkeuColors.ink,
        ),
      ),
      // Sheets and dialogs are raised panels too: same radii, same soft face.
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SkeuColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SkeuRadius.xxxl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SkeuColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SkeuRadius.xxl),
        ),
        titleTextStyle: SkeuText.title(),
        contentTextStyle: SkeuText.prose(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SkeuColors.navy,
        contentTextStyle: SkeuText.body(color: SkeuColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SkeuRadius.lg),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: SkeuColors.teal600,
        selectionColor: SkeuColors.pink200.withValues(alpha: .6),
        selectionHandleColor: SkeuColors.teal600,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SkeuColors.teal600,
        linearTrackColor: SkeuColors.cream200,
        circularTrackColor: SkeuColors.cream200,
      ),
      iconTheme: const IconThemeData(color: SkeuColors.ink, size: 22),
      // Material Cards are raised panels too: a navy-tinted shadow, the panel
      // radius, and no surface tint. They cannot carry the lit top bevel a
      // SkeuPanel paints, so they read one step flatter — use SkeuPanel for
      // anything that should look like a real object.
      cardTheme: CardThemeData(
        color: SkeuColors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: SkeuColors.navy.withValues(alpha: .5),
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SkeuRadius.xl),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: SkeuColors.ink,
        iconColor: SkeuColors.teal600,
        tileColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SkeuColors.cream100,
        labelStyle: SkeuText.body(weight: SkeuText.weightHeading),
        side: const BorderSide(color: SkeuColors.borderHairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SkeuRadius.pill),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: SkeuColors.teal700,
        unselectedLabelColor: SkeuColors.inkFaint,
        indicatorColor: SkeuColors.teal600,
        labelStyle: SkeuText.body(weight: SkeuText.weightHeading),
        unselectedLabelStyle: SkeuText.body(),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) => base
      .apply(
        fontFamily: SkeuText.family,
        bodyColor: SkeuColors.ink,
        displayColor: SkeuColors.ink,
      )
      .copyWith(
        displayLarge: SkeuText.display().copyWith(fontSize: 32),
        headlineMedium: SkeuText.stat(),
        titleLarge: SkeuText.title(),
        titleMedium: SkeuText.field(weight: SkeuText.weightHeading),
        bodyLarge: SkeuText.field(),
        bodyMedium: SkeuText.body(),
        bodySmall: SkeuText.caption(color: SkeuColors.inkSoft),
        labelLarge: SkeuText.body(weight: SkeuText.weightHeading),
        labelSmall: SkeuText.eyebrow(),
      );
}
