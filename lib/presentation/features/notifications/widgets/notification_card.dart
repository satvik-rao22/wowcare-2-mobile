import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

import '../../../../domain/features/notifications/entities/app_notification.dart';
import 'notification_category_style.dart';

/// A single notification row in the center, matching the design: a coloured
/// initials avatar, the title, a relative timestamp, a category chip, a chevron
/// and an unread blue dot.
///
/// Stateless and dumb: it renders the [notification] and forwards taps to
/// [onTap]. All read-state logic lives in the cubit.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Prefer the real backend `module` (ATTENDANCE / CLASSROOM / USER / …) so
    // the chip reflects the actual source, not the 3-bucket category (which
    // collapses unknown modules to "Staff"). Falls back to the category label.
    final module = (notification.data['module'] ?? '').trim();
    final chipLabel = module.isNotEmpty
        ? NotificationCategoryStyle.moduleLabel(module)
        : notification.category.label;
    final style = module.isNotEmpty
        ? NotificationCategoryStyle.forModule(module)
        : NotificationCategoryStyle.of(notification.category);
    final isUnread = !notification.isRead;

    return Material(
      color: AppColors.whiteColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile avatar via the shared DocumentImageWidget. With no
              // image/codes and the lookup fallbacks disabled it renders a
              // stable coloured initials avatar (no network calls) — the
              // initials come from the subject's name (e.g. "Parker Long" → PL).
              // When notifications later carry a staff/student code, pass it
              // here and real photos resolve automatically.
              DocumentImageWidget(
                fileUuid: notification.id,
                name: notification.subjectName ?? notification.category.label,
                size: 40,
                fontSize: 15,
                disableProfileLookupFallback: true,
                disableAttendanceStatusLookup: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    if ((notification.body ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body!.trim(),
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                          color: AppColors.primaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          _relativeTime(notification.createdAt),
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.primaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _CategoryChip(
                          label: chipLabel,
                          style: style,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.primaryColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 8),
                  if (isUnread)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppPalette.statusInfo,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(width: 10, height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact "x mins/hrs/days ago" formatting (no external dependency).
  static String _relativeTime(DateTime time) {
    final diff = AppTime.nowUtc().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'min' : 'mins'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hr' : 'hrs'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    }
    final w = (diff.inDays / 7).floor();
    return '$w ${w == 1 ? 'week' : 'weeks'} ago';
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.style});

  final String label;
  final NotificationCategoryStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: style.foreground,
        ),
      ),
    );
  }
}
