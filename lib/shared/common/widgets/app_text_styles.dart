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

  /// Value text style - used for displaying values/content
  /// fontSize: 14, fontWeight: w500, color: primaryColor, height: 19/14
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

  /// Body text style - used for regular body text
  /// fontSize: 14, fontWeight: w500, color: primaryColor, height: 19/14
  static const TextStyle body = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
    height: 19 / 14,
  );

  /// Small text style - used for smaller text
  /// fontSize: 12, fontWeight: w400, color: primaryColor
  static const TextStyle small = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryColor,
    height: 15 / 12,
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

enum _TextVariant { label, value, title, subtitle, body, small, sectionHeader }
