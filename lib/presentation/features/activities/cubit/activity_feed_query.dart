import 'package:equatable/equatable.dart';

/// Immutable, fully-resolved inputs for a single daily-feed load.
///
/// Every field here is the RESOLVED value the View used to derive inline from
/// its own filter/selection state (`_selectedClassroomCodesForFeed`,
/// `_selectedStudentCodesForAttendanceFilter`, `_selectedAttendanceEventFilter`,
/// `_activityTypeCodesForApiFilter`, `_approvalStatusesForApiFilter`,
/// `_shouldIncludeAttendanceEntries`, `_isMarkedAbsentEvent`, `_dateQueryParam`,
/// `_filterTags`, ...) before calling the feed APIs. Passing this object to
/// [ActivityFeedCubit] means the cubit depends on NO View filter field — the
/// View (or a later resolver) does the resolution and hands over a plain value.
class ActivityFeedQuery extends Equatable {
  const ActivityFeedQuery({
    required this.organizationCode,
    required this.schoolCode,
    required this.classroomCode,
    this.classroomCodes = const <String>[],
    required this.dateStr,
    this.studentCode,
    this.studentCodes,
    this.attendanceEvent,
    this.signInAtFilter,
    this.signOutAtFilter,
    this.typeCodes,
    this.approvalStatuses,
    this.tagCodes = const <String>[],
    this.guardianPersona = false,
    this.includeAttendance = true,
    this.isMarkedAbsentEvent = false,
    this.pageSize = 10,
  });

  /// Active organization scope.
  final String organizationCode;

  /// Active school scope. Empty is treated as "not ready" (load clears items).
  final String schoolCode;

  /// Primary/first classroom code for the feed API. Empty is "not ready".
  final String classroomCode;

  /// All selected classroom codes (multi-select); used for the feed +
  /// attendance/absent calls. May be empty (falls back to [classroomCode]).
  final List<String> classroomCodes;

  /// `yyyy-MM-dd` date the feed is for (already `_dateQueryParam`-formatted).
  final String dateStr;

  /// Single selected student code, if the feed is scoped to one student.
  final String? studentCode;

  /// All selected student codes for the attendance/absent filter.
  final List<String>? studentCodes;

  /// Resolved attendance event label ('Sign-in' / 'Sign-out' / 'Transfer' /
  /// 'Marked Absent'), or null for "all events". Mirrors
  /// `_selectedAttendanceEventFilter()`.
  final String? attendanceEvent;

  /// `'NOT_NULL'` when the attendance API should filter to signed-in rows.
  final String? signInAtFilter;

  /// `'NOT_NULL'` when the attendance API should filter to signed-out rows.
  final String? signOutAtFilter;

  /// Activity-type codes for the feed API (`activityTypeCode[]`).
  final List<String>? typeCodes;

  /// Approval-status enums for the feed API. Only sent on the FIRST page load,
  /// matching the View (`_loadDailyFeed` passes it; pagination does not).
  final List<String>? approvalStatuses;

  /// Selected tag names/codes. Drives the client-side `_withTagFilterOnly`
  /// gate — when empty, no tag filtering is applied.
  final List<String> tagCodes;

  /// Parent-home persona (guardian). Passed as `guardianPersona` to the feed.
  final bool guardianPersona;

  /// Whether the attendance + absent sub-feeds should be fetched at all.
  /// Mirrors `_filterApprovalStatuses.isEmpty && _shouldIncludeAttendanceEntries()`.
  final bool includeAttendance;

  /// Whether the selected event is 'Marked Absent' (absent-only sub-path).
  /// Mirrors `_isMarkedAbsentEvent(selectedEvent)`.
  final bool isMarkedAbsentEvent;

  /// Rows per page for every sub-feed. Mirrors `_feedPageSize`.
  final int pageSize;

  ActivityFeedQuery copyWith({
    String? organizationCode,
    String? schoolCode,
    String? classroomCode,
    List<String>? classroomCodes,
    String? dateStr,
    String? studentCode,
    List<String>? studentCodes,
    String? attendanceEvent,
    String? signInAtFilter,
    String? signOutAtFilter,
    List<String>? typeCodes,
    List<String>? approvalStatuses,
    List<String>? tagCodes,
    bool? guardianPersona,
    bool? includeAttendance,
    bool? isMarkedAbsentEvent,
    int? pageSize,
  }) {
    return ActivityFeedQuery(
      organizationCode: organizationCode ?? this.organizationCode,
      schoolCode: schoolCode ?? this.schoolCode,
      classroomCode: classroomCode ?? this.classroomCode,
      classroomCodes: classroomCodes ?? this.classroomCodes,
      dateStr: dateStr ?? this.dateStr,
      studentCode: studentCode ?? this.studentCode,
      studentCodes: studentCodes ?? this.studentCodes,
      attendanceEvent: attendanceEvent ?? this.attendanceEvent,
      signInAtFilter: signInAtFilter ?? this.signInAtFilter,
      signOutAtFilter: signOutAtFilter ?? this.signOutAtFilter,
      typeCodes: typeCodes ?? this.typeCodes,
      approvalStatuses: approvalStatuses ?? this.approvalStatuses,
      tagCodes: tagCodes ?? this.tagCodes,
      guardianPersona: guardianPersona ?? this.guardianPersona,
      includeAttendance: includeAttendance ?? this.includeAttendance,
      isMarkedAbsentEvent: isMarkedAbsentEvent ?? this.isMarkedAbsentEvent,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
        organizationCode,
        schoolCode,
        classroomCode,
        classroomCodes,
        dateStr,
        studentCode,
        studentCodes,
        attendanceEvent,
        signInAtFilter,
        signOutAtFilter,
        typeCodes,
        approvalStatuses,
        tagCodes,
        guardianPersona,
        includeAttendance,
        isMarkedAbsentEvent,
        pageSize,
      ];
}
