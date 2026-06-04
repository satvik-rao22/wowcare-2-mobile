import 'package:equatable/equatable.dart';

/// Domain entity for kiosk staff attendance result.
/// Pure business logic - no API dependencies.
class KioskStaffAttendanceEntity extends Equatable {
  const KioskStaffAttendanceEntity({
    required this.staffCode,
    required this.status,
    this.currentClassroomCode,
    this.message,
  });

  final String staffCode;
  final String status; // 'SIGNED_IN' or 'SIGNED_OUT'
  final String? currentClassroomCode;
  final String? message;

  @override
  List<Object?> get props => [staffCode, status, currentClassroomCode, message];
}

/// Domain entity for kiosk student attendance result.
class KioskStudentAttendanceEntity extends Equatable {
  const KioskStudentAttendanceEntity({
    required this.studentCode,
    required this.status,
    this.message,
  });

  final String studentCode;
  final String status; // 'SIGNED_IN' or 'SIGNED_OUT'
  final String? message;

  @override
  List<Object?> get props => [studentCode, status, message];
}

/// Domain entity for kiosk attendance status.
class KioskAttendanceStatusEntity extends Equatable {
  const KioskAttendanceStatusEntity({
    required this.staffCode,
    required this.status,
    required this.statusMap,
  });

  final String staffCode;
  final String status;
  final Map<String, String> statusMap;

  @override
  List<Object?> get props => [staffCode, status, statusMap];
}
