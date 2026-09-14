import 'package:flutter/widgets.dart';

/// Centralised component dimensions (logical pixels): icon sizes, stroke
/// widths, minimum touch targets and illustration sizes.
///
/// Values mirror the sizes already used across the app so adoption is
/// pixel-identical. Complements [AppSpacing] (gaps/padding) and [AppRadius]
/// (corner radii).
class AppDimensions {
  AppDimensions._();

  /// WCAG 2.1 / platform minimum interactive target. Interactive controls
  /// should not be smaller than this in either dimension.
  static const double minTouchTarget = 48;

  // ── Icon sizes ─────────────────────────────────────────────────────────────
  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;

  // ── Stroke / border widths ──────────────────────────────────────────────────
  static const double hairline = 1;
  static const double borderThin = 1.5;
  static const double borderThick = 2;

  // ── Empty-state / illustration sizes ────────────────────────────────────────
  static const double illustrationSm = 80;
  static const double illustrationMd = 200;

  // ── Common circular avatar diameters ────────────────────────────────────────
  static const double avatarSm = 30;
  static const double avatarMd = 36;
  static const double avatarLg = 48;

  /// A square [SizedBox] sized to [minTouchTarget] — handy to pad an
  /// otherwise-small tappable icon up to an accessible hit area.
  static const SizedBox minTouchTargetBox = SizedBox(
    width: minTouchTarget,
    height: minTouchTarget,
  );
}
