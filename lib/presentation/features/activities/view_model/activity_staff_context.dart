/// Logged-in staff/session context needed by every activity create/edit
/// screen (who's creating it, their school/org, their active role). Returned
/// by [ActivityEditorCubit.loadStaffContext] — see that method's doc comment
/// for why this is a returned value rather than cubit state.
class StaffContext {
  const StaffContext({
    required this.staffName,
    required this.staffType,
    required this.staffCode,
    required this.staffPresentCode,
    required this.schoolCode,
    required this.organizationCode,
    required this.currentUserCode,
    required this.currentUserRole,
  });

  final String staffName;
  final String staffType;
  final String? staffCode;
  final String? staffPresentCode;
  final String? schoolCode;
  final String? organizationCode;
  final String? currentUserCode;
  final String? currentUserRole;
}
