import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';

/// Visual mapping for event types and RSVP statuses, taken from the Figma
/// Make events design (indigo/purple/blue/green/teal family) and adapted
/// to the app's existing palette.
class EventUiUtils {
  EventUiUtils._();

  static Color typeColor(EventType type) {
    switch (type) {
      case EventType.classroom:
        return const Color(0xFF5978F7); // indigo
      case EventType.student:
        return const Color(0xFF9C6BF7); // purple
      case EventType.staff:
        return const Color(0xFF4A90D9); // blue
      case EventType.school:
        return const Color(0xFF4CAF50); // green
      case EventType.custom:
        return const Color(0xFF26A69A); // teal
      case EventType.individual:
        return const Color(0xFFF57C00); // orange
    }
  }

  static Color typeBackground(EventType type) =>
      typeColor(type).withValues(alpha: 0.10);

  static IconData typeIcon(EventType type) {
    switch (type) {
      case EventType.classroom:
        return Icons.meeting_room_outlined;
      case EventType.student:
        return Icons.child_care_outlined;
      case EventType.staff:
        return Icons.badge_outlined;
      case EventType.school:
        return Icons.school_outlined;
      case EventType.custom:
        return Icons.auto_awesome_outlined;
      case EventType.individual:
        return Icons.person_outline;
    }
  }

  static Color rsvpColor(EventRsvpStatus status) {
    switch (status) {
      case EventRsvpStatus.attending:
        return const Color(0xFF388E3C);
      case EventRsvpStatus.maybe:
        return const Color(0xFFF9A825);
      case EventRsvpStatus.notAttending:
        return const Color(0xFFD32F2F);
    }
  }

  static IconData rsvpIcon(EventRsvpStatus status) {
    switch (status) {
      case EventRsvpStatus.attending:
        return Icons.check_circle_outline;
      case EventRsvpStatus.maybe:
        return Icons.help_outline;
      case EventRsvpStatus.notAttending:
        return Icons.cancel_outlined;
    }
  }

  /// Formats a `HH:mm` 24-hour string as `h:mm AM/PM`. Returns the raw
  /// value when it doesn't parse.
  static String formatTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return hhmm;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(dt);
  }

  /// "All day" or "9:30 AM - 11:00 AM".
  static String timeLabel(Event event) {
    if (event.allDay) return 'All day';
    final start = formatTime(event.startTime);
    final end = formatTime(event.endTime);
    if (start.isEmpty) return 'All day';
    return end.isEmpty ? start : '$start - $end';
  }

  /// "2 classrooms • 5 staff • Parents invited" style summary.
  static String audienceSummary(Event event) {
    final parts = <String>[];
    if (event.type == EventType.school) {
      parts.add('Entire school');
    } else {
      if (event.classrooms.isNotEmpty) {
        parts.add(_plural(event.classrooms.length, 'classroom'));
      }
      if (event.students.isNotEmpty) {
        parts.add(_plural(event.students.length, 'student'));
      }
    }
    if (event.staff.isNotEmpty) {
      parts.add(_plural(event.staff.length, 'staff', plural: 'staff'));
    }
    if (event.includeParents) parts.add('Parents invited');
    return parts.isEmpty ? 'No attendees selected' : parts.join(' • ');
  }

  static String _plural(int count, String singular, {String? plural}) {
    return '$count ${count == 1 ? singular : (plural ?? '${singular}s')}';
  }
}
