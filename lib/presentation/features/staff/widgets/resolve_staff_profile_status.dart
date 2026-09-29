import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_profile_usecase.dart';

/// Real employment status ('ACTIVE'/'UPCOMING'/...) for [staffCode], for
/// passing as the `profileStatus` extra when opening
/// [StaffAttendanceProfile] from a screen that doesn't already have it.
///
/// The staff-attendance-daily/custom/absent screens' own data
/// (`StaffAttendanceCardData`/`StaffAttendanceDailyItem`) has no status
/// field — the daily attendance API they read from doesn't return one,
/// unlike the general staff list (`staff_screen.dart`'s
/// `_attendanceAvailabilityForSelection` reads `StaffMember.status` from
/// that list, which it already has loaded). Those three screens don't have
/// that list, so this fetches the one profile it needs instead of
/// hardcoding 'A' — which is what let Sign-In/Mark Absent stay enabled for
/// Upcoming staff (who haven't started yet) when opened from any of them.
///
/// Falls back to 'ACTIVE' on failure — matches the previous hardcoded
/// behavior rather than blocking navigation on a lookup that isn't the
/// primary purpose of these screens.
Future<String> resolveStaffProfileStatus(String staffCode) async {
  if (staffCode.trim().isEmpty) return 'ACTIVE';
  try {
    final profile = await serviceLocator<GetStaffProfileUseCase>().call(
      staffCode: staffCode,
    );
    final status = profile.status.trim().toUpperCase();
    return status.isEmpty ? 'ACTIVE' : status;
  } catch (_) {
    return 'ACTIVE';
  }
}
