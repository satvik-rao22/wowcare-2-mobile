import 'package:equatable/equatable.dart';

class StudentAttendanceCustomItem extends Equatable {
  const StudentAttendanceCustomItem({
    required this.studentCode,
    required this.studentName,
    required this.isExpectedToday,
    required this.classroomName,
    required this.classroomCode,
    required this.attendedDays,
    required this.attendedTime,
    required this.attendedHours,
    required this.attendedMinutes,
    this.signedInBy,
    this.signedInTime,
    this.signedOutBy,
    this.signedOutTime,
    required this.tagCodes,
    required this.tagNames,
  });

  final String studentCode;
  final String studentName;
  final bool isExpectedToday;
  final String classroomName;
  final String classroomCode;
  final int attendedDays;
  final String attendedTime;
  final int attendedHours;
  final int attendedMinutes;
  final String? signedInBy;
  final String? signedInTime;
  final String? signedOutBy;
  final String? signedOutTime;
  final List<String> tagCodes;
  final List<String> tagNames;

  bool get hasSignIn => signedInTime != null && signedInTime!.isNotEmpty;

  bool get hasSignOut => signedOutTime != null && signedOutTime!.isNotEmpty;

  @override
  List<Object?> get props => [
        studentCode,
        studentName,
        isExpectedToday,
        classroomName,
        classroomCode,
        attendedDays,
        attendedTime,
        attendedHours,
        attendedMinutes,
        signedInBy,
        signedInTime,
        signedOutBy,
        signedOutTime,
        tagCodes,
        tagNames,
      ];
}

class StudentAttendanceCustomPage extends Equatable {
  const StudentAttendanceCustomPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StudentAttendanceCustomItem> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];
}

