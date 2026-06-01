import '../../../../domain/features/geofencing/entities/attendance_settings_entity.dart';

/// Data model for
/// GET /api/v1/attendance/schools/{schoolCode}/attendance-settings
class AttendanceSettingsModel {
  const AttendanceSettingsModel({
    required this.gpsSignInEnabled,
    required this.proximityRadiusMeters,
    required this.maxProximityLimitMeters,
    required this.allowOutsideSchoolHours,
    required this.outsideTimeWindowMinutes,
    required this.allowTeacherCrossClassAttendance,
    required this.autoSignOutEnabled,
    required this.autoSignOutDelayMinutes,
  });

  final bool gpsSignInEnabled;
  final double proximityRadiusMeters;
  final double maxProximityLimitMeters;
  final bool allowOutsideSchoolHours;
  final int outsideTimeWindowMinutes;
  final bool allowTeacherCrossClassAttendance;
  final bool autoSignOutEnabled;
  final int autoSignOutDelayMinutes;

  factory AttendanceSettingsModel.fromJson(Map<String, dynamic> json) {
    // Backend wraps response in a `data` key.
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AttendanceSettingsModel(
      gpsSignInEnabled: data['gpsSignInEnabled'] as bool? ?? false,
      proximityRadiusMeters:
          (data['proximityRadiusMeters'] as num?)?.toDouble() ?? 0.0,
      maxProximityLimitMeters:
          (data['maxProximityLimitMeters'] as num?)?.toDouble() ?? 0.0,
      allowOutsideSchoolHours:
          data['allowOutsideSchoolHours'] as bool? ?? false,
      outsideTimeWindowMinutes:
          (data['outsideTimeWindowMinutes'] as num?)?.toInt() ?? 0,
      allowTeacherCrossClassAttendance:
          data['allowTeacherCrossClassAttendance'] as bool? ?? false,
      autoSignOutEnabled: data['autoSignOutEnabled'] as bool? ?? false,
      autoSignOutDelayMinutes:
          (data['autoSignOutDelayMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  AttendanceSettingsEntity toEntity() => AttendanceSettingsEntity(
        gpsSignInEnabled: gpsSignInEnabled,
        proximityRadiusMeters: proximityRadiusMeters,
        maxProximityLimitMeters: maxProximityLimitMeters,
        allowOutsideSchoolHours: allowOutsideSchoolHours,
        outsideTimeWindowMinutes: outsideTimeWindowMinutes,
        allowTeacherCrossClassAttendance: allowTeacherCrossClassAttendance,
        autoSignOutEnabled: autoSignOutEnabled,
        autoSignOutDelayMinutes: autoSignOutDelayMinutes,
      );
}
