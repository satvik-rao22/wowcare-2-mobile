import '../policy/reg_time_policy.dart';
import 'missed_signout.dart';

/// What the client submits to raise a request — one item of §9.2, or one entry
/// of the §9.2b batch.
///
/// [signOutLocal] carries **wall-clock school-local** fields; the repository
/// converts it to UTC and sends `timeZone` alongside (§10.1). Keeping it local
/// here means nothing in the domain has to know about timezones.
///
/// There is no `confirmedSuggestedTime`: the server no longer tracks whether
/// the pre-filled suggestion was kept (§7.5), and `reason` is required either
/// way (§8.2).
class RegRaiseInput {
  const RegRaiseInput({
    required this.staffCode,
    required this.attendanceCode,
    required this.attendanceDate,
    required this.signOutLocal,
    required this.reason,
  });

  /// Builds an input from a gate item the sheet was opened on, so callers
  /// cannot mismatch the codes and the date.
  factory RegRaiseInput.forGate(
    MissedSignout item, {
    required String signOutStaffCode,
    required DateTime signOutLocal,
    required String reason,
  }) {
    return RegRaiseInput(
      staffCode: item.staffCode.isNotEmpty ? item.staffCode : signOutStaffCode,
      attendanceCode: item.attendanceCode,
      attendanceDate: item.attendanceDate,
      signOutLocal: signOutLocal,
      reason: reason,
    );
  }

  final String staffCode;
  final String attendanceCode;
  final DateTime attendanceDate;

  /// School-local wall-clock sign-out being requested.
  final DateTime signOutLocal;

  /// Mandatory, non-blank (§8.2).
  final String reason;

  /// First failing rule (§8.2, §8.5), or `null` when the input is submittable.
  ///
  /// Pass [signedInAt] to enforce "after sign-in", and [cap] when the school's
  /// real working-hours end is known.
  String? validate({DateTime? signedInAt, DateTime? cap}) {
    return RegTimePolicy.validateReason(reason) ??
        RegTimePolicy.validateSignOut(
          signOutLocal: signOutLocal,
          attendanceDate: attendanceDate,
          signedInAt: signedInAt,
          cap: cap,
        );
  }

  RegRaiseInput copyWith({DateTime? signOutLocal, String? reason}) {
    return RegRaiseInput(
      staffCode: staffCode,
      attendanceCode: attendanceCode,
      attendanceDate: attendanceDate,
      signOutLocal: signOutLocal ?? this.signOutLocal,
      reason: reason ?? this.reason,
    );
  }
}
