import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.themeColor,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.themeColor),
  useMaterial3: true,
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.themeColor,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.themeColor,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
);


