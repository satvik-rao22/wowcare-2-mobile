import 'package:equatable/equatable.dart';

/// Kind of a unified calendar-feed row. The app renders EVENT/TASK/HOLIDAY
/// today; unknown kinds (BIRTHDAY, IMPORTANT_DATE — not built yet) parse as
/// [unknown] and are skipped by the UI.
enum CalendarFeedKind {
  event('EVENT'),
  task('TASK'),
  holiday('HOLIDAY'),
  unknown('');

  const CalendarFeedKind(this.value);

  final String value;

  static CalendarFeedKind fromValue(String? raw) {
    final v = (raw ?? '').trim().toUpperCase();
    for (final k in CalendarFeedKind.values) {
      if (k.value == v) return k;
    }
    return CalendarFeedKind.unknown;
  }
}

/// One lightweight row of `GET /api/v1/calendar/feed` — enough to paint a
/// calendar dot and a summary card. Full details (roster, myRsvp, task
/// assignees list) are fetched from the per-item detail APIs on tap.
class CalendarFeedItem extends Equatable {
  const CalendarFeedItem({
    required this.kind,
    required this.code,
    required this.name,
    required this.date,
    required this.allDay,
    this.description = '',
    this.location = '',
    this.startTime = '',
    this.endTime = '',
    this.status = '',
    this.recurring = false,
    this.colorHint = '',
    // Event-only
    this.eventCode = '',
    this.eventType = '',
    this.includeParents = false,
    this.attendingCount = 0,
    this.totalAttendee = 0,
    this.staffCount = 0,
    this.studentCount = 0,
    this.parentCount = 0,
    this.createdBy = '',
    // Task-only
    this.taskCode = '',
    this.priority = '',
    this.totalAssignees = 0,
    this.completedAssignees = 0,
    this.assigneeCode = '',
    this.dueDate,
    this.overdue = false,
    // Holiday-only
    this.holidayType = '',
  });

  final CalendarFeedKind kind;

  /// Row identity: occurrence code (EVENT), task-occurrence code (TASK),
  /// or holiday code (HOLIDAY).
  final String code;
  final String name;
  final String description;
  final String location;
  final DateTime date;
  final bool allDay;
  final String startTime;
  final String endTime;
  final String status;
  final bool recurring;

  /// Server-provided hex color for the dot/accent (e.g. `#2563EB`).
  final String colorHint;

  final String eventCode;
  final String eventType;
  final bool includeParents;
  final int attendingCount;
  final int totalAttendee;
  final int staffCount;
  final int studentCount;
  final int parentCount;
  final String createdBy;

  final String taskCode;
  final String priority;
  final int totalAssignees;
  final int completedAssignees;

  /// Task-occurrence assignee (the feed returns one row per assignee).
  final String assigneeCode;
  final DateTime? dueDate;
  final bool overdue;

  final String holidayType;

  bool get isEvent => kind == CalendarFeedKind.event;
  bool get isTask => kind == CalendarFeedKind.task;
  bool get isHoliday => kind == CalendarFeedKind.holiday;

  bool occursOn(DateTime day) =>
      date.year == day.year && date.month == day.month && date.day == day.day;

  @override
  List<Object?> get props => [kind, code, date, status];
}
