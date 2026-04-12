import 'package:equatable/equatable.dart';

class StaffAttendanceAbsentItem extends Equatable {
  const StaffAttendanceAbsentItem({
    required this.staffCode,
    required this.staffName,
    required this.classroomCode,
    required this.classroomName,
    required this.absenceDate,
    this.markedAbsentTime,
    required this.markedAbsentByName,
    this.absenceNote,
    required this.absentDays,
  });

  final String staffCode;
  final String staffName;
  final String classroomCode;
  final String classroomName;
  final String absenceDate;
  final StaffAttendanceTime? markedAbsentTime;
  final String markedAbsentByName;
  final String? absenceNote;
  final int absentDays;

  @override
  List<Object?> get props => [
        staffCode,
        staffName,
        classroomCode,
        classroomName,
        absenceDate,
        markedAbsentTime,
        markedAbsentByName,
        absenceNote,
        absentDays,
      ];
}

class StaffAttendanceTime extends Equatable {
  const StaffAttendanceTime({
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

class StaffAttendanceAbsentPage extends Equatable {
  const StaffAttendanceAbsentPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StaffAttendanceAbsentItem> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];
}

