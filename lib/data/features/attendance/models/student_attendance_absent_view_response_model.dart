import 'package:equatable/equatable.dart';

import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_view_response.dart';

/// Data-layer JSON parsing (and re-serialization, for the local cache
/// round-trip) for [StudentAttendanceAbsentViewResponse]. The domain entity
/// stays pure (no `fromJson`/`toJson`); this model owns the wire/cache shape
/// and maps to/from it via [toEntity]/[fromEntity].
///
/// Byte-faithful to the raw response the `student_attendance_absent_view`
/// screen used to parse inline — it previously read the top-level `data`
/// object off the payload (`data['data'] as Map<String, dynamic>? ?? {}`)
/// and hand-parsed the page fields (`content` / `last` / `number`) and each
/// record's fields inside its own `_applyPagePayload(...)`.
///
/// [toJson] reconstructs the same key shape the screen used to cache
/// verbatim, so the cache round-trip (write [toJson], read [fromJson]) stays
/// byte-faithful.
class StudentAbsentViewRecordModel extends Equatable {
  const StudentAbsentViewRecordModel({
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

  final String absenceDate;
  final String? classroomName;
  final String? classroomCode;
  final String studentCode;
  final String studentName;
  final int absentDays;
  final dynamic markedAbsentTime;
  final String markedAbsentByName;
  final String? absenceNote;

  factory StudentAbsentViewRecordModel.fromJson(Map<String, dynamic> m) {
    return StudentAbsentViewRecordModel(
      absenceDate: m['absenceDate'] as String? ?? '',
      classroomName: m['classroomName'] as String?,
      classroomCode: m['classroomCode'] as String?,
      studentCode: m['studentCode'] as String? ?? '',
      studentName: m['studentName'] as String? ?? '',
      absentDays: m['absentDays'] as int? ?? 0,
      markedAbsentTime: m['markedAbsentTime'],
      markedAbsentByName: m['markedAbsentByName'] as String? ?? '',
      absenceNote: m['absenceNote'] as String?,
    );
  }

  factory StudentAbsentViewRecordModel.fromEntity(
    StudentAbsentViewRecord entity,
  ) {
    return StudentAbsentViewRecordModel(
      absenceDate: entity.absenceDate,
      classroomName: entity.classroomName,
      classroomCode: entity.classroomCode,
      studentCode: entity.studentCode,
      studentName: entity.studentName,
      absentDays: entity.absentDays,
      markedAbsentTime: entity.markedAbsentTime,
      markedAbsentByName: entity.markedAbsentByName,
      absenceNote: entity.absenceNote,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'absenceDate': absenceDate,
      'classroomName': classroomName,
      'classroomCode': classroomCode,
      'studentCode': studentCode,
      'studentName': studentName,
      'absentDays': absentDays,
      'markedAbsentTime': markedAbsentTime,
      'markedAbsentByName': markedAbsentByName,
      'absenceNote': absenceNote,
    };
  }

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

  StudentAbsentViewRecord toEntity() {
    return StudentAbsentViewRecord(
      absenceDate: absenceDate,
      classroomName: classroomName,
      classroomCode: classroomCode,
      studentCode: studentCode,
      studentName: studentName,
      absentDays: absentDays,
      markedAbsentTime: markedAbsentTime,
      markedAbsentByName: markedAbsentByName,
      absenceNote: absenceNote,
    );
  }
}

class StudentAttendanceAbsentViewResponseModel extends Equatable {
  const StudentAttendanceAbsentViewResponseModel({
    required this.content,
    required this.last,
    required this.number,
  });

  final List<StudentAbsentViewRecordModel> content;
  final bool? last;
  final int? number;

  factory StudentAttendanceAbsentViewResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final root = json['data'] as Map<String, dynamic>? ?? {};
    return StudentAttendanceAbsentViewResponseModel(
      content: (root['content'] as List? ?? const [])
          .map(
            (e) => StudentAbsentViewRecordModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      last: root['last'] as bool?,
      number: root['number'] as int?,
    );
  }

  factory StudentAttendanceAbsentViewResponseModel.fromEntity(
    StudentAttendanceAbsentViewResponse entity,
  ) {
    return StudentAttendanceAbsentViewResponseModel(
      content: entity.content
          .map((r) => StudentAbsentViewRecordModel.fromEntity(r))
          .toList(),
      last: entity.last,
      number: entity.number,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'data': <String, dynamic>{
        'content': content.map((r) => r.toJson()).toList(),
        'last': last,
        'number': number,
      },
    };
  }

  @override
  List<Object?> get props => [content, last, number];

  StudentAttendanceAbsentViewResponse toEntity() {
    return StudentAttendanceAbsentViewResponse(
      content: content.map((r) => r.toEntity()).toList(),
      last: last,
      number: number,
    );
  }
}
