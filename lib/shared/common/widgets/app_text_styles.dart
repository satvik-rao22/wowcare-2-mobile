import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';

/// Reusable text style widgets following the design patterns from staff_card.dart
class AppTextStyles {
  AppTextStyles._();

  /// Label text style - used for field labels
  /// fontSize: 13, fontWeight: w400, color: primaryColor, height: 16/13
  static const TextStyle label = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryColor,
    height: 16 / 13,
  );

  /// Display text style
  /// fontSize: 24, fontWeight: w700, color: primaryColor
  static const TextStyle display = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryColor,
  );

  /// Screen Title text style
  /// fontSize: 20, fontWeight: w600, color: primaryColor
  static const TextStyle screenTitle = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  /// Heading text style
  /// fontSize: 18, fontWeight: w600, color: primaryColor
  static const TextStyle heading = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  /// Value text style - used for displaying values/content
  /// fontSize: 14, fontWeight: w500, color: primaryColor, height: 19/14
  @Deprecated('Use AppTextStyles.body instead')
  static const TextStyle value = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
    height: 19 / 14,
  );

  /// Title text style - used for section titles
  /// fontSize: 16, fontWeight: w700, color: primaryColor
  static const TextStyle title = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryColor,
    height: 16 / 16,
  );

  /// Subtitle text style - used for subtitles
  /// fontSize: 14, fontWeight: w700, color: primaryColor
  static const TextStyle subtitle = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryColor,
  );

  /// Body large text style
  /// fontSize: 16, fontWeight: w500, color: primaryColor
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
  );

  /// Body text style - used for regular body text
  /// fontSize: 14, fontWeight: w500, color: primaryColor, height: 19/14
  static const TextStyle body = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
    height: 19 / 14,
  );

  /// Body small text style
  /// fontSize: 12, fontWeight: w400, color: primaryColor
  static const TextStyle bodySmall = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryColor,
    height: 15 / 12,
  );

  /// Small text style - used for smaller text (deprecated in favor of bodySmall)
  /// fontSize: 12, fontWeight: w400, color: primaryColor
  static const TextStyle small = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryColor,
    height: 15 / 12,
  );

  /// Caption text style
  /// fontSize: 12, fontWeight: w500, color: primaryColor
  static const TextStyle caption = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
  );

  /// Button text style - used for button labels
  /// fontSize: 16, fontWeight: w700, color: varies
  static TextStyle button({Color? color}) => TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.primaryColor,
    height: 16 / 16,
  );

  /// Section header text style - used for section headers
  /// fontSize: 13, fontWeight: w600, color: primaryColor
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );
  /// Empty state text style
  /// fontSize: 16, fontWeight: w500, color: primaryColor
  static const TextStyle emptyState = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
  );
}

/// Reusable text widgets with predefined styles
class AppText extends StatelessWidget {
  const AppText.label(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.label;

  const AppText.value(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.value;

  const AppText.title(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.title;

  const AppText.subtitle(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.subtitle;

  const AppText.body(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.body;

  const AppText.bodyLarge(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.bodyLarge;

  const AppText.bodySmall(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.bodySmall;

  const AppText.caption(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.caption;

  const AppText.display(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.display;

  const AppText.screenTitle(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.screenTitle;

  const AppText.heading(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.heading;

  const AppText.emptyState(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.emptyState;

  const AppText.small(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.small;

  const AppText.sectionHeader(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.sectionHeader;

  final String text;
  final _TextVariant _variant;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  TextStyle get _baseStyle {
    switch (_variant) {
      case _TextVariant.label:
        return AppTextStyles.label;
      case _TextVariant.value:
        return AppTextStyles.value;
      case _TextVariant.title:
        return AppTextStyles.title;
      case _TextVariant.subtitle:
        return AppTextStyles.subtitle;
      case _TextVariant.body:
        return AppTextStyles.body;
      case _TextVariant.bodyLarge:
        return AppTextStyles.bodyLarge;
      case _TextVariant.bodySmall:
        return AppTextStyles.bodySmall;
      case _TextVariant.caption:
        return AppTextStyles.caption;
      case _TextVariant.display:
        return AppTextStyles.display;
      case _TextVariant.screenTitle:
        return AppTextStyles.screenTitle;
      case _TextVariant.heading:
        return AppTextStyles.heading;
      case _TextVariant.emptyState:
        return AppTextStyles.emptyState;
      case _TextVariant.small:
        return AppTextStyles.small;
      case _TextVariant.sectionHeader:
        return AppTextStyles.sectionHeader;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _baseStyle.merge(style),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

enum _TextVariant { label, value, title, subtitle, body, bodyLarge, bodySmall, caption, display, screenTitle, heading, emptyState, small, sectionHeader }
