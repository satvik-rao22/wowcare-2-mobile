import 'package:equatable/equatable.dart';

import 'package:wowcare/data/features/attendance/models/student_attendance_models.dart';

/// Typed model for the staff attendance profile (present-day summary +
/// records) response.
///
/// This is a pure client-side typing of the raw response the
/// `fetchStaffAttendanceProfile` repository method used to return as a raw
/// `Map<String, dynamic>?`. It is byte-faithful to the TWO existing consumers,
/// which parse the SAME raw payload in two different ways:
///
/// 1. `staff_attendance_profile.dart` reads `data.aggregations`
///    (`attendedDays` / `totalAttendedTime` / `absentDays`) and the record
///    list under `data.records.content` (present-days cards). Every field is
///    read with the exact same `as T? ?? default` the screen applied — see
///    [StaffAttendanceProfileRecord].
///
/// 2. `my_attendance_cubit.dart` hands the whole raw map to
///    [StaffAttendanceDailyPageModel.fromJson], which reads the pageable shape
///    (`data.content` + `data.number` / `data.size` / `data.totalPages` /
///    `data.totalElements` + `data.aggregations`). That parse is preserved
///    verbatim by exposing the composed model as [dailyPage].
class StaffAttendanceProfileRecord extends Equatable {
  const StaffAttendanceProfileRecord({
    required this.attendanceDate,
    required this.sequenceNumber,
    required this.totalSequenceCount,
    required this.signedInTime,
    required this.signedOutTime,
    required this.transferTime,
    required this.nextActionTime,
    required this.signedOutMethod,
    required this.transferredBy,
    required this.signedInBy,
    required this.signedOutBy,
    required this.classroomName,
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

  /// `m['signedOutMethod'] as String?` (nullable; passed to method->enum mapper)
  final String? signedOutMethod;

  /// `m['transferredBy'] as String? ?? ''` (screen keeps the `.trim()`)
  final String transferredBy;

  /// `m['signedInBy'] as String? ?? ''` (screen keeps the `.trim()`)
  final String signedInBy;

  /// `m['signedOutBy'] as String? ?? ''` (screen keeps the `.trim()`)
  final String signedOutBy;

  /// `m['classroomName'] as String?` (nullable; screen falls back to roomName)
  final String? classroomName;

  /// `m['attendedTime'] as String? ?? ''`
  final String attendedTime;

  /// `m['attendedHours'] as int? ?? 0`
  final int attendedHours;

  /// `m['attendedMinutes'] as int? ?? 0`
  final int attendedMinutes;

  /// `m['signedInMethod'] as String?` (nullable; passed to method->enum mapper)
  final String? signedInMethod;

  /// `m['notExpectedComment'] as String? ?? ''` (screen keeps the `.trim()`)
  final String notExpectedComment;

  factory StaffAttendanceProfileRecord.fromJson(Map<String, dynamic> m) {
    return StaffAttendanceProfileRecord(
      attendanceDate: m['attendanceDate'] as String? ?? '',
      sequenceNumber: m['sequenceNumber'] as int? ?? 1,
      totalSequenceCount: m['totalSequenceCount'] as int? ?? 1,
      signedInTime: m['signedInTime'],
      signedOutTime: m['signedOutTime'],
      transferTime: m['transferTime'],
      nextActionTime: m['nextActionTime'],
      signedOutMethod: m['signedOutMethod'] as String?,
      transferredBy: m['transferredBy'] as String? ?? '',
      signedInBy: m['signedInBy'] as String? ?? '',
      signedOutBy: m['signedOutBy'] as String? ?? '',
      classroomName: m['classroomName'] as String?,
      attendedTime: m['attendedTime'] as String? ?? '',
      attendedHours: m['attendedHours'] as int? ?? 0,
      attendedMinutes: m['attendedMinutes'] as int? ?? 0,
      signedInMethod: m['signedInMethod'] as String?,
      notExpectedComment: m['notExpectedComment'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        attendanceDate,
        sequenceNumber,
        totalSequenceCount,
        signedInTime,
        signedOutTime,
        transferTime,
        nextActionTime,
        signedOutMethod,
        transferredBy,
        signedInBy,
        signedOutBy,
        classroomName,
        attendedTime,
        attendedHours,
        attendedMinutes,
        signedInMethod,
        notExpectedComment,
      ];
}

class StaffAttendanceProfileResponse extends Equatable {
  const StaffAttendanceProfileResponse({
    required this.attendedDays,
    required this.totalAttendedTime,
    required this.absentDays,
    required this.records,
    required this.dailyPage,
  });

  /// `aggJson['attendedDays'] as int? ?? 0`
  final int attendedDays;

  /// `aggJson['totalAttendedTime'] as String? ?? ''`
  final String totalAttendedTime;

  /// `aggJson['absentDays'] as int? ?? 0`
  final int absentDays;

  /// `data.records.content` parsed into typed records (present-days screen).
  final List<StaffAttendanceProfileRecord> records;

  /// The whole raw payload parsed the pageable way the dashboard cubit needs
  /// (`StaffAttendanceDailyPageModel.fromJson`), byte-for-byte unchanged.
  final StaffAttendanceDailyPageModel dailyPage;

  factory StaffAttendanceProfileResponse.fromJson(Map<String, dynamic> json) {
    final root = json['data'] as Map<String, dynamic>? ?? {};
    final agg = root['aggregations'] as Map<String, dynamic>? ?? {};
    final recordsMap = root['records'] as Map<String, dynamic>? ?? {};
    final content = recordsMap['content'] as List<dynamic>? ?? const [];

    return StaffAttendanceProfileResponse(
      attendedDays: agg['attendedDays'] as int? ?? 0,
      totalAttendedTime: agg['totalAttendedTime'] as String? ?? '',
      absentDays: agg['absentDays'] as int? ?? 0,
      records: content
          .map(
            (e) => StaffAttendanceProfileRecord.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      dailyPage: StaffAttendanceDailyPageModel.fromJson(json),
    );
  }

  @override
  List<Object?> get props => [
        attendedDays,
        totalAttendedTime,
        absentDays,
        records,
        dailyPage,
      ];
}
