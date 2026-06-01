import 'package:equatable/equatable.dart';

/// Domain entity for school attendance GPS settings.
///
/// Values come exclusively from
/// GET /api/v1/attendance/schools/{schoolCode}/attendance-settings.
/// Never hardcode defaults in business logic — always read from this entity.
class AttendanceSettingsEntity extends Equatable {
  const AttendanceSettingsEntity({
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

  @override
  List<Object?> get props => [
        gpsSignInEnabled,
        proximityRadiusMeters,
        maxProximityLimitMeters,
        allowOutsideSchoolHours,
        outsideTimeWindowMinutes,
        allowTeacherCrossClassAttendance,
        autoSignOutEnabled,
        autoSignOutDelayMinutes,
      ];
}
