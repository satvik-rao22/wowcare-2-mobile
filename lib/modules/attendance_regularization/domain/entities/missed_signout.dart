import '../policy/reg_time_policy.dart';

/// An unresolved past day — one `(staff, date)` pair, evaluated on that day's
/// last session. Either still open, or closed by the scheduler on a guess.
///
/// [staffCode] / [staffName] are only populated when someone is looking at
/// another person's day, which is how the bulk gate lists a roster.
class MissedSignout {
  const MissedSignout({
    required this.attendanceCode,
    required this.attendanceDate,
    this.signedInAt,
    this.signedInByCode,
    this.suggestedSignOutTime,
    this.classroomCode,
    this.hasPendingRequest = false,
    this.pendingRequestCode,
    this.staffCode = '',
    this.staffName = '',
  });

  final String attendanceCode;
  final DateTime attendanceDate;
  final DateTime? signedInAt;
  final String? signedInByCode;

  /// Computed server-side per call, never stored.
  final DateTime? suggestedSignOutTime;

  final String? classroomCode;

  /// Sign-in is allowed once a request exists, so this stops the gate
  /// re-prompting someone who already raised.
  final bool hasPendingRequest;

  final String? pendingRequestCode;
  final String staffCode;
  final String staffName;

  DateTime get suggestedOrCap =>
      RegTimePolicy.suggestedOr(suggestedSignOutTime, attendanceDate);

  /// Open the sheet in edit mode rather than attempting a duplicate create.
  bool get resolvesByEdit =>
      hasPendingRequest && (pendingRequestCode ?? '').isNotEmpty;

  bool get blocksSignIn => !hasPendingRequest;

  String get initials {
    final parts = staffName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
