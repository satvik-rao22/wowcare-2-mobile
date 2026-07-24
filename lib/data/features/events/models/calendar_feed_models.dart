import 'package:wowcare/domain/features/events/entities/calendar_feed_item.dart';

/// Parses one `/api/v1/calendar/feed` row into a [CalendarFeedItem].
class CalendarFeedItemModel {
  CalendarFeedItemModel._();

  static CalendarFeedItem? fromApi(Map<String, dynamic> json) {
    final kind = CalendarFeedKind.fromValue(json['type']?.toString());
    final code = (json['code'] ?? '').toString().trim();
    if (code.isEmpty) return null;

    final date = DateTime.tryParse(
      (json['scheduledStartDate'] ?? '').toString(),
    );
    if (date == null) return null;

    final rsvp = json['rsvpSummary'];
    final counts = json['participantCounts'];
    int summ(dynamic m, String k) =>
        (m is Map ? (m[k] as num?)?.toInt() : null) ?? 0;

    return CalendarFeedItem(
      kind: kind,
      code: code,
      name: (json['displayName'] ?? '').toString(),
      description: (json['displayDescription'] ?? '').toString(),
      location: (json['displayLocation'] ?? '').toString(),
      date: DateTime(date.year, date.month, date.day),
      allDay: json['allDayFlag'] == true,
      startTime: _hhmm(json['scheduledStartTime']),
      endTime: _hhmm(json['scheduledEndTime']),
      status: (json['status'] ?? '').toString().toUpperCase(),
      recurring: json['recurring'] == true,
      colorHint: (json['colorHint'] ?? '').toString().trim(),
      // Event
      eventCode: (json['eventCode'] ?? '').toString().trim(),
      eventType: (json['eventType'] ?? '').toString().toUpperCase(),
      includeParents: json['includeParentsFlag'] == true,
      attendingCount: summ(rsvp, 'attending'),
      totalAttendee: summ(rsvp, 'totalAttendee'),
      staffCount: summ(counts, 'staff'),
      studentCount: summ(counts, 'students'),
      parentCount: summ(counts, 'parents'),
      createdBy: (json['createdBy'] ?? '').toString().trim(),
      // Task
      taskCode: (json['taskCode'] ?? '').toString().trim(),
      priority: (json['priority'] ?? '').toString().toUpperCase(),
      totalAssignees: (json['totalAssignees'] as num?)?.toInt() ?? 0,
      completedAssignees:
          (json['completedAssignees'] as num?)?.toInt() ?? 0,
      // Holiday
      holidayType: (json['holidayType'] ?? '').toString().toUpperCase(),
    );
  }

  static String _hhmm(dynamic raw) {
    final v = (raw ?? '').toString().trim();
    return v.length >= 5 ? v.substring(0, 5) : v;
  }
}
