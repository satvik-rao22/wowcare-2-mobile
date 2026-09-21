import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';

/// Typography names used across the Attendance V2 module.
///
/// The scale is not the module's own any more — every style is an alias for
/// an `av2*` entry in [AppTextStyles], where the rest of the app's type
/// lives. The names are kept because ~90 call sites read them.
class Av2Text {
  const Av2Text._();

  static const TextStyle hero = AppTextStyles.av2Hero;
  static const TextStyle title = AppTextStyles.av2Title;
  static const TextStyle metricValue = AppTextStyles.av2MetricValue;
  static const TextStyle body = AppTextStyles.av2Body;
  static const TextStyle bodyMedium = AppTextStyles.av2BodyMedium;
  static const TextStyle label = AppTextStyles.av2Label;
  static const TextStyle caption = AppTextStyles.av2Caption;
  static const TextStyle chip = AppTextStyles.av2Chip;
}
