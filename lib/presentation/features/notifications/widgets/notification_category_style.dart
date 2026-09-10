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
          foreground: Color(0xFF2E7D32),
          background: Color(0xFFE7F5E9),
        );
      case NotificationCategory.staff:
        return const NotificationCategoryStyle(
          foreground: Color(0xFFC2185B),
          background: Color(0xFFFCE7F0),
        );
      case NotificationCategory.student:
        return const NotificationCategoryStyle(
          foreground: MaterialHues.indigo,
          background: Color(0xFFE8EAF6),
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
          foreground: Color(0xFF00796B),
          background: Color(0xFFE0F2F1),
        );
      case 'STAFF':
        return const NotificationCategoryStyle(
          foreground: Color(0xFFC2185B),
          background: Color(0xFFFCE7F0),
        );
      case 'STUDENT':
        return const NotificationCategoryStyle(
          foreground: MaterialHues.indigo,
          background: Color(0xFFE8EAF6),
        );
      case 'CLASSROOM':
      case 'CLASSROOM_SCHEDULE':
        return const NotificationCategoryStyle(
          foreground: Color(0xFFE65100),
          background: MaterialHues.orange50,
        );
      case 'USER':
        return const NotificationCategoryStyle(
          foreground: MaterialHues.blueGrey700,
          background: Color(0xFFECEFF1),
        );
      case 'BILLING':
      case 'ACCOUNTS':
      case 'INVOICES':
      case 'TRANSACTION':
        return const NotificationCategoryStyle(
          foreground: Color(0xFF2E7D32),
          background: Color(0xFFE7F5E9),
        );
      case 'ACTIVITY':
      case 'ACTIVITIES':
      case 'DAILY_ACTIVITY':
        return const NotificationCategoryStyle(
          foreground: Color(0xFF6A1B9A),
          background: Color(0xFFF3E5F5),
        );
      case 'SCHEDULING':
      case 'STAFF_SCHEDULING':
        return const NotificationCategoryStyle(
          foreground: Color(0xFF1565C0),
          background: MaterialHues.blue50,
        );
      case 'AVAILABILITY':
      case 'FUTURE_AVAILABILITY':
      case 'MOVEMENT_RULES':
      case 'INDIVISUAL_MOVEMENTS':
        return const NotificationCategoryStyle(
          foreground: Color(0xFF2E7D32),
          background: Color(0xFFE7F5E9),
        );
      case 'NEWSLETTER':
      case 'MESSAGING':
      case 'PARENT_MESSAGING':
      case 'STAFF_MESSAGING':
        return const NotificationCategoryStyle(
          foreground: Color(0xFF00838F),
          background: Color(0xFFE0F7FA),
        );
      default:
        return const NotificationCategoryStyle(
          foreground: AppColors.primaryColor,
          background: Color(0xFFF1ECF1),
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
