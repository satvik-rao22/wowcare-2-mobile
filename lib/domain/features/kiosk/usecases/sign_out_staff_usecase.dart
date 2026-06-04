import 'package:wowcare/domain/features/kiosk/entities/kiosk_attendance_entity.dart';
import 'package:wowcare/domain/features/kiosk/repositories/kiosk_attendance_repository.dart';

/// Use case: Staff member signs out via kiosk.
class SignOutStaffUseCase {
  SignOutStaffUseCase(this._repository);

  final KioskAttendanceRepository _repository;

  Future<KioskStaffAttendanceEntity> call({
    required String staffCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  }) {
    return _repository.signOutStaff(
      staffCode: staffCode,
      timeZone: timeZone,
      latitude: latitude,
      longitude: longitude,
      withinGeofence: withinGeofence,
    );
  }
}
