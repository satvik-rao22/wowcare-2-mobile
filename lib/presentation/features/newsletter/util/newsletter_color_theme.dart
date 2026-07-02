import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

/// Visual palette for a newsletter [colorTheme] value from the API.
class NewsletterThemeColors {
  const NewsletterThemeColors({
    required this.heading,
    required this.body,
    required this.accent,
    required this.divider,
    required this.titleGradientStart,
    required this.titleGradientEnd,
    this.titleTextColor = Colors.white,
  });

  final Color heading;
  final Color body;
  final Color accent;
  final Color divider;
  final Color titleGradientStart;
  final Color titleGradientEnd;
  final Color titleTextColor;

  LinearGradient get titleBarGradient => LinearGradient(
        colors: <Color>[titleGradientStart, titleGradientEnd],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static NewsletterThemeColors fromKey(String themeKey) {
    switch (themeKey.trim().toLowerCase()) {
      case 'vibrant':
        return const NewsletterThemeColors(
          heading: Color(0xFFE65100),
          body: Color(0xFFBF360C),
          accent: Color(0xFFFF9800),
          divider: Color(0xFFFFCC80),
          titleGradientStart: Color(0xFFC05D38),
          titleGradientEnd: Color(0xFFE89264),
        );
      case 'ocean':
        return const NewsletterThemeColors(
          heading: Color(0xFF0277BD),
          body: Color(0xFF01579B),
          accent: Color(0xFF29B6F6),
          divider: Color(0xFF81D4FA),
          titleGradientStart: Color(0xFF1565C0),
          titleGradientEnd: Color(0xFF64B5F6),
        );
      case 'forest':
        return const NewsletterThemeColors(
          heading: Color(0xFF2E7D32),
          body: Color(0xFF1B5E20),
          accent: Color(0xFF66BB6A),
          divider: Color(0xFFA5D6A7),
          titleGradientStart: Color(0xFF2E7D32),
          titleGradientEnd: Color(0xFF81C784),
        );
      case 'sunset':
        return const NewsletterThemeColors(
          heading: Color(0xFFC62828),
          body: Color(0xFF880E4F),
          accent: Color(0xFFEF5350),
          divider: Color(0xFFEF9A9A),
          titleGradientStart: Color(0xFFC62828),
          titleGradientEnd: Color(0xFFFF8A65),
        );
      case 'professional':
        return const NewsletterThemeColors(
          heading: Color(0xFF263238),
          body: Color(0xFF37474F),
          accent: Color(0xFF546E7A),
          divider: Color(0xFFCFD8DC),
          titleGradientStart: Color(0xFF37474F),
          titleGradientEnd: Color(0xFF78909C),
        );
      default:
        return NewsletterThemeColors(
          heading: AppColors.themeColor,
          body: AppColors.primaryColor.withValues(alpha: 0.88),
          accent: AppColors.themeColor.withValues(alpha: 0.75),
          divider: AppColors.themeColor.withValues(alpha: 0.22),
          titleGradientStart: AppColors.themeColor,
          titleGradientEnd: AppColors.themeColor.withValues(alpha: 0.65),
        );
    }
  }
}
