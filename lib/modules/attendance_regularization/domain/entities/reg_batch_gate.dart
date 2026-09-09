import 'missed_signout.dart';

/// Result of checking many staff for unresolved days in one call (§9.1b) —
/// the first step of an admin bulk sign-in.
///
/// The split is the whole point: [clear] staff are signed in **immediately**
/// and are never held up by someone else's forgotten sign-out, while [blocked]
/// staff go onto one consolidated sheet (§5.1c, §8.3 partial-success).
class RegBatchGate {
  const RegBatchGate({required this.blocked, required this.clear});

  const RegBatchGate.empty()
      : blocked = const <MissedSignout>[],
        clear = const <String>[];

  /// Staff with an unresolved past day — at most one entry per
  /// `(staff, date)` (§9.1b). Carries `staffName` so the sheet can list people
  /// without a second lookup.
  final List<MissedSignout> blocked;

  /// Staff codes that may be signed in right away.
  final List<String> clear;

  bool get hasBlocked => blocked.isNotEmpty;

  /// Staff codes of the blocked entries, in the same order.
  List<String> get blockedStaffCodes =>
      blocked.map((b) => b.staffCode).toList(growable: false);

  /// Everyone the batch knows about.
  int get total => blocked.length + clear.length;
}
