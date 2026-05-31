import 'package:flutter/material.dart';

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
          foreground: Color(0xFF3F51B5),
          background: Color(0xFFE8EAF6),
        );
    }
  }
}
