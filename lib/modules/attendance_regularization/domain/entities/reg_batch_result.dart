/// An item a batch declined to act on. Skipped, not failed, so a retry after a
/// dropped connection converges.
class RegSkipped {
  const RegSkipped({
    required this.reason,
    this.code = '',
    this.attendanceCode = '',
  });

  /// The `SREG_…` code, when the server knew one.
  final String code;

  /// The attendance row the item targeted.
  final String attendanceCode;

  /// e.g. "already resolved" / "already decided".
  final String reason;

  /// Whichever identifier the caller sent, for reconciling its own list.
  String get key => code.isNotEmpty ? code : attendanceCode;
}

/// Result of `raise-batch` or `approve-selected`. Always
/// `applied + skipped.length == items.length`.
class RegBatchResult {
  const RegBatchResult({required this.applied, required this.skipped});

  const RegBatchResult.empty() : applied = 0, skipped = const <RegSkipped>[];

  final int applied;
  final List<RegSkipped> skipped;

  bool get hasSkipped => skipped.isNotEmpty;
  bool get isNoop => applied == 0;

  Set<String> get skippedKeys => skipped.map((s) => s.key).toSet();

  Set<String> get skippedCodes =>
      skipped.where((s) => s.code.isNotEmpty).map((s) => s.code).toSet();

  Set<String> get skippedAttendanceCodes => skipped
      .where((s) => s.attendanceCode.isNotEmpty)
      .map((s) => s.attendanceCode)
      .toSet();

  String get summary {
    if (skipped.isEmpty) return '$applied approved';
    final reason = skipped.first.reason;
    final allSame = skipped.every((s) => s.reason == reason);
    return '$applied approved · ${skipped.length} skipped'
        '${allSame ? ' — $reason' : ''}';
  }
}
