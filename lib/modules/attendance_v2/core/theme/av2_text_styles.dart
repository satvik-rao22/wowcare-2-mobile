import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'av2_colors.dart';

/// Typography tokens for Attendance V2.
///
/// Uses the host app's Manrope family. Sizes are tuned for comfortable
/// readability (no tiny text), and every style defaults to the brand plum
/// (#573353) — never pure black — for a warm childcare feel.
class Av2Text {
  const Av2Text._();

  /// The app's body family, from the one place families are named.
  static const String _family = AppFonts.body;

  static const TextStyle hero = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: Av2Colors.theme,
    letterSpacing: -0.5,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Av2Colors.textPrimary,
  );

  static const TextStyle metricValue = TextStyle(
    fontFamily: _family,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: Av2Colors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Av2Colors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Av2Colors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Av2Colors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: Av2Colors.textSecondary,
  );

  static const TextStyle chip = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
}
