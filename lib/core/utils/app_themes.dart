/// The [ThemeData] handed to `MaterialApp`, built from the tokens in
/// `lib/core/theme/app_theme_config.dart`.
///
/// ## Why this file stopped using `ColorScheme.fromSeed`
///
/// A seeded scheme derives all 30-odd Material roles algorithmically from
/// one colour. With pink as the seed that made every Material-owned surface
/// a pink-tinted neutral — the date picker's ground, a dropdown's menu, an
/// `AlertDialog`, anything Material 3 elevates and therefore tints with
/// `surfaceTint`. None of it went through [AppPalette], so re-skinning the
/// app could not reach it.
///
/// Every role below is now read from [AppPalette] instead, and `surfaceTint`
/// is transparent so elevation darkens with a shadow rather than staining a
/// surface with the brand colour. Material's own widgets are now skinned by
/// the same file as everything else.
///
/// ## Adding a skin (dark mode, a festival palette)
///
/// Nothing in this file changes. Add the skin to [AppSkin], give every role
/// in [AppPalette] a value under it, and flip `AppThemeConfig.skin`. The
/// scheme, the component themes and the text theme below all re-derive from
/// those roles.
///
/// The switch is compile-time on purpose: the app declares thousands of
/// `const` text styles and decorations, and a `const` cannot read from an
/// `InheritedWidget`. See the header of `app_theme_config.dart`.
library;

import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_elevation.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// Material's colour roles, mapped onto ours.
///
/// The `surfaceContainer*` ramp is the L4 surface set in order, which is what
/// lets a Material widget that picks its own container tone still land on a
/// tone this design language recognises.
ColorScheme _scheme(Brightness brightness) => ColorScheme(
  brightness: brightness,

  primary: AppPalette.brand,
  onPrimary: AppPalette.onBrand,
  primaryContainer: AppPalette.brandSoft,
  onPrimaryContainer: AppPalette.brandDark,

  secondary: AppPalette.actionSecondary,
  onSecondary: AppPalette.textOnDark,
  secondaryContainer: AppPalette.statusInfoSoft,
  onSecondaryContainer: AppPalette.statusInfo,

  tertiary: AppPalette.statusWarning,
  onTertiary: AppPalette.textOnDark,
  tertiaryContainer: AppPalette.statusWarningSoft,
  onTertiaryContainer: AppPalette.statusWarning,

  error: AppPalette.statusError,
  onError: AppPalette.textOnDark,
  errorContainer: AppPalette.statusErrorSoft,
  onErrorContainer: AppPalette.statusErrorStrong,

  surface: AppPalette.surfaceCard,
  onSurface: AppPalette.textPrimary,
  surfaceDim: AppPalette.surfaceField,
  surfaceBright: AppPalette.surfaceCard,
  surfaceContainerLowest: AppPalette.surfaceCard,
  surfaceContainerLow: AppPalette.surfacePage,
  surfaceContainer: AppPalette.surfaceSunken,
  surfaceContainerHigh: AppPalette.surfaceMuted,
  surfaceContainerHighest: AppPalette.surfaceField,
  onSurfaceVariant: AppPalette.textSecondary,

  inverseSurface: AppPalette.surfaceInverse,
  onInverseSurface: AppPalette.textOnDark,
  inversePrimary: AppPalette.brandLight,

  outline: AppPalette.borderStrong,
  outlineVariant: AppPalette.border,
  shadow: AppPalette.shadowAmbient,
  scrim: AppPalette.scrim,

  // Elevation must not stain a surface with the brand colour: depth in this
  // design language comes from the bevel, the rim and the ambient shadow.
  surfaceTint: AppColors.transparentColor,
);

/// The type scale, in the ink the given brightness calls for. [heading] and
/// [body] are separate because the dark theme has always used a softer white
/// for running text than for headings.
TextTheme _textTheme(Color heading, Color body) => TextTheme(
  displayLarge: TextStyle(
    fontSize: AppTypeScale.s32,
    fontWeight: AppTypeScale.bold,
    color: heading,
  ),
  headlineMedium: TextStyle(
    fontSize: AppTypeScale.size2xl,
    fontWeight: AppTypeScale.bold,
    color: heading,
  ),
  titleLarge: TextStyle(
    fontSize: AppTypeScale.sizeLg,
    fontWeight: AppTypeScale.semiBold,
    color: heading,
  ),
  bodyLarge: TextStyle(
    fontSize: AppTypeScale.sizeMd,
    fontWeight: AppTypeScale.regular,
    color: body,
  ),
  bodyMedium: TextStyle(
    fontSize: AppTypeScale.sizeBase,
    fontWeight: AppTypeScale.regular,
    color: body,
  ),
);

/// A `WidgetStateProperty` that is [selected] when the control is on and
/// [rest] otherwise — the shape every Material toggle wants.
WidgetStateProperty<Color> _whenSelected(Color selected, Color rest) =>
    WidgetStateProperty.resolveWith(
      (Set<WidgetState> states) =>
          states.contains(WidgetState.selected) ? selected : rest,
    );

/// The same, as a [Color], for the handful of theme slots that take a
/// `WidgetStateColor` rather than a property (the time picker's dial).
WidgetStateColor _colorWhenSelected(Color selected, Color rest) =>
    WidgetStateColor.resolveWith(
      (Set<WidgetState> states) =>
          states.contains(WidgetState.selected) ? selected : rest,
    );

/// The field default, taken from the same builder call sites use.
InputDecorationTheme _fieldTheme() {
  final InputDecoration d = AppSurfaces.fieldDecoration();
  return InputDecorationTheme(
    filled: d.filled,
    fillColor: d.fillColor,
    border: d.border,
    enabledBorder: d.enabledBorder,
    focusedBorder: d.focusedBorder,
    errorBorder: d.errorBorder,
    focusedErrorBorder: d.focusedErrorBorder,
    hintStyle: TextStyle(
      fontFamily: AppFonts.body,
      color: AppPalette.textMuted,
    ),
  );
}

/// The component themes shared by both brightnesses.
///
/// Each one exists for the same reason: the widget is Material's, the app
/// uses it directly in at least a dozen places, and left alone it would take
/// its colour from Material's defaults rather than from [AppPalette].
ThemeData _build(Brightness brightness) {
  final ColorScheme scheme = _scheme(brightness);
  final bool isDark = brightness == Brightness.dark;
  final Color ink = isDark ? AppPalette.textOnDark : AppPalette.textPrimary;
  final Color inkMuted = isDark ? MaterialHues.white70 : AppPalette.textPrimary;

  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    primaryColor: AppColors.themeColor,
    colorScheme: scheme,
    fontFamily: AppFonts.body,
    textTheme: _textTheme(ink, inkMuted),
    scaffoldBackgroundColor: AppPalette.surfacePage,
    canvasColor: AppPalette.surfaceCard,
    dividerColor: AppPalette.divider,
    shadowColor: AppPalette.shadowAmbient,
    splashColor: AppPalette.brandSoft,
    highlightColor: AppPalette.brandSoft,

    iconTheme: IconThemeData(color: AppPalette.iconDefault),
    primaryIconTheme: IconThemeData(color: AppPalette.iconOnBrand),

    // ── Anything Material raises off the page ─────────────────────────────
    //
    // `surfaceTintColor` is set to transparent on each of these as well as on
    // the scheme: several of them read the widget-level property first.
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.surfacePage,
      foregroundColor: ink,
      surfaceTintColor: AppColors.transparentColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppPalette.iconDefault),
    ),

    cardTheme: CardThemeData(
      color: AppPalette.surfaceCard,
      surfaceTintColor: AppColors.transparentColor,
      shadowColor: AppPalette.shadowAmbient,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXl),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.surfaceCard,
      surfaceTintColor: AppColors.transparentColor,
      shadowColor: AppPalette.shadowAmbient,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXl),
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: AppTypeScale.sizeLg,
        fontWeight: AppTypeScale.semiBold,
        color: ink,
      ),
      contentTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: AppTypeScale.sizeBase,
        color: inkMuted,
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppPalette.surfaceSunken,
      modalBackgroundColor: AppPalette.surfaceSunken,
      surfaceTintColor: AppColors.transparentColor,
      elevation: 0,
      modalElevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r28),
        ),
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: AppPalette.surfaceCard,
      surfaceTintColor: AppColors.transparentColor,
      shadowColor: AppPalette.shadowAmbient,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      textStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: AppTypeScale.sizeBase,
        color: ink,
      ),
    ),

    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(AppPalette.surfaceCard),
        surfaceTintColor: WidgetStatePropertyAll<Color>(
          AppColors.transparentColor,
        ),
        shadowColor: WidgetStatePropertyAll<Color>(AppPalette.shadowAmbient),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        ),
      ),
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(AppPalette.surfaceCard),
        surfaceTintColor: WidgetStatePropertyAll<Color>(
          AppColors.transparentColor,
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        ),
      ),
    ),

    // ── Date and time ─────────────────────────────────────────────────────
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppPalette.surfaceCard,
      surfaceTintColor: AppColors.transparentColor,
      headerBackgroundColor: AppPalette.surfaceCard,
      headerForegroundColor: ink,
      dayForegroundColor: _whenSelected(AppPalette.onBrand, ink),
      dayBackgroundColor: _whenSelected(
        AppPalette.brand,
        AppColors.transparentColor,
      ),
      todayForegroundColor: _whenSelected(AppPalette.onBrand, AppPalette.brand),
      todayBorder: BorderSide(color: AppPalette.brand),
      yearForegroundColor: _whenSelected(AppPalette.onBrand, ink),
      yearBackgroundColor: _whenSelected(
        AppPalette.brand,
        AppColors.transparentColor,
      ),
      rangeSelectionBackgroundColor: AppPalette.brandSoft,
      rangePickerBackgroundColor: AppPalette.surfaceCard,
      rangePickerHeaderBackgroundColor: AppPalette.surfaceCard,
      rangePickerHeaderForegroundColor: ink,
      dividerColor: AppPalette.divider,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXl),
    ),

    timePickerTheme: TimePickerThemeData(
      backgroundColor: AppPalette.surfaceCard,
      dialBackgroundColor: AppPalette.surfaceField,
      dialHandColor: AppPalette.brand,
      dialTextColor: _colorWhenSelected(AppPalette.onBrand, ink),
      hourMinuteColor: _colorWhenSelected(
        AppPalette.brandSoft,
        AppPalette.surfaceField,
      ),
      hourMinuteTextColor: _colorWhenSelected(AppPalette.brand, ink),
      entryModeIconColor: AppPalette.iconDefault,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXl),
    ),

    // ── Fields ────────────────────────────────────────────────────────────
    //
    // The default for anything typed into that does not build its own
    // decoration. A field is cut *into* the surface: cool fill, no outline
    // at rest, a brand ring on focus. It does not get the well's inset
    // shadow — InputDecoration cannot paint one, and wrapping the field
    // would put its error and counter text inside the well.
    inputDecorationTheme: _fieldTheme(),

    // ── Small parts ───────────────────────────────────────────────────────
    dividerTheme: DividerThemeData(color: AppPalette.divider),

    listTileTheme: ListTileThemeData(
      iconColor: AppPalette.iconDefault,
      textColor: ink,
      selectedColor: AppPalette.brand,
      selectedTileColor: AppPalette.surfaceSelected,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppPalette.surfaceSunken,
      selectedColor: AppPalette.surfaceSelected,
      disabledColor: AppPalette.surfaceField,
      surfaceTintColor: AppColors.transparentColor,
      side: BorderSide(color: AppPalette.borderHairline),
      labelStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: AppTypeScale.sizeSm,
        color: ink,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppPalette.surfaceInverse,
      contentTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: AppTypeScale.sizeBase,
        color: AppPalette.textOnDark,
      ),
      actionTextColor: AppPalette.brandLight,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppPalette.surfaceInverse,
        borderRadius: AppRadius.allMd,
        boxShadow: AppElevation.toast,
      ),
      textStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: AppTypeScale.sizeSm,
        color: AppPalette.textOnDark,
      ),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppPalette.brand,
      linearTrackColor: AppPalette.surfaceField,
      circularTrackColor: AppColors.transparentColor,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: _whenSelected(AppPalette.onBrand, AppPalette.surfaceCard),
      trackColor: _whenSelected(
        AppPalette.statusSuccess,
        AppPalette.surfaceField,
      ),
      trackOutlineColor: WidgetStatePropertyAll<Color>(AppPalette.border),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: _whenSelected(AppPalette.brand, AppColors.transparentColor),
      checkColor: WidgetStatePropertyAll<Color>(AppPalette.onBrand),
      side: BorderSide(color: AppPalette.borderStrong, width: 1.5),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXs),
    ),

    radioTheme: RadioThemeData(
      fillColor: _whenSelected(AppPalette.brand, AppPalette.borderStrong),
    ),

    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppPalette.brand,
      selectionColor: AppPalette.surfaceSelected,
      selectionHandleColor: AppPalette.brand,
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: ink,
      unselectedLabelColor: AppPalette.textMuted,
      indicatorColor: AppPalette.brand,
      dividerColor: AppColors.transparentColor,
    ),
  );
}

/// The app's light theme.
final ThemeData lightTheme = _build(Brightness.light);

// ═══════════════════════════════════════════════════════════════════════════
// DARK THEME: PLANNED, DO NOT DELETE
// ═══════════════════════════════════════════════════════════════════════════
//
// Wired end to end but not switched on: it renders the light palette, because
// AppPalette holds one skin's worth of values today. A real dark mode is a
// dark set of values for those 75 roles, and nothing in this file changes
// when they land.
//
// Keep it. `AppTheme.dark` and `ThemeCubit` are the seam it plugs into, so
// removing either one makes dark mode a rewrite instead of a palette.

/// The app's dark theme. Light colours for now, see the header above.
final ThemeData darkTheme = _build(Brightness.dark);

/// The themes handed to `MaterialApp`, and the only place that picks one.
///
/// Both read every colour from [AppPalette], so adding a skin means giving
/// those roles new values, not editing this class or any screen.
///
/// Not on `AppThemeConfig`: that file is the leaf token file the whole app
/// imports, and pointing it at the builders here would make the import cycle.
class AppTheme {
  AppTheme._();

  static ThemeData get light => lightTheme;

  /// Light colours today. See the DARK THEME header above.
  static ThemeData get dark => darkTheme;
}
