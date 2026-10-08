/// The rules every write must satisfy, shared by the sheets so the message
/// shown locally matches what the server would reject for.
///
/// There is deliberately **no upper bound** on the sign-out time. Staff
/// routinely stay past closing — for clean-up, a parent meeting, a late
/// pick-up — and those are exactly the days someone forgets to sign out, so
/// capping the time would block the very requests this module exists to
/// capture.
abstract final class RegTimePolicy {
  const RegTimePolicy._();

  /// Where the time picker opens when the server sends no suggestion. A
  /// starting point only — any later time is valid.
  static const int defaultSignOutHour = 19;

  static DateTime defaultSignOutFor(DateTime attendanceDate) => DateTime(
    attendanceDate.year,
    attendanceDate.month,
    attendanceDate.day,
    defaultSignOutHour,
  );

  static DateTime suggestedOr(DateTime? suggested, DateTime attendanceDate) =>
      suggested ?? defaultSignOutFor(attendanceDate);

  /// `null` when acceptable, else a message safe to show the user.
  static String? validateSignOut({
    required DateTime signOutLocal,
    required DateTime attendanceDate,
    DateTime? signedInAt,
  }) {
    if (signedInAt != null && !signOutLocal.isAfter(signedInAt)) {
      return 'Sign-out must be after sign-in.';
    }
    return null;
  }

  /// Mandatory on every write, and whitespace does not count.
  static String? validateReason(String? reason) =>
      (reason ?? '').trim().isEmpty ? 'Add a reason.' : null;

  static bool hasReason(String? reason) => validateReason(reason) == null;
}
