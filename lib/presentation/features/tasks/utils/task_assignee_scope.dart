import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';

/// Loads the assignable-staff list for the Task form's assignee picker.
///
/// PRD §5.2 (Create Task): Org/School Admin and CWW Super Admin may assign to
/// any active staff, but a Staff/Teacher persona may only "assign to staff in
/// allowed classes only". This reuses the same classroom-scope resolver the
/// attendance module uses, so the rule matches the rest of the app:
///
/// - Admin / school-admin / org-admin → no classroom restriction (all active
///   staff).
/// - Non-admin staff with allowed classrooms → staff in those classrooms only.
/// - Non-admin staff with no resolved classrooms → unrestricted fallback (same
///   behaviour the attendance scope uses when the profile has no codes).
Future<void> loadAssignableStaff(StaffCubit cubit) async {
  final storage = serviceLocator<StorageService>();
  final scoped = await isAttendanceScopedStaffPersona(storage: storage);
  if (scoped) {
    final codes =
        await resolveAttendanceAllowedClassroomCodes(storage: storage);
    if (codes.isNotEmpty) {
      cubit.updateFilters(classCodes: codes);
    }
  }
  await cubit.loadInitial();
}
