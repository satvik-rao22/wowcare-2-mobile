import 'package:equatable/equatable.dart';

import 'package:wowcare/domain/features/attendance/entities/student_attendance_profile_response.dart';

/// Data-layer JSON parsing for [StudentAttendanceProfileResponse]. The
/// domain entity stays pure (no `fromJson`); this model owns the wire
/// parsing and maps into it via [toEntity].
///
/// Byte-faithful to the raw response the `student_attendance_profile`
/// screen used to parse inline: every field is read with the exact same
/// `as T? ?? default` the screen applied, and the same null-guards for the
/// nested `data` / `aggregations` / `records.content` containers.
class StudentAttendanceProfileRecordModel extends Equatable {
  const StudentAttendanceProfileRecordModel({
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

  final String attendanceDate;
  final int sequenceNumber;
  final int totalSequenceCount;
  final dynamic signedInTime;
  final dynamic signedOutTime;
  final dynamic transferTime;
  final dynamic nextActionTime;
  final String? classroomName;
  final String? classroomCode;
  final String? signedOutMethod;
  final String transferredBy;
  final String signedInBy;
  final String signedOutBy;
  final String attendedTime;
  final int attendedHours;
  final int attendedMinutes;
  final String? signedInMethod;
  final String notExpectedComment;

  factory StudentAttendanceProfileRecordModel.fromJson(Map<String, dynamic> m) {
    return StudentAttendanceProfileRecordModel(
      attendanceDate: m['attendanceDate'] as String? ?? '',
      sequenceNumber: m['sequenceNumber'] as int? ?? 1,
      totalSequenceCount: m['totalSequenceCount'] as int? ?? 1,
      signedInTime: m['signedInTime'],
      signedOutTime: m['signedOutTime'],
      transferTime: m['transferTime'],
      nextActionTime: m['nextActionTime'],
      classroomName: m['classroomName'] as String?,
      classroomCode: m['classroomCode'] as String?,
      signedOutMethod: m['signedOutMethod'] as String?,
      transferredBy: m['transferredBy'] as String? ?? '',
      signedInBy: m['signedInBy'] as String? ?? '',
      signedOutBy: m['signedOutBy'] as String? ?? '',
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

  StudentAttendanceProfileRecord toEntity() {
    return StudentAttendanceProfileRecord(
      attendanceDate: attendanceDate,
      sequenceNumber: sequenceNumber,
      totalSequenceCount: totalSequenceCount,
      signedInTime: signedInTime,
      signedOutTime: signedOutTime,
      transferTime: transferTime,
      nextActionTime: nextActionTime,
      classroomName: classroomName,
      classroomCode: classroomCode,
      signedOutMethod: signedOutMethod,
      transferredBy: transferredBy,
      signedInBy: signedInBy,
      signedOutBy: signedOutBy,
      attendedTime: attendedTime,
      attendedHours: attendedHours,
      attendedMinutes: attendedMinutes,
      signedInMethod: signedInMethod,
      notExpectedComment: notExpectedComment,
    );
  }
}

class StudentAttendanceProfileResponseModel extends Equatable {
  const StudentAttendanceProfileResponseModel({
    required this.attendedDays,
    required this.totalAttendedTime,
    required this.records,
  });

  final int attendedDays;
  final String totalAttendedTime;
  final List<StudentAttendanceProfileRecordModel> records;

  factory StudentAttendanceProfileResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final root = json['data'] as Map<String, dynamic>? ?? {};
    final agg = root['aggregations'] as Map<String, dynamic>? ?? {};
    final recordsMap = root['records'] as Map<String, dynamic>? ?? {};
    final content = recordsMap['content'] as List<dynamic>? ?? const [];

    return StudentAttendanceProfileResponseModel(
      attendedDays: agg['attendedDays'] as int? ?? 0,
      totalAttendedTime: agg['totalAttendedTime'] as String? ?? '',
      records: content
          .map(
            (e) => StudentAttendanceProfileRecordModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => [attendedDays, totalAttendedTime, records];

  StudentAttendanceProfileResponse toEntity() {
    return StudentAttendanceProfileResponse(
      attendedDays: attendedDays,
      totalAttendedTime: totalAttendedTime,
      records: records.map((r) => r.toEntity()).toList(),
    );
  }
}
