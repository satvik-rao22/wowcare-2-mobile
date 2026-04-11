import 'package:equatable/equatable.dart';

class StudentAttendanceDailyItem extends Equatable {
  const StudentAttendanceDailyItem({
    this.attendanceRecordCode,
    this.studentCode,
    required this.studentName,
    required this.isExpectedToday,
    required this.classroomName,
    this.signedInAt,
    this.signedInTime,
    this.signedInBy,
    this.signedOutAt,
    this.signedOutTime,
    this.signedOutBy,
    this.signedInMethod,
    this.signedOutMethod,
    required this.classroomCode,
    required this.tagCodes,
    required this.tagNames,
    this.duration,
    // Transfer-related fields
    this.isTransfer,
    this.sequenceNumber,
    this.totalSequenceCount,
    this.hasNextTransfer,
    this.isLastSequenceEntry,
    this.fromClassroomCode,
    this.fromClassroomName,
    this.toClassroomCode,
    this.toClassroomName,
    this.transferTime,
    this.nextActionTime,
    this.transferredBy,
    this.transferReason,
  });

  final String? attendanceRecordCode;
  final String? studentCode;
  final String studentName;
  final bool isExpectedToday;
  final String classroomName;
  final String? signedInAt;
  final StudentAttendanceTime? signedInTime;
  final String? signedInBy;
  final String? signedOutAt;
  final StudentAttendanceTime? signedOutTime;
  final String? signedOutBy;
  /// Sign-in method code as returned by the API (e.g. GPS, PIN, QR, APP).
  final String? signedInMethod;

  /// Sign-out method code as returned by the API (e.g. GPS, PIN, QR, APP).
  final String? signedOutMethod;
  final String classroomCode;
  final List<String> tagCodes;
  final List<String> tagNames;
  final String? duration;

  // Transfer-related fields
  final bool? isTransfer;
  final int? sequenceNumber;
  final int? totalSequenceCount;
  final bool? hasNextTransfer;
  final bool? isLastSequenceEntry;
  final String? fromClassroomCode;
  final String? fromClassroomName;
  final String? toClassroomCode;
  final String? toClassroomName;
  final StudentAttendanceTime? transferTime;
  final StudentAttendanceTime? nextActionTime;
  final String? transferredBy;
  final String? transferReason;

  /// Helper to check if student has signed in
  bool get hasSignIn => signedInAt != null && signedInAt!.isNotEmpty;

  /// Helper to format sign in time
  String? get formattedSignInTime => signedInTime?.formattedTime;

  /// Helper to format sign out time
  String? get formattedSignOutTime => signedOutTime?.formattedTime;

  @override
  List<Object?> get props => [
        attendanceRecordCode,
        studentCode,
        studentName,
        isExpectedToday,
        classroomName,
        signedInAt,
        signedInTime,
        signedInBy,
        signedOutAt,
        signedOutTime,
        signedOutBy,
        signedInMethod,
        signedOutMethod,
        classroomCode,
        tagCodes,
        tagNames,
        duration,
        // Transfer-related fields
        isTransfer,
        sequenceNumber,
        totalSequenceCount,
        hasNextTransfer,
        isLastSequenceEntry,
        fromClassroomCode,
        fromClassroomName,
        toClassroomCode,
        toClassroomName,
        transferTime,
        nextActionTime,
        transferredBy,
        transferReason,
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

  /// Formats time as "HH:mm AM/PM"
  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  @override
  List<Object?> get props => [hour, minute, second, nano];
}

class StudentAttendanceDailyPage extends Equatable {
  const StudentAttendanceDailyPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StudentAttendanceDailyItem> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];
}
