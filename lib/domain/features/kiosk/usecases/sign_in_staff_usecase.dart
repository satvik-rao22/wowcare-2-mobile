import 'package:wowcare/domain/features/kiosk/entities/kiosk_attendance_entity.dart';
import 'package:wowcare/domain/features/kiosk/repositories/kiosk_attendance_repository.dart';

/// Use case: Staff member signs in via kiosk.
///
/// Encapsulates business logic for staff sign-in:
/// 1. Call sign-in API
/// 2. Fetch updated status
/// 3. Return complete attendance state
///
/// Pure business logic - no UI, no state management.
class SignInStaffUseCase {
  SignInStaffUseCase(this._repository);

  final KioskAttendanceRepository _repository;

  Future<KioskStaffAttendanceEntity> call({
    required String staffCode,
    required String schoolCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
    String? pin,
  }) {
    return _repository.signInStaff(
      staffCode: staffCode,
      schoolCode: schoolCode,
      timeZone: timeZone,
      latitude: latitude,
      longitude: longitude,
      withinGeofence: withinGeofence,
      pin: pin,
    );
  }
}
