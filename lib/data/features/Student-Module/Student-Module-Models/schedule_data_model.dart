import 'dart:convert';
import 'package:equatable/equatable.dart';

import '../../../../core/util/typedefs.dart';

class ScheduleEntity extends Equatable {
  final int id;
  final String day;
  final String startTime;
  final String endTime;
  final String status;
  final int schoolId;
  final int studentId;
  final String lastModified;
  final String lastModifiedBy;
  final int program;

  const ScheduleEntity({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.schoolId,
    required this.studentId,
    required this.lastModified,
    required this.lastModifiedBy,
    required this.program,
  });

  @override
  List<Object> get props => [
    id,
    day,
    startTime,
    endTime,
    status,
    schoolId,
    studentId,
    lastModified,
    lastModifiedBy,
    program,
  ];

  static const empty = ScheduleEntity(
    id: 0,
    day: '',
    startTime: '',
    endTime: '',
    status: '',
    schoolId: 0,
    studentId: 0,
    lastModified: '',
    lastModifiedBy: '',
    program: 0,
  );

  static const demo = ScheduleEntity(
    id: 1,
    day: 'Monday',
    startTime: '08:00 AM',
    endTime: '03:00 PM',
    status: 'Active',
    schoolId: 1,
    studentId: 1,
    lastModified: '2025-09-18',
    lastModifiedBy: 'Admin',
    program: 101,
  );
}

class ScheduleDataModel extends ScheduleEntity {
  const ScheduleDataModel({
    required super.id,
    required super.day,
    required super.startTime,
    required super.endTime,
    required super.status,
    required super.schoolId,
    required super.studentId,
    required super.lastModified,
    required super.lastModifiedBy,
    required super.program,
  });

  ScheduleDataModel copyWith({
    int? id,
    String? day,
    String? startTime,
    String? endTime,
    String? status,
    int? schoolId,
    int? studentId,
    String? lastModified,
    String? lastModifiedBy,
    int? program,
  }) {
    return ScheduleDataModel(
      id: id ?? this.id,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      lastModified: lastModified ?? this.lastModified,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      program: program ?? this.program,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'id': id,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'schoolId': schoolId,
      'studentId': studentId,
      'lastModified': lastModified,
      'lastModifiedBy': lastModifiedBy,
      'program': program,
    };
  }

  factory ScheduleDataModel.fromMap(DataMap map) {
    return ScheduleDataModel(
      id: map['id'] as int? ?? 0,
      day: map['day'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      status: map['status'] as String? ?? '',
      schoolId: map['schoolId'] as int? ?? 0,
      studentId: map['studentId'] as int? ?? 0,
      lastModified: map['lastModified'] as String? ?? '',
      lastModifiedBy: map['lastModifiedBy'] as String? ?? '',
      program: map['program'] as int? ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ScheduleDataModel.fromJson(String source) =>
      ScheduleDataModel.fromMap(json.decode(source) as DataMap);

  @override
  bool get stringify => true;

  static const empty = ScheduleDataModel(
    id: 0,
    day: '',
    startTime: '',
    endTime: '',
    status: '',
    schoolId: 0,
    studentId: 0,
    lastModified: '',
    lastModifiedBy: '',
    program: 0,
  );

  static const demo = ScheduleDataModel(
    id: 1,
    day: 'Monday',
    startTime: '08:00 AM',
    endTime: '03:00 PM',
    status: 'Active',
    schoolId: 1,
    studentId: 1,
    lastModified: '2025-09-18',
    lastModifiedBy: 'Admin',
    program: 101,
  );

  static const demoList = [demo];
}
