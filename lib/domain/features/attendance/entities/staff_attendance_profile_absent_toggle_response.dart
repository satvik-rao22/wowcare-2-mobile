import 'package:equatable/equatable.dart';

import 'package:wowcare/data/features/attendance/models/student_attendance_models.dart';

/// Typed model for the staff attendance profile absent-toggle list response.
///
/// This is a pure client-side typing of the raw response the
/// `fetchStaffAttendanceProfileAbsentToggle` repository method used to return
/// as a raw `Map<String, dynamic>?`. It is byte-faithful to the TWO existing
/// consumers, which parse the SAME raw payload in two different ways:
///
/// 1. `staff_attendance_profile.dart` reads `data.aggregations.absentDays` and
///    the record list under `data.records.content` (absent-days toggle cards).
///    Every field is read with the exact same `as T? ?? default` (and raw
///    `??`) the screen applied — see [StaffAttendanceProfileAbsentToggleRecord].
///
/// 2. `my_attendance_cubit.dart` hands the whole raw map to
///    [StaffAttendanceAbsentPageModel.fromJson], which reads the pageable shape
///    (`data.content` + `data.number` / `data.size` / `data.totalPages` /
///    `data.totalElements` + `data.aggregations`). That parse is preserved
///    verbatim by exposing the composed model as [absentPage].
class StaffAttendanceProfileAbsentToggleRecord extends Equatable {
  const StaffAttendanceProfileAbsentToggleRecord({
    required this.absenceDate,
    required this.markedAbsentTime,
    required this.markedAbsentByName,
    required this.markedAbsentBy,
    required this.absenceNote,
    required this.markAbsentMethod,
    required this.classroomName,
    required this.classroomCode,
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

  /// `m['classroomName'] as String?` (nullable; screen trims + falls back to code)
  final String? classroomName;

  /// `m['classroomCode'] as String?` (nullable; screen trims for fallback)
  final String? classroomCode;

  factory StaffAttendanceProfileAbsentToggleRecord.fromJson(
    Map<String, dynamic> m,
  ) {
    return StaffAttendanceProfileAbsentToggleRecord(
      absenceDate: m['absenceDate'] as String? ?? '',
      markedAbsentTime: m['markedAbsentTime'],
      markedAbsentByName: m['markedAbsentByName'],
      markedAbsentBy: m['markedAbsentBy'],
      absenceNote: m['absenceNote'] as String? ?? '',
      markAbsentMethod: m['markAbsentMethod'] as String?,
      classroomName: m['classroomName'] as String?,
      classroomCode: m['classroomCode'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        absenceDate,
        markedAbsentTime,
        markedAbsentByName,
        markedAbsentBy,
        absenceNote,
        markAbsentMethod,
        classroomName,
        classroomCode,
      ];
}

class StaffAttendanceProfileAbsentToggleResponse extends Equatable {
  const StaffAttendanceProfileAbsentToggleResponse({
    required this.absentDays,
    required this.records,
    required this.absentPage,
  });

  /// `agg['absentDays'] as int? ?? 0`
  final int absentDays;

  /// `data.records.content` parsed into typed records (profile screen).
  final List<StaffAttendanceProfileAbsentToggleRecord> records;

  /// The whole raw payload parsed the pageable way the dashboard cubit needs
  /// (`StaffAttendanceAbsentPageModel.fromJson`), byte-for-byte unchanged.
  final StaffAttendanceAbsentPageModel absentPage;

  factory StaffAttendanceProfileAbsentToggleResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final root = json['data'] as Map<String, dynamic>? ?? {};
    final agg = root['aggregations'] as Map<String, dynamic>? ?? {};
    final recordsMap = root['records'] as Map<String, dynamic>? ?? {};
    final content = recordsMap['content'] as List<dynamic>? ?? const [];

    return StaffAttendanceProfileAbsentToggleResponse(
      absentDays: agg['absentDays'] as int? ?? 0,
      records: content
          .map(
            (e) => StaffAttendanceProfileAbsentToggleRecord.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      absentPage: StaffAttendanceAbsentPageModel.fromJson(json),
    );
  }

  @override
  List<Object?> get props => [
        absentDays,
        records,
        absentPage,
      ];
}
