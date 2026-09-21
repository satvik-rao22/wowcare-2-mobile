import 'missed_signout.dart';

/// The gate response. The split is the point: [clear] staff sign in
/// immediately and are never held up by someone else's forgotten sign-out.
class RegBatchGate {
  const RegBatchGate({required this.blocked, required this.clear});

  const RegBatchGate.empty()
      : blocked = const <MissedSignout>[],
        clear = const <String>[];

  final List<MissedSignout> blocked;
  final List<String> clear;

  bool get hasBlocked => blocked.isNotEmpty;

  List<String> get blockedStaffCodes =>
      blocked.map((b) => b.staffCode).toList(growable: false);

  int get total => blocked.length + clear.length;
}
