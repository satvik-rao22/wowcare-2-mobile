import 'package:equatable/equatable.dart';

/// Typed model for the student attendance profile (present-day summary +
/// records) response.
///
/// This is a pure client-side typing of the raw response the
/// `student_attendance_profile` screen used to parse inline. The parsing is
/// byte-faithful to that screen: every field is read with the exact same
/// `as T? ?? default` the screen applied, and the same null-guards for the
/// nested `data` / `aggregations` / `records.content` containers.
class StudentAttendanceProfileRecord extends Equatable {
  const StudentAttendanceProfileRecord({
    required this.attendanceDate,
    required this.sequenceNumber,
    required this.totalSequenceCount,
    required this.signedInTime,
    required this.signedOutTime,
    required this.transferTime,
    required this.nextActionTime,
    required this.classroomName,
    required this.classroomCode,
    required this.signedOutMethod,
    required this.transferredBy,
    required this.signedInBy,
    required this.signedOutBy,
    required this.attendedTime,
    required this.attendedHours,
    required this.attendedMinutes,
    required this.signedInMethod,
    required this.notExpectedComment,
  });

  /// `m['attendanceDate'] as String? ?? ''`
  final String attendanceDate;

  /// `m['sequenceNumber'] as int? ?? 1`
  final int sequenceNumber;

  /// `m['totalSequenceCount'] as int? ?? 1`
  final int totalSequenceCount;

  // Time fields are read raw (no cast) by the screen and handed to
  // `_formatApiTime`, which accepts both a `String` and an object-shaped
  // `Map<String, dynamic>` ({hour, minute, ...}). They are kept `dynamic` to
  // preserve that exact behaviour — a `String?` cast would throw on the
  // object-shaped payload and change functionality.

  /// `m['signedInTime']` (raw)
  final dynamic signedInTime;

  /// `m['signedOutTime']` (raw)
  final dynamic signedOutTime;

  /// `m['transferTime']` (raw)
  final dynamic transferTime;

  /// `m['nextActionTime']` (raw)
  final dynamic nextActionTime;

  /// `m['classroomName'] as String?` (nullable; screen falls back to roomName)
  final String? classroomName;

  /// `m['classroomCode'] as String?` (nullable; passed to code->name resolver)
  final String? classroomCode;

  /// `m['signedOutMethod'] as String?` (nullable; passed to method->enum mapper)
  final String? signedOutMethod;

  /// `m['transferredBy'] as String? ?? ''`
  final String transferredBy;

  /// `m['signedInBy'] as String? ?? ''`
  final String signedInBy;

  /// `m['signedOutBy'] as String? ?? ''`
  final String signedOutBy;

  /// `m['attendedTime'] as String? ?? ''`
  final String attendedTime;

  /// `m['attendedHours'] as int? ?? 0`
  final int attendedHours;

  /// `m['attendedMinutes'] as int? ?? 0`
  final int attendedMinutes;

  /// `m['signedInMethod'] as String?` (nullable; passed to method->enum mapper)
  final String? signedInMethod;

  /// `m['notExpectedComment'] as String? ?? ''`
  final String notExpectedComment;

  @override
  List<Object?> get props => [
    attendanceDate,
    sequenceNumber,
    totalSequenceCount,
    signedInTime,
    signedOutTime,
    transferTime,
    nextActionTime,
    classroomName,
    classroomCode,
    signedOutMethod,
    transferredBy,
    signedInBy,
    signedOutBy,
    attendedTime,
    attendedHours,
    attendedMinutes,
    signedInMethod,
    notExpectedComment,
  ];
}

class StudentAttendanceProfileResponse extends Equatable {
  const StudentAttendanceProfileResponse({
    required this.attendedDays,
    required this.totalAttendedTime,
    required this.records,
  });

  /// `agg['attendedDays'] as int? ?? 0`
  final int attendedDays;

  /// `agg['totalAttendedTime'] as String? ?? ''`
  final String totalAttendedTime;

  /// `data.records.content` parsed into typed records.
  final List<StudentAttendanceProfileRecord> records;

  @override
  List<Object?> get props => [attendedDays, totalAttendedTime, records];
}
