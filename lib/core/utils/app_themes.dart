/// The [ThemeData] handed to `MaterialApp`, built from the tokens in
/// `lib/core/theme/app_theme_config.dart`.
///
/// Only colours and typography are set here. Component themes (app bar,
/// buttons, inputs, sheets) are deliberately left to Flutter's defaults so
/// that centralising the theme does not restyle any widget — the shape of
/// these two objects is unchanged from before centralisation, only the values
/// now come from the token file.
library;

import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// The app's light theme.
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.themeColor,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.themeColor),
  useMaterial3: true,
  fontFamily: AppFonts.body,
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: AppTypeScale.s32,
      fontWeight: AppTypeScale.bold,
      color: AppPalette.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: AppTypeScale.size2xl,
      fontWeight: AppTypeScale.bold,
      color: AppPalette.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: AppTypeScale.sizeLg,
      fontWeight: AppTypeScale.semiBold,
      color: AppPalette.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: AppTypeScale.sizeMd,
      fontWeight: AppTypeScale.regular,
      color: AppPalette.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: AppTypeScale.sizeBase,
      fontWeight: AppTypeScale.regular,
      color: AppPalette.textPrimary,
    ),
  ),
);

/// The app's dark theme. Reachable only through `ThemeCubit.toggleTheme`.
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.themeColor,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.themeColor,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  fontFamily: AppFonts.body,
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: AppTypeScale.s32,
      fontWeight: AppTypeScale.bold,
      color: AppPalette.textOnDark,
    ),
    headlineMedium: TextStyle(
      fontSize: AppTypeScale.size2xl,
      fontWeight: AppTypeScale.bold,
      color: AppPalette.textOnDark,
    ),
    titleLarge: TextStyle(
      fontSize: AppTypeScale.sizeLg,
      fontWeight: AppTypeScale.semiBold,
      color: AppPalette.textOnDark,
    ),
    bodyLarge: TextStyle(
      fontSize: AppTypeScale.sizeMd,
      fontWeight: AppTypeScale.regular,
      color: MaterialHues.white70,
    ),
    bodyMedium: TextStyle(
      fontSize: AppTypeScale.sizeBase,
      fontWeight: AppTypeScale.regular,
      color: MaterialHues.white70,
    ),
  ),
);
