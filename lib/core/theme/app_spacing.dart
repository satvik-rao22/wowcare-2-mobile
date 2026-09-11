import 'package:flutter/widgets.dart';

/// Centralised spacing scale (logical pixels) for gaps, padding and margins.
///
/// The values mirror the spacing already used across the app, so replacing a
/// raw literal with the matching token is **pixel-identical** — adopting a
/// token never shifts layout. Prefer the semantic names ([xxs]…[xxxl]); the
/// numeric aliases (`s5`, `s10`, `s19`, …) exist only so off-scale legacy
/// values can be migrated onto a token without any visual drift.
///
/// See also [AppRadius] for corner radii and [AppDimensions] for component
/// sizes. Colors live in `AppColors`, typography in `AppTextStyles`.
class AppSpacing {
  AppSpacing._();

  static const double none = 0;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  /// Off-scale legacy values retained so existing UI migrates faithfully.
  /// New code should reach for the semantic names above instead.
  static const double s2 = 2;
  static const double s5 = 5;
  static const double s6 = 6;
  static const double s10 = 10;
  static const double s14 = 14;
  static const double s18 = 18;
  static const double s19 = 19;

  // ── Ready-made gap widgets (avoid re-allocating const SizedBoxes) ──────────
  static const SizedBox gapHXxs = SizedBox(width: xxs);
  static const SizedBox gapHXs = SizedBox(width: xs);
  static const SizedBox gapHSm = SizedBox(width: sm);
  static const SizedBox gapHMd = SizedBox(width: md);
  static const SizedBox gapHLg = SizedBox(width: lg);

  static const SizedBox gapVXxs = SizedBox(height: xxs);
  static const SizedBox gapVXs = SizedBox(height: xs);
  static const SizedBox gapVSm = SizedBox(height: sm);
  static const SizedBox gapVMd = SizedBox(height: md);
  static const SizedBox gapVLg = SizedBox(height: lg);
}
