import 'package:equatable/equatable.dart';

/// Typed model for the student attendance profile absent-toggle list response.
///
/// This is a pure client-side typing of the raw response the
/// `student_attendance_profile` screen used to parse inline for its absent-days
/// toggle list. The parsing is byte-faithful to that screen: the aggregation
/// `absentDays` and the per-record fields are read with the exact same
/// `as T? ?? default` (and raw `??`) the screen applied, and the same
/// null-guards for the nested `data` / `aggregations` / `records.content`
/// containers.
class StudentAttendanceProfileAbsentToggleRecord extends Equatable {
  const StudentAttendanceProfileAbsentToggleRecord({
    required this.absenceDate,
    required this.markedAbsentTime,
    required this.markedAbsentByName,
    required this.markedAbsentBy,
    required this.absenceNote,
    required this.markAbsentMethod,
    required this.classroomCode,
    required this.classroomName,
  });

  /// `m['absenceDate'] as String? ?? ''`
  final String absenceDate;

  // Time field is read raw (no cast) by the screen and handed to
  // `_formatApiTime`, which accepts both a `String` and an object-shaped
  // `Map<String, dynamic>` ({hour, minute, ...}). Kept `dynamic` to preserve
  // that exact behaviour — a `String?` cast would throw on the object-shaped
  // payload and change functionality.

  /// `m['markedAbsentTime']` (raw)
  final dynamic markedAbsentTime;

  // The screen reads `(m['markedAbsentByName'] ?? m['markedAbsentBy'] ?? '')`
  // .toString() — both keys are read raw (no cast) and coalesced, so both are
  // kept `dynamic` to preserve that exact expression.

  /// `m['markedAbsentByName']` (raw)
  final dynamic markedAbsentByName;

  /// `m['markedAbsentBy']` (raw)
  final dynamic markedAbsentBy;

  /// `m['absenceNote'] as String? ?? ''`
  final String absenceNote;

  /// `m['markAbsentMethod'] as String?` (nullable; passed to method->enum mapper)
  final String? markAbsentMethod;

  /// `m['classroomCode'] as String?` (nullable; passed to code->name resolver)
  final String? classroomCode;

  /// `m['classroomName'] as String?` (nullable; screen trims + falls back)
  final String? classroomName;

  @override
  List<Object?> get props => [
    absenceDate,
    markedAbsentTime,
    markedAbsentByName,
    markedAbsentBy,
    absenceNote,
    markAbsentMethod,
    classroomCode,
    classroomName,
  ];
}

class StudentAttendanceProfileAbsentToggleResponse extends Equatable {
  const StudentAttendanceProfileAbsentToggleResponse({
    required this.absentDays,
    required this.records,
  });

  /// `agg['absentDays'] as int? ?? 0`
  final int absentDays;

  /// `data.records.content` parsed into typed records.
  final List<StudentAttendanceProfileAbsentToggleRecord> records;

  @override
  List<Object?> get props => [absentDays, records];
}
