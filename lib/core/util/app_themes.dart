// import 'package:flutter/material.dart';
// import 'package:wowcare/app/theme/colors.dart';

// final ThemeData lightTheme = ThemeData(
//   brightness: Brightness.light,
//   primaryColor: AppColors.themeColor,
//   colorScheme: ColorScheme.fromSeed(seedColor: AppColors.themeColor),
//   useMaterial3: true,
// );

// final ThemeData darkTheme = ThemeData(
//   brightness: Brightness.dark,
//   primaryColor: AppColors.themeColor,
//   colorScheme: ColorScheme.fromSeed(
//     seedColor: AppColors.themeColor,
//     brightness: Brightness.dark,
//   ),
//   useMaterial3: true,
// );

import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.themeColor,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.themeColor),
  useMaterial3: true,
  fontFamily: Fonts.manrope,
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryColor,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryColor,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryColor,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.primaryColor,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.primaryColor,
    ),
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.themeColor,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.themeColor,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  fontFamily: Fonts.manrope,
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Colors.white70,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Colors.white70,
    ),
  ),
);
