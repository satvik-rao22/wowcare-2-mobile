/// Result of gating a single sign-in.
enum RegGateOutcome {
  /// Nothing unresolved, or the request was raised — let the sign-in through.
  proceed,

  /// The person dismissed a mandatory sheet, so the sign-in must not happen.
  blocked;

  bool get isProceed => this == RegGateOutcome.proceed;
  bool get isBlocked => this == RegGateOutcome.blocked;
}

/// Result of gating a **bulk** sign-in (spec §5.1c, §8.3).
///
/// [allowed] is the point of the whole type: bulk sign-in is partial-success,
/// never all-or-nothing. The interceptor narrows the outgoing payload to these
/// staff instead of failing the request, so 40 people are never held up
/// because 10 forgot to sign out.
class RegBulkGateOutcome {
  const RegBulkGateOutcome({
    required this.allowed,
    this.cleared = 0,
    this.skipped = 0,
    this.blockedRemaining = 0,
  });

  const RegBulkGateOutcome.allowAll(List<String> staffCodes)
      : allowed = staffCodes,
        cleared = 0,
        skipped = 0,
        blockedRemaining = 0;

  /// Staff codes that may be signed in now.
  final List<String> allowed;

  /// How many blocked staff were resolved by this pass.
  final int cleared;

  /// How many the server skipped as already resolved (§9.2b).
  final int skipped;

  /// How many are still blocked — the admin chose Skip, so they keep their
  /// gate for next time (§5.1c step 3).
  final int blockedRemaining;

  /// True when nobody can be signed in, so the request should be rejected
  /// rather than sent with an empty list.
  bool get isEmpty => allowed.isEmpty;

  /// A one-line summary for a snackbar, or `null` when nothing noteworthy
  /// happened (a plain sign-in needs no commentary).
  String? get summary {
    final parts = <String>[
      if (cleared > 0) '$cleared day${cleared == 1 ? '' : 's'} closed',
      if (skipped > 0) '$skipped already resolved',
      if (blockedRemaining > 0) '$blockedRemaining still need closing',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
