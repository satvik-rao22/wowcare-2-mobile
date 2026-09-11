import 'package:equatable/equatable.dart';

import 'package:wowcare/data/features/attendance/models/student_attendance_models.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_profile_absent_toggle_response.dart';

/// Data-layer JSON parsing for [StaffAttendanceProfileAbsentToggleResponse].
/// The domain entity stays pure (no `fromJson`); this model owns the wire
/// parsing and maps into it via [toEntity].
///
/// Byte-faithful to the TWO existing consumers that parse the SAME raw
/// payload in two different ways:
///
/// 1. `staff_attendance_profile.dart` reads `data.aggregations.absentDays`
///    and the record list under `data.records.content` (absent-days toggle
///    cards).
///
/// 2. `my_attendance_cubit.dart` hands the whole raw map to
///    [StaffAttendanceAbsentPageModel.fromJson], which reads the pageable
///    shape. That parse is preserved verbatim by exposing the composed
///    model as [absentPage].
class StaffAttendanceProfileAbsentToggleRecordModel extends Equatable {
  const StaffAttendanceProfileAbsentToggleRecordModel({
    required this.absenceDate,
    required this.markedAbsentTime,
    required this.markedAbsentByName,
    required this.markedAbsentBy,
    required this.absenceNote,
    required this.markAbsentMethod,
    required this.classroomName,
    required this.classroomCode,
  });

  final String absenceDate;
  final dynamic markedAbsentTime;
  final dynamic markedAbsentByName;
  final dynamic markedAbsentBy;
  final String absenceNote;
  final String? markAbsentMethod;
  final String? classroomName;
  final String? classroomCode;

  factory StaffAttendanceProfileAbsentToggleRecordModel.fromJson(
    Map<String, dynamic> m,
  ) {
    return StaffAttendanceProfileAbsentToggleRecordModel(
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

  StaffAttendanceProfileAbsentToggleRecord toEntity() {
    return StaffAttendanceProfileAbsentToggleRecord(
      absenceDate: absenceDate,
      markedAbsentTime: markedAbsentTime,
      markedAbsentByName: markedAbsentByName,
      markedAbsentBy: markedAbsentBy,
      absenceNote: absenceNote,
      markAbsentMethod: markAbsentMethod,
      classroomName: classroomName,
      classroomCode: classroomCode,
    );
  }
}

class StaffAttendanceProfileAbsentToggleResponseModel extends Equatable {
  const StaffAttendanceProfileAbsentToggleResponseModel({
    required this.absentDays,
    required this.records,
    required this.absentPage,
  });

  final int absentDays;
  final List<StaffAttendanceProfileAbsentToggleRecordModel> records;
  final StaffAttendanceAbsentPageModel absentPage;

  factory StaffAttendanceProfileAbsentToggleResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final root = json['data'] as Map<String, dynamic>? ?? {};
    final agg = root['aggregations'] as Map<String, dynamic>? ?? {};
    final recordsMap = root['records'] as Map<String, dynamic>? ?? {};
    final content = recordsMap['content'] as List<dynamic>? ?? const [];

    return StaffAttendanceProfileAbsentToggleResponseModel(
      absentDays: agg['absentDays'] as int? ?? 0,
      records: content
          .map(
            (e) => StaffAttendanceProfileAbsentToggleRecordModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      absentPage: StaffAttendanceAbsentPageModel.fromJson(json),
    );
  }

  @override
  List<Object?> get props => [absentDays, records, absentPage];

  StaffAttendanceProfileAbsentToggleResponse toEntity() {
    return StaffAttendanceProfileAbsentToggleResponse(
      absentDays: absentDays,
      records: records.map((r) => r.toEntity()).toList(),
      absentPage: absentPage,
    );
  }
}
