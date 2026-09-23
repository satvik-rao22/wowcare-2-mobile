import '../policy/reg_time_policy.dart';

/// What the client submits to revise a still-`PENDING` request (§9.4).
///
/// This is the module's only correction path — there is no cancel (§8.4). Both
/// fields are individually optional but **at least one must be present**;
/// omitting a field leaves the stored value untouched.
///
/// [signOutLocal] carries wall-clock school-local fields; the repository
/// converts it and sends `timeZone` whenever it is present (§9.4, §10.1).
class RegEditInput {
  const RegEditInput({
    required this.code,
    required this.attendanceDate,
    this.signOutLocal,
    this.reason,
  });

  /// The `SREG_…` code being edited.
  final String code;

  /// Needed to validate the new time against the day window (§8.5). Not sent
  /// on the wire — §9.4 takes only the two changed fields.
  final DateTime attendanceDate;

  /// New school-local sign-out, or `null` to leave it unchanged.
  final DateTime? signOutLocal;

  /// New reason, or `null` to leave it unchanged. When present it must be
  /// non-blank — an edit can replace the reason but never clear it (§8.2).
  final String? reason;

  /// True when this edit would actually change something. §9.4 rejects an
  /// empty patch, so the client should not send one.
  bool get hasChange => signOutLocal != null || reason != null;

  /// First failing rule, or `null` when the edit is submittable.
  ///
  /// Note the asymmetry with [RegRaiseInput.validate]: a *raise* always
  /// requires a reason, whereas an *edit* only validates the reason it was
  /// given — an edit that changes the time alone is legitimate and leaves the
  /// existing reason in place.
  String? validate({DateTime? signedInAt}) {
    if (!hasChange) return 'Change the time or the reason before saving.';
    if (reason != null) {
      final reasonError = RegTimePolicy.validateReason(reason);
      if (reasonError != null) return reasonError;
    }
    if (signOutLocal != null) {
      return RegTimePolicy.validateSignOut(
        signOutLocal: signOutLocal!,
        attendanceDate: attendanceDate,
        signedInAt: signedInAt,
      );
    }
    return null;
  }
}
