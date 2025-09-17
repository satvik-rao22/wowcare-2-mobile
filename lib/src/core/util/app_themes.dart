import 'package:flutter/material.dart';

import '../res/colors.dart';
import '../res/fonts.dart';

final TextTheme _textTheme = const TextTheme(
  bodyLarge: TextStyle(letterSpacing: 0),
  bodyMedium: TextStyle(letterSpacing: 0),
  bodySmall: TextStyle(letterSpacing: 0),
  displayLarge: TextStyle(letterSpacing: 0),
  displayMedium: TextStyle(letterSpacing: 0),
  displaySmall: TextStyle(letterSpacing: 0),
  headlineLarge: TextStyle(letterSpacing: 0),
  headlineMedium: TextStyle(letterSpacing: 0),
  headlineSmall: TextStyle(letterSpacing: 0),
  labelLarge: TextStyle(letterSpacing: 0),
  labelMedium: TextStyle(letterSpacing: 0),
  labelSmall: TextStyle(letterSpacing: 0),
  titleLarge: TextStyle(letterSpacing: 0),
  titleMedium: TextStyle(letterSpacing: 0),
  titleSmall: TextStyle(letterSpacing: 0),
);

final lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSwatch(accentColor: AppColors.themeColor),
  fontFamily: Fonts.manrope,
  shadowColor: AppColors.primaryColor,
  textTheme: _textTheme,
  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Colors.blueAccent,
    secondary: Colors.blue,
  ),
  fontFamily: Fonts.manrope,
  shadowColor: AppColors.cardColor,
  textTheme: _textTheme,
  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
);
