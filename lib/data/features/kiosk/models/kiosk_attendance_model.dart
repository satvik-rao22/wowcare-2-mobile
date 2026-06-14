import 'package:wowcare/domain/features/kiosk/entities/kiosk_attendance_entity.dart';

/// Data model for kiosk staff attendance (DTO).
/// Represents the API response structure.
class KioskStaffAttendanceModel {
  KioskStaffAttendanceModel({
    required this.staffCode,
    required this.status,
    this.currentClassroomCode,
    this.message,
  });

  final String staffCode;
  final String status;
  final String? currentClassroomCode;
  final String? message;

  factory KioskStaffAttendanceModel.fromJson(Map<String, dynamic> json) {
    return KioskStaffAttendanceModel(
      staffCode: json['staffCode'] ?? '',
      status: json['status'] ?? 'SIGNED_OUT',
      currentClassroomCode: json['currentClassroomCode'],
      message: json['message'],
    );
  }

  /// Convert to domain entity (for business logic layer)
  KioskStaffAttendanceEntity toEntity() {
    return KioskStaffAttendanceEntity(
      staffCode: staffCode,
      status: status,
      currentClassroomCode: currentClassroomCode,
      message: message,
    );
  }
}

/// Data model for kiosk attendance status (DTO).
class KioskAttendanceStatusModel {
  KioskAttendanceStatusModel({
    required this.staffCode,
    required this.status,
    required this.statusMap,
  });

  final String staffCode;
  final String status;
  final Map<String, String> statusMap;

  factory KioskAttendanceStatusModel.fromJson(Map<String, dynamic> json) {
    final statusData = json['data'] as Map<String, dynamic>? ?? {};
    final statusMap = <String, String>{};
    statusData.forEach((key, value) {
      statusMap[key] = value.toString();
    });

    final primaryStatus = statusMap.isEmpty ? 'SIGNED_OUT' : statusMap.values.first;

    return KioskAttendanceStatusModel(
      staffCode: statusMap.keys.isNotEmpty ? statusMap.keys.first : '',
      status: primaryStatus,
      statusMap: statusMap,
    );
  }

  /// Convert to domain entity
  KioskAttendanceStatusEntity toEntity() {
    return KioskAttendanceStatusEntity(
      staffCode: staffCode,
      status: status,
      statusMap: statusMap,
    );
  }
}

/// Data model for kiosk student attendance (DTO).
class KioskStudentAttendanceModel {
  KioskStudentAttendanceModel({
    required this.studentCode,
    required this.status,
    this.message,
  });

  final String studentCode;
  final String status;
  final String? message;

  factory KioskStudentAttendanceModel.fromJson(Map<String, dynamic> json) {
    return KioskStudentAttendanceModel(
      studentCode: json['studentCode'] ?? '',
      status: json['status'] ?? 'SIGNED_OUT',
      message: json['message'],
    );
  }

  /// Convert to domain entity
  KioskStudentAttendanceEntity toEntity() {
    return KioskStudentAttendanceEntity(
      studentCode: studentCode,
      status: status,
      message: message,
    );
  }
}
