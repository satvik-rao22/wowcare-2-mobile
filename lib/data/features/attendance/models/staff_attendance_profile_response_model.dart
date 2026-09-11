import 'package:equatable/equatable.dart';

import 'package:wowcare/data/features/attendance/models/student_attendance_models.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_profile_response.dart';

/// Data-layer JSON parsing for [StaffAttendanceProfileResponse]. The domain
/// entity stays pure (no `fromJson`); this model owns the wire parsing and
/// maps into it via [toEntity].
///
/// Byte-faithful to the TWO existing consumers that parse the SAME raw
/// payload in two different ways:
///
/// 1. `staff_attendance_profile.dart` reads `data.aggregations`
///    (`attendedDays` / `totalAttendedTime` / `absentDays`) and the record
///    list under `data.records.content` (present-days cards).
///
/// 2. `my_attendance_cubit.dart` hands the whole raw map to
///    [StaffAttendanceDailyPageModel.fromJson], which reads the pageable
///    shape. That parse is preserved verbatim by exposing the composed
///    model as [dailyPage].
class StaffAttendanceProfileRecordModel extends Equatable {
  const StaffAttendanceProfileRecordModel({
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

  final String attendanceDate;
  final int sequenceNumber;
  final int totalSequenceCount;
  final dynamic signedInTime;
  final dynamic signedOutTime;
  final dynamic transferTime;
  final dynamic nextActionTime;
  final String? signedOutMethod;
  final String transferredBy;
  final String signedInBy;
  final String signedOutBy;
  final String? classroomName;
  final String attendedTime;
  final int attendedHours;
  final int attendedMinutes;
  final String? signedInMethod;
  final String notExpectedComment;

  factory StaffAttendanceProfileRecordModel.fromJson(Map<String, dynamic> m) {
    return StaffAttendanceProfileRecordModel(
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

  StaffAttendanceProfileRecord toEntity() {
    return StaffAttendanceProfileRecord(
      attendanceDate: attendanceDate,
      sequenceNumber: sequenceNumber,
      totalSequenceCount: totalSequenceCount,
      signedInTime: signedInTime,
      signedOutTime: signedOutTime,
      transferTime: transferTime,
      nextActionTime: nextActionTime,
      signedOutMethod: signedOutMethod,
      transferredBy: transferredBy,
      signedInBy: signedInBy,
      signedOutBy: signedOutBy,
      classroomName: classroomName,
      attendedTime: attendedTime,
      attendedHours: attendedHours,
      attendedMinutes: attendedMinutes,
      signedInMethod: signedInMethod,
      notExpectedComment: notExpectedComment,
    );
  }
}

class StaffAttendanceProfileResponseModel extends Equatable {
  const StaffAttendanceProfileResponseModel({
    required this.attendedDays,
    required this.totalAttendedTime,
    required this.absentDays,
    required this.records,
    required this.dailyPage,
  });

  final int attendedDays;
  final String totalAttendedTime;
  final int absentDays;
  final List<StaffAttendanceProfileRecordModel> records;
  final StaffAttendanceDailyPageModel dailyPage;

  factory StaffAttendanceProfileResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final root = json['data'] as Map<String, dynamic>? ?? {};
    final agg = root['aggregations'] as Map<String, dynamic>? ?? {};
    final recordsMap = root['records'] as Map<String, dynamic>? ?? {};
    final content = recordsMap['content'] as List<dynamic>? ?? const [];

    return StaffAttendanceProfileResponseModel(
      attendedDays: agg['attendedDays'] as int? ?? 0,
      totalAttendedTime: agg['totalAttendedTime'] as String? ?? '',
      absentDays: agg['absentDays'] as int? ?? 0,
      records: content
          .map(
            (e) => StaffAttendanceProfileRecordModel.fromJson(
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

  StaffAttendanceProfileResponse toEntity() {
    return StaffAttendanceProfileResponse(
      attendedDays: attendedDays,
      totalAttendedTime: totalAttendedTime,
      absentDays: absentDays,
      records: records.map((r) => r.toEntity()).toList(),
      dailyPage: dailyPage,
    );
  }
}
