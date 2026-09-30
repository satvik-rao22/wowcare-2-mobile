import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_spacing.dart';

/// Spacing, radius and sizing names used across the Attendance V2 module.
///
/// The scale is not the module's own any more — every value resolves to
/// [AppSpacing] or [AppRadius], so the app has one rhythm and one set of
/// corners. The names are kept because ~160 call sites read them, and
/// because the last few entries (screen padding per breakpoint, content max
/// width, the desktop rail) are genuinely module-specific layout metrics
/// with no app-wide equivalent.
class Av2Spacing {
  const Av2Spacing._();

  // Base spacing scale — AppSpacing.
  static const double xxs = AppSpacing.xxs;
  static const double xs = AppSpacing.xs;
  static const double sm = AppSpacing.sm;
  static const double md = AppSpacing.md;
  static const double lg = AppSpacing.lg;
  static const double xl = AppSpacing.xl;
  static const double xxl = AppSpacing.xxl;

  // Corner radii — AppRadius.
  static const double radiusSm = AppRadius.sm;
  static const double radiusMd = AppRadius.md;
  static const double radiusLg = AppRadius.lg;
  static const double radiusPill = AppRadius.pill;

  // ── Module layout metrics (no app-wide equivalent) ──────────────────────

  /// Screen padding (horizontal) per breakpoint.
  static const double screenPadMobile = AppSpacing.md;
  static const double screenPadTablet = AppSpacing.xl;
  static const double screenPadDesktop = AppSpacing.xxl;

  /// Content max width on large screens so lines never stretch too wide.
  static const double contentMaxWidth = 720;

  /// Desktop master-detail rail width.
  static const double rosterRailWidth = 280;
}
