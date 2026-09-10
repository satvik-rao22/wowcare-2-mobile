import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// Visual palette for a newsletter's `colorTheme`, chosen by whoever wrote it.
///
/// The five schemes are author data, not app chrome, so they are allowed to
/// be their own colours — but they are still built from [AppPalette]'s
/// categorical `data*` roles rather than from hexes, so a new skin moves them
/// with everything else. Each scheme is one hue used at three depths: a
/// heading, a body, and the tint its divider and title bar sit on.
///
/// The title bar is a flat fill. It was a two-stop wash, which rule 3 of the
/// design language forbids.
class NewsletterThemeColors {
  const NewsletterThemeColors({
    required this.heading,
    required this.body,
    required this.accent,
    required this.divider,
    required this.titleBarColor,
    this.titleTextColor = AppColors.textOnDarkColor,
  });

  /// One hue at three depths: [strong] for headings and the title bar,
  /// [mid] for the accent, [soft] for the divider.
  const NewsletterThemeColors._hue({
    required Color strong,
    required Color mid,
    required Color soft,
  }) : heading = strong,
       body = strong,
       accent = mid,
       divider = soft,
       titleBarColor = strong,
       titleTextColor = AppColors.textOnDarkColor;

  final Color heading;
  final Color body;
  final Color accent;
  final Color divider;

  /// The flat fill behind the newsletter's title.
  final Color titleBarColor;

  final Color titleTextColor;

  static NewsletterThemeColors fromKey(String themeKey) =>
      switch (themeKey.trim().toLowerCase()) {
        'vibrant' => const NewsletterThemeColors._hue(
          strong: AppPalette.statusWarningStrong,
          mid: AppPalette.dataOrange,
          soft: AppPalette.dataOrangeSoft,
        ),
        'ocean' => const NewsletterThemeColors._hue(
          strong: AppPalette.domainStudentInk,
          mid: AppPalette.dataTeal,
          soft: AppPalette.dataTealSoft,
        ),
        'forest' => const NewsletterThemeColors._hue(
          strong: AppPalette.statusSuccessStrong,
          mid: AppPalette.dataGreen,
          soft: AppPalette.dataGreenSoft,
        ),
        'sunset' => const NewsletterThemeColors._hue(
          strong: AppPalette.statusErrorStrong,
          mid: AppPalette.dataPink,
          soft: AppPalette.dataPinkSoft,
        ),
        'professional' => const NewsletterThemeColors._hue(
          strong: AppPalette.textPrimary,
          mid: AppPalette.textSecondary,
          soft: AppPalette.surfaceField,
        ),
        _ => const NewsletterThemeColors._hue(
          strong: AppPalette.brand,
          mid: AppPalette.brandLight,
          soft: AppPalette.brandSoft,
        ),
      };
}
