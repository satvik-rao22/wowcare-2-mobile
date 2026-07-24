import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/events/entities/calendar_feed_item.dart';
import 'package:wowcare/presentation/features/events/utils/event_ui_utils.dart';

/// One card in the calendar's selected-day list — renders any feed kind
/// (event / task / holiday) with a color accent from the server's
/// `colorHint`, title, time, and a kind-specific summary line. Holidays
/// are non-tappable ([onTap] null).
class CalendarFeedCard extends StatelessWidget {
  const CalendarFeedCard({required this.item, this.onTap, super.key});

  final CalendarFeedItem item;
  final VoidCallback? onTap;

  Color get _accent {
    final hex = item.colorHint.replaceAll('#', '');
    if (hex.length == 6) {
      final v = int.tryParse('FF$hex', radix: 16);
      if (v != null) return Color(v);
    }
    return item.isTask
        ? const Color(0xFFFBBF24)
        : item.isHoliday
            ? const Color(0xFFF87171)
            : const Color(0xFF2563EB);
  }

  String get _timeLabel {
    if (item.allDay) return 'All day';
    if (item.startTime.isEmpty) return 'All day';
    final start = EventUiUtils.formatTime(item.startTime);
    final end = EventUiUtils.formatTime(item.endTime);
    return end.isEmpty ? start : '$start - $end';
  }

  ({String label, IconData icon}) get _badge {
    if (item.isTask) return (label: 'Task', icon: Icons.check_circle_outline);
    if (item.isHoliday) {
      return (label: 'Holiday', icon: Icons.beach_access_outlined);
    }
    return (label: 'Event', icon: Icons.event_outlined);
  }

  String get _summary {
    if (item.isTask) {
      final p = item.priority.isEmpty ? '' : '${_titleCase(item.priority)} • ';
      return '$p${item.completedAssignees}/${item.totalAssignees} done';
    }
    if (item.isHoliday) return _titleCase(item.holidayType);
    // Event
    return '${item.attendingCount}/${item.totalAttendee} attending';
  }

  static String _titleCase(String s) => s.isEmpty
      ? s
      : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withValues(alpha: 0.25)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(badge.icon, size: 14, color: _accent),
                            const SizedBox(width: 4),
                            Text(
                              badge.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _accent,
                              ),
                            ),
                            if (item.recurring) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.repeat, size: 12, color: Colors.grey[500]),
                            ],
                            const Spacer(),
                            if (onTap != null)
                              Icon(Icons.chevron_right,
                                  size: 16, color: Colors.grey[400]),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              _timeLabel,
                              style:
                                  TextStyle(fontSize: 11.5, color: Colors.grey[700]),
                            ),
                            if (!item.isHoliday) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _summary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
