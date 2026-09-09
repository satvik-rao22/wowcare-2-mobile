/// One item a batch write declined to act on.
///
/// [key] is whatever identified the item in the request — an `attendanceCode`
/// for a batch raise (§9.2b), an `SREG_…` code for bulk approve (§9.7).
class RegSkipped {
  const RegSkipped({required this.key, required this.reason});

  final String key;

  /// Server-supplied explanation, e.g. "already resolved" / "already decided".
  final String reason;
}

/// Outcome of a batch write. §9.2b and §9.7 return the same shape — a count of
/// what succeeded plus the items that were **skipped rather than errored** —
/// so one type covers both.
///
/// Skipping instead of failing is deliberate (§10.3): these operations are
/// idempotent and snapshot-based, so an item another admin already handled is
/// a normal outcome, not a failure of the batch.
class RegBatchResult {
  const RegBatchResult({required this.count, required this.skipped});

  const RegBatchResult.empty()
      : count = 0,
        skipped = const <RegSkipped>[];

  /// `applied` in §9.2b, `approved` in §9.7.
  final int count;

  final List<RegSkipped> skipped;

  bool get hasSkipped => skipped.isNotEmpty;

  /// True when every item was skipped — nothing changed.
  bool get isNoop => count == 0;

  /// The keys that were skipped, for reconciling an optimistic list.
  Set<String> get skippedKeys =>
      skipped.map((s) => s.key).toSet();

  /// One-line summary for a snackbar. Names how many were skipped and why,
  /// which §9.7's UI requirement asks for.
  String get summary {
    if (skipped.isEmpty) return '$count approved';
    final reason = skipped.first.reason;
    final allSame = skipped.every((s) => s.reason == reason);
    final why = allSame ? ' — $reason' : '';
    return '$count approved · ${skipped.length} skipped$why';
  }
}
