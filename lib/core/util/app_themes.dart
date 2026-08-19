import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// The app runs on the ChildcareWow skeuomorphic design system, so the base
/// Material theme comes from [SkeuTheme] — Poppins throughout, navy ink, teal
/// primary, pink reserved for the recommended action.
final ThemeData lightTheme = SkeuTheme.light();

/// Dark mode is not part of the skeuomorphic design: the whole material
/// language depends on a single light source above a light page. Until a dark
/// palette is designed, [ThemeCubit.toggleTheme] swaps to this Material dark
/// theme, which at least keeps the brand typography and colours.
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: SkeuColors.teal500,
  colorScheme: ColorScheme.fromSeed(
    seedColor: SkeuColors.teal500,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  fontFamily: SkeuText.family,
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.white70,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.white70,
    ),
  ),
);
