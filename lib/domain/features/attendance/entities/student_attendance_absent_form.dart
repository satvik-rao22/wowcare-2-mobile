import 'package:equatable/equatable.dart';

class StudentAttendanceAbsentFormItem extends Equatable {
  const StudentAttendanceAbsentFormItem({
    required this.studentCode,
    required this.studentName,
    required this.classroomCode,
    required this.classroomName,
    required this.absenceDate,
    this.markedAbsentTime,
    this.markedAbsentByName,
    this.absenceNote,
    this.markAbsentMethod,
    this.absentDays = 0,
    this.absenceRecordCode,
  });

  final String studentCode;
  final String studentName;
  final String classroomCode;
  final String classroomName;
  final String absenceDate;
  final StudentAttendanceTime? markedAbsentTime;
  final String? markedAbsentByName;
  final String? absenceNote;
  final String? markAbsentMethod;
  final int absentDays;

  /// Server identifier for DELETE `/api/v1/student-absence-records/{code}`.
  final String? absenceRecordCode;

  @override
  List<Object?> get props => [
        studentCode,
        studentName,
        classroomCode,
        classroomName,
        absenceDate,
        markedAbsentTime,
        markedAbsentByName,
        absenceNote,
        markAbsentMethod,
        absentDays,
        absenceRecordCode,
      ];
}

class StudentAttendanceTime extends Equatable {
  const StudentAttendanceTime({
    required this.hour,
    required this.minute,
    this.second = 0,
    this.nano = 0,
  });

  final int hour;
  final int minute;
  final int second;
  final int nano;

  String get formattedHms {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    final s = second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// 12-hour clock with AM/PM (e.g. `2:05:03 PM`).
  String get formatted12h {
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    final mm = minute.toString().padLeft(2, '0');
    final ss = second.toString().padLeft(2, '0');
    return '$h12:$mm:$ss $period';
  }

  @override
  List<Object?> get props => [hour, minute, second, nano];
}

class StudentAttendanceAbsentFormPage extends Equatable {
  const StudentAttendanceAbsentFormPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StudentAttendanceAbsentFormItem> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];
}

