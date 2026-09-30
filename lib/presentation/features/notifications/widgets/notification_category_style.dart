import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

import '../../../../domain/features/notifications/entities/notification_category.dart';

/// Presentation-only mapping of a [NotificationCategory] to its chip / avatar
/// colours. Lives in the presentation layer (not the domain enum) so the domain
/// stays free of any Flutter dependency.
class NotificationCategoryStyle {
  const NotificationCategoryStyle({
    required this.foreground,
    required this.background,
  });

  final Color foreground;
  final Color background;

  static NotificationCategoryStyle of(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.availability:
        return const NotificationCategoryStyle(
          foreground: AppPalette.statusSuccessStrong,
          background: AppPalette.statusSuccessSoft,
        );
      case NotificationCategory.staff:
        return const NotificationCategoryStyle(
          foreground: AppPalette.brandDark,
          background: AppPalette.brandSoft,
        );
      case NotificationCategory.student:
        return const NotificationCategoryStyle(
          foreground: MaterialHues.indigo,
          background: AppPalette.surfaceMuted,
        );
    }
  }

  /// Colours for a raw backend `module` string (e.g. `ATTENDANCE`, `CLASSROOM`,
  /// `USER`). The notification chip shows the actual module, which is a wider
  /// set than [NotificationCategory], so this maps each known module to a tint
  /// and falls back to a neutral grey for anything unrecognised.
  static NotificationCategoryStyle forModule(String module) {
    switch (module.trim().toUpperCase()) {
      case 'ATTENDANCE':
      case 'STAFF_ATTENDANCE':
      case 'STUDENT_ATTENDANCE':
        return const NotificationCategoryStyle(
          foreground: AppPalette.domainStudentInk,
          background: AppPalette.domainStudentSoft,
        );
      case 'STAFF':
        return const NotificationCategoryStyle(
          foreground: AppPalette.brandDark,
          background: AppPalette.brandSoft,
        );
      case 'STUDENT':
        return const NotificationCategoryStyle(
          foreground: MaterialHues.indigo,
          background: AppPalette.surfaceMuted,
        );
      case 'CLASSROOM':
      case 'CLASSROOM_SCHEDULE':
        return const NotificationCategoryStyle(
          foreground: AppPalette.statusWarningStrong,
          background: MaterialHues.orange50,
        );
      case 'USER':
        return const NotificationCategoryStyle(
          foreground: MaterialHues.blueGrey700,
          background: AppPalette.surfaceMuted,
        );
      case 'BILLING':
      case 'ACCOUNTS':
      case 'INVOICES':
      case 'TRANSACTION':
        return const NotificationCategoryStyle(
          foreground: AppPalette.statusSuccessStrong,
          background: AppPalette.statusSuccessSoft,
        );
      case 'ACTIVITY':
      case 'ACTIVITIES':
      case 'DAILY_ACTIVITY':
        return const NotificationCategoryStyle(
          foreground: AppPalette.dataPurple,
          background: AppPalette.dataPurpleSoft,
        );
      case 'SCHEDULING':
      case 'STAFF_SCHEDULING':
        return const NotificationCategoryStyle(
          foreground: AppPalette.statusInfo,
          background: MaterialHues.blue50,
        );
      case 'AVAILABILITY':
      case 'FUTURE_AVAILABILITY':
      case 'MOVEMENT_RULES':
      case 'INDIVISUAL_MOVEMENTS':
        return const NotificationCategoryStyle(
          foreground: AppPalette.statusSuccessStrong,
          background: AppPalette.statusSuccessSoft,
        );
      case 'NEWSLETTER':
      case 'MESSAGING':
      case 'PARENT_MESSAGING':
      case 'STAFF_MESSAGING':
        return const NotificationCategoryStyle(
          foreground: AppPalette.domainStudentInk,
          background: AppPalette.statusInfoSoft,
        );
      default:
        return const NotificationCategoryStyle(
          foreground: AppColors.primaryColor,
          background: AppPalette.surfaceMuted,
        );
    }
  }

  /// Title-cases a raw module string for display, e.g. `STAFF_ATTENDANCE` →
  /// `Staff Attendance`, `ATTENDANCE` → `Attendance`.
  static String moduleLabel(String module) {
    final cleaned = module.trim();
    if (cleaned.isEmpty) return '';
    return cleaned
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}
