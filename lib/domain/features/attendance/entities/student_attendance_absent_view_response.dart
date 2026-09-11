import 'package:equatable/equatable.dart';

/// Typed model for the student absent-view list response.
///
/// This is a pure client-side typing of the raw response the
/// `student_attendance_absent_view` screen used to parse inline. The screen
/// previously read the top-level `data` object off the payload —
/// `data['data'] as Map<String, dynamic>? ?? {}` — and then hand-parsed the
/// page fields (`content` / `last` / `number`) and each record's fields inside
/// its own `_applyPagePayload(...)`.
///
/// Those exact casts/defaults now live in the paired
/// `StudentAttendanceAbsentViewResponseModel` (data layer) so this entity
/// stays a pure typed value — the model's `toJson`/`fromJson` reconstruct the
/// same key shape the screen used to cache verbatim, so the cache round-trip
/// stays byte-faithful.

/// A single absent-student record inside the paged `content` list.
class StudentAbsentViewRecord extends Equatable {
  const StudentAbsentViewRecord({
    required this.absenceDate,
    required this.classroomName,
    required this.classroomCode,
    required this.studentCode,
    required this.studentName,
    required this.absentDays,
    required this.markedAbsentTime,
    required this.markedAbsentByName,
    required this.absenceNote,
  });

  /// `m['absenceDate'] as String? ?? ''`
  final String absenceDate;

  /// `m['classroomName'] as String?`
  final String? classroomName;

  /// `m['classroomCode'] as String?`
  final String? classroomCode;

  /// `m['studentCode'] as String? ?? ''`
  final String studentCode;

  /// `m['studentName'] as String? ?? ''`
  final String studentName;

  /// `m['absentDays'] as int? ?? 0`
  final int absentDays;

  /// `m['markedAbsentTime']` kept raw (String OR `{hour,minute,second}` OR null)
  /// so the screen's `parseTime(...)` can discriminate the shape.
  final dynamic markedAbsentTime;

  /// `m['markedAbsentByName'] as String? ?? ''`
  final String markedAbsentByName;

  /// `m['absenceNote'] as String?`
  final String? absenceNote;

  @override
  List<Object?> get props => [
    absenceDate,
    classroomName,
    classroomCode,
    studentCode,
    studentName,
    absentDays,
    markedAbsentTime,
    markedAbsentByName,
    absenceNote,
  ];
}

class StudentAttendanceAbsentViewResponse extends Equatable {
  const StudentAttendanceAbsentViewResponse({
    required this.content,
    required this.last,
    required this.number,
  });

  /// `root['content'] as List? ?? const []` mapped to typed records.
  final List<StudentAbsentViewRecord> content;

  /// `root['last'] as bool?` (screen applies its own `?? true` default).
  final bool? last;

  /// `root['number'] as int?` (screen applies its own `?? _studentsPage`).
  final int? number;

  @override
  List<Object?> get props => [content, last, number];
}
