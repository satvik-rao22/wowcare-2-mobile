import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';

/// The classroom codes the Task form's assignee picker must be restricted to,
/// or an empty list when the persona may assign to any active staff member.
///
/// PRD §5.2 (Create Task): Org/School Admin and CWW Super Admin may assign to
/// any active staff, but a Staff/Teacher persona may only "assign to staff in
/// allowed classes only". This reuses the same classroom-scope resolver the
/// attendance module uses, so the rule matches the rest of the app:
///
/// - Admin / school-admin / org-admin (and guardians, who have no task access
///   at all) → no classroom restriction.
/// - Non-admin staff with allowed classrooms → those classrooms only.
/// - Non-admin staff with no resolvable classrooms → unrestricted, the same
///   fallback the attendance scope uses when the profile carries no codes
///   (otherwise the picker would be empty and the persona could not create the
///   tasks the PRD grants them).
Future<List<String>> assignableStaffClassroomScope({
  required StorageService storage,
}) async {
  final scoped = await isAttendanceScopedStaffPersona(storage: storage);
  if (!scoped) return const <String>[];
  return resolveAttendanceAllowedClassroomCodes(storage: storage);
}

/// Loads the assignable-staff list for the Task form's assignee picker, scoped
/// per [assignableStaffClassroomScope].
Future<void> loadAssignableStaff(
  StaffCubit cubit, {
  StorageService? storage,
}) async {
  final codes = await assignableStaffClassroomScope(
    storage: storage ?? serviceLocator<StorageService>(),
  );
  if (codes.isNotEmpty) {
    cubit.updateFilters(classCodes: codes);
  }
  await cubit.loadInitial();
}
