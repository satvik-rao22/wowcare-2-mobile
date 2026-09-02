import 'package:equatable/equatable.dart';

import 'package:wowcare/domain/features/attendance/entities/student_attendance_profile_absent_toggle_response.dart';

/// Data-layer JSON parsing for [StudentAttendanceProfileAbsentToggleResponse].
/// The domain entity stays pure (no `fromJson`); this model owns the wire
/// parsing and maps into it via [toEntity].
///
/// Byte-faithful to the raw response the `student_attendance_profile` screen
/// used to parse inline for its absent-days toggle list: the aggregation
/// `absentDays` and the per-record fields are read with the exact same
/// `as T? ?? default` (and raw `??`) the screen applied, and the same
/// null-guards for the nested `data` / `aggregations` / `records.content`
/// containers.
class StudentAttendanceProfileAbsentToggleRecordModel extends Equatable {
  const StudentAttendanceProfileAbsentToggleRecordModel({
    required this.absenceDate,
    required this.markedAbsentTime,
    required this.markedAbsentByName,
    required this.markedAbsentBy,
    required this.absenceNote,
    required this.markAbsentMethod,
    required this.classroomCode,
    required this.classroomName,
  });

  final String absenceDate;
  final dynamic markedAbsentTime;
  final dynamic markedAbsentByName;
  final dynamic markedAbsentBy;
  final String absenceNote;
  final String? markAbsentMethod;
  final String? classroomCode;
  final String? classroomName;

  factory StudentAttendanceProfileAbsentToggleRecordModel.fromJson(
    Map<String, dynamic> m,
  ) {
    return StudentAttendanceProfileAbsentToggleRecordModel(
      absenceDate: m['absenceDate'] as String? ?? '',
      markedAbsentTime: m['markedAbsentTime'],
      markedAbsentByName: m['markedAbsentByName'],
      markedAbsentBy: m['markedAbsentBy'],
      absenceNote: m['absenceNote'] as String? ?? '',
      markAbsentMethod: m['markAbsentMethod'] as String?,
      classroomCode: m['classroomCode'] as String?,
      classroomName: m['classroomName'] as String?,
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
    classroomCode,
    classroomName,
  ];

  StudentAttendanceProfileAbsentToggleRecord toEntity() {
    return StudentAttendanceProfileAbsentToggleRecord(
      absenceDate: absenceDate,
      markedAbsentTime: markedAbsentTime,
      markedAbsentByName: markedAbsentByName,
      markedAbsentBy: markedAbsentBy,
      absenceNote: absenceNote,
      markAbsentMethod: markAbsentMethod,
      classroomCode: classroomCode,
      classroomName: classroomName,
    );
  }
}

class StudentAttendanceProfileAbsentToggleResponseModel extends Equatable {
  const StudentAttendanceProfileAbsentToggleResponseModel({
    required this.absentDays,
    required this.records,
  });

  final int absentDays;
  final List<StudentAttendanceProfileAbsentToggleRecordModel> records;

  factory StudentAttendanceProfileAbsentToggleResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final root = json['data'] as Map<String, dynamic>? ?? {};
    final agg = root['aggregations'] as Map<String, dynamic>? ?? {};
    final recordsMap = root['records'] as Map<String, dynamic>? ?? {};
    final content = recordsMap['content'] as List<dynamic>? ?? const [];

    return StudentAttendanceProfileAbsentToggleResponseModel(
      absentDays: agg['absentDays'] as int? ?? 0,
      records: content
          .map(
            (e) => StudentAttendanceProfileAbsentToggleRecordModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => [absentDays, records];

  StudentAttendanceProfileAbsentToggleResponse toEntity() {
    return StudentAttendanceProfileAbsentToggleResponse(
      absentDays: absentDays,
      records: records.map((r) => r.toEntity()).toList(),
    );
  }
}
