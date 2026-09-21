/// The two rules every write must satisfy, shared by the sheets and the mock so
/// the message shown locally matches what the server would reject for.
abstract final class RegTimePolicy {
  const RegTimePolicy._();

  /// Used when the school's closing time is unknown.
  static const int fallbackCapHour = 19;

  static DateTime fallbackCapFor(DateTime attendanceDate) => DateTime(
      attendanceDate.year, attendanceDate.month, attendanceDate.day,
      fallbackCapHour);

  static DateTime suggestedOr(DateTime? suggested, DateTime attendanceDate) =>
      suggested ?? fallbackCapFor(attendanceDate);

  /// `null` when acceptable, else a message safe to show the user.
  static String? validateSignOut({
    required DateTime signOutLocal,
    required DateTime attendanceDate,
    DateTime? signedInAt,
    DateTime? cap,
  }) {
    if (signedInAt != null && !signOutLocal.isAfter(signedInAt)) {
      return 'Sign-out must be after sign-in.';
    }
    if (signOutLocal.isAfter(cap ?? fallbackCapFor(attendanceDate))) {
      return 'Time is outside the school day.';
    }
    return null;
  }

  /// Mandatory on every write, and whitespace does not count.
  static String? validateReason(String? reason) =>
      (reason ?? '').trim().isEmpty ? 'Add a reason.' : null;

  static bool hasReason(String? reason) => validateReason(reason) == null;
}
