/// The two validation rules that every regularization write must satisfy,
/// in one place.
///
/// Both the client (pre-validating a sheet before submit) and the in-memory
/// fake datasource run these, and the server enforces the same rules — so
/// keeping them here means the message the staff sees locally matches the
/// reason the backend would reject for.
///
/// Spec: `docs/attendance_regularization_requirements.md` §8.2 (reason) and
/// §8.5 (day window).
abstract final class RegTimePolicy {
  const RegTimePolicy._();

  /// Fallback close-of-day cap, school-local, used when the school's schedule
  /// settings are unavailable (§8.5: "schools close before 19:00").
  static const int fallbackCapHour = 19;

  /// The latest sign-out allowed on [attendanceDate] when no school schedule
  /// is available. Same calendar day — a corrected time may never cross
  /// midnight (§8.5).
  static DateTime fallbackCapFor(DateTime attendanceDate) => DateTime(
        attendanceDate.year,
        attendanceDate.month,
        attendanceDate.day,
        fallbackCapHour,
      );

  /// The time to pre-fill the sheet with.
  ///
  /// [suggested] is computed server-side (§9.1) and is nullable, so this
  /// resolves the fallback once rather than letting every sheet invent its
  /// own default.
  static DateTime suggestedOr(DateTime? suggested, DateTime attendanceDate) =>
      suggested ?? fallbackCapFor(attendanceDate);

  /// Validates a proposed sign-out. Returns `null` when acceptable, otherwise
  /// a message safe to show the user.
  ///
  /// Applies to a raise (§9.2), a batch raise item (§9.2b), an edit (§9.4) and
  /// an admin's modified approval time (§9.6) — §8.5 names all four.
  ///
  /// [cap] overrides [fallbackCapFor] when the school's real working-hours end
  /// is known.
  static String? validateSignOut({
    required DateTime signOutLocal,
    required DateTime attendanceDate,
    DateTime? signedInAt,
    DateTime? cap,
  }) {
    if (signedInAt != null && !signOutLocal.isAfter(signedInAt)) {
      return 'Sign-out must be after sign-in.';
    }
    final limit = cap ?? fallbackCapFor(attendanceDate);
    if (signOutLocal.isAfter(limit)) {
      return 'Time is outside the school day.';
    }
    return null;
  }

  /// Validates a reason. Returns `null` when acceptable.
  ///
  /// §8.2: mandatory on **every** write — trimmed, so a single space does not
  /// satisfy it. There is no "confirm" shortcut any more: with the stored
  /// suggestion and `confirmed_suggested_time` both dropped from the model,
  /// the server cannot tell "kept the pre-filled time" from "typed the same
  /// time deliberately", so every request states a reason.
  static String? validateReason(String? reason) {
    if ((reason ?? '').trim().isEmpty) {
      return 'Add a reason.';
    }
    return null;
  }

  /// True when [reason] passes [validateReason].
  static bool hasReason(String? reason) => validateReason(reason) == null;
}
