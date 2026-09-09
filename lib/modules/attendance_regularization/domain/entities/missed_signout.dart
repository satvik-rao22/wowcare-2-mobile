import '../policy/reg_time_policy.dart';

/// An unresolved past day that blocks the next sign-in — the unit of
/// regularization.
///
/// One instance is one **`(staff, date)`** pair, evaluated on that day's
/// **last session** (§4). A staff may sign in and out many times in a day; the
/// gate looks only at the last of those sessions, so a day whose last session
/// was genuinely signed out by a human is clear even if an earlier session was
/// left open. Two shapes qualify as unresolved (§1):
///
/// * `status = SIGNED_IN` with no `signed_out_at` — still open, or
/// * `signed_out_method = SYSTEM` — the scheduler closed it on a guess, which
///   is not a staff-confirmed sign-out.
///
/// [staffCode] / [staffName] are only populated when an **admin** is looking at
/// someone else's open day — the bulk sign-in gate lists many staff at once
/// (§9.1b). For a staff resolving their own day they can be left empty.
///
/// Maps §9.1 (single) and the `blocked` items of §9.1b (batch).
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

  /// FK to `staff_attendance_record.code` (`STAR_…`) — the row being closed.
  final String attendanceCode;

  /// School-local calendar date being corrected.
  final DateTime attendanceDate;

  /// Sign-in of the day's last session. Bounds the correction (§8.5).
  final DateTime? signedInAt;

  final String? signedInByCode;

  /// Pre-fill for the sheet, **computed server-side per call and never
  /// stored** (§4, §7.5): the scheduler's own `signed_out_at` if it auto-closed
  /// the row, else the school's closing time for that weekday, else a 19:00
  /// local cap. Nullable — use [suggestedOrCap] rather than reading it raw.
  final DateTime? suggestedSignOutTime;

  /// Room of the open session, read from the target attendance row's
  /// `current_classroom_code` (§9.1). A code, not a display name.
  final String? classroomCode;

  /// True when a `PENDING` request already exists for [attendanceCode].
  ///
  /// Load-bearing: §8.3 allows sign-in once a request exists, so the gate must
  /// **not** block on this day again. Without it the staff would be pushed
  /// through a sheet they already completed every morning until an admin
  /// approves.
  final bool hasPendingRequest;

  /// The existing request's code, present when [hasPendingRequest] (§9.1).
  /// Lets the client go straight to **edit** (§9.4) instead of attempting a
  /// duplicate create.
  final String? pendingRequestCode;

  /// Whose day this is. Empty for a staff resolving their own (§9.1); set by
  /// the batch gate (§9.1b).
  final String staffCode;
  final String staffName;

  /// The time to pre-fill the sheet with, with §8.5's fallback applied.
  DateTime get suggestedOrCap =>
      RegTimePolicy.suggestedOr(suggestedSignOutTime, attendanceDate);

  /// True when this day should open the sheet in **edit** mode (§9.4) rather
  /// than create — a request exists and we know its code.
  bool get resolvesByEdit =>
      hasPendingRequest && (pendingRequestCode ?? '').isNotEmpty;

  /// True when this day still blocks sign-in (§8.3).
  bool get blocksSignIn => !hasPendingRequest;

  /// "Sara Malik" -> "SM"; falls back to "?" when no name is carried.
  String get initials {
    final parts = staffName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
