import 'package:equatable/equatable.dart';

class StaffAttendanceDailyItem extends Equatable {
  const StaffAttendanceDailyItem({
    required this.staffCode,
    required this.staffName,
    required this.isExpectedToday,
    required this.classroomName,
    required this.classroomCode,
    required this.attendedDays,
    this.signedInBy,
    this.signedInTime,
    this.signedOutBy,
    this.signedOutTime,
    required this.designation,
    this.attendedTime,
    this.attendedHours,
    this.attendedMinutes,
    this.signedInMethod,
    this.signedOutMethod,
  });

  final String staffCode;
  final String staffName;
  final bool isExpectedToday;
  final String classroomName;
  final String classroomCode;
  final int attendedDays;
  final String? signedInBy;
  final StaffAttendanceTime? signedInTime;
  final String? signedOutBy;
  final StaffAttendanceTime? signedOutTime;
  final List<String> designation;
  final String? attendedTime;
  final int? attendedHours;
  final int? attendedMinutes;

  /// Sign-in method code as returned by the API (e.g. GPS, PIN, QR, APP).
  final String? signedInMethod;

  /// Sign-out method code as returned by the API (e.g. GPS, PIN, QR, APP).
  final String? signedOutMethod;

  bool get hasSignIn => signedInTime != null || (signedInBy != null && signedInBy!.isNotEmpty);

  String? get formattedSignInTime => signedInTime?.formattedTime;

  String? get formattedSignOutTime => signedOutTime?.formattedTime;

  @override
  List<Object?> get props => [
        staffCode,
        staffName,
        isExpectedToday,
        classroomName,
        classroomCode,
        attendedDays,
        signedInBy,
        signedInTime,
        signedOutBy,
        signedOutTime,
        designation,
        attendedTime,
        attendedHours,
        attendedMinutes,
        signedInMethod,
        signedOutMethod,
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

  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  @override
  List<Object?> get props => [hour, minute, second, nano];
}

class StaffAttendanceDailyPage extends Equatable {
  const StaffAttendanceDailyPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StaffAttendanceDailyItem> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];
}

