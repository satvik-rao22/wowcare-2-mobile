/// The four bulk attendance actions the staff list can launch for the staff
/// members currently selected.
///
/// Replaces the `String actionName` ('sign_in', 'sign_out', 'transfer',
/// anything-else-means-absent) the screen used to branch on four times over:
/// a typo silently fell through to the mark-absent branch.
enum StaffAttendanceAction {
  signIn('/attendance/staff-sign-in'),
  signOut('/attendance/staff-sign-out'),
  transfer('/attendance/staff-transfer'),
  markAbsent('/attendance/staff-mark-absent');

  const StaffAttendanceAction(this.routePath);

  /// The attendance form route this action opens with the resolved targets.
  final String routePath;
}
