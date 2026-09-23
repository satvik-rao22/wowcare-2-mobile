part of 'parent_billing_cubit.dart';

class ParentBillingState extends Equatable {
  const ParentBillingState({
    required this.isLoading,
    required this.isPaymentLoading,
    required this.isAutoPayLoading,
    required this.displayCount,
    this.ledger,
    this.errorMessage,
    this.startDate,
    this.endDate,
    this.autoPayBlocked = false,
  });

  const ParentBillingState.initial()
      : isLoading = false,
        isPaymentLoading = false,
        isAutoPayLoading = false,
        displayCount = 10,
        ledger = null,
        errorMessage = null,
        startDate = null,
        endDate = null,
        autoPayBlocked = false;

  final bool isLoading;
  final bool isPaymentLoading;
  final bool isAutoPayLoading;

  /// AutoPay is on but the school no longer accepts the method it's set up
  /// to use — see [AutoPayMethodsState.autoPayBlocked] for the same check on
  /// the AutoPay screen itself. Refreshed alongside the ledger (initial load
  /// and pull-to-refresh) so this banner never goes stale.
  final bool autoPayBlocked;

  /// How many transactions to show (client-side pagination).
  final int displayCount;

  final FamilyLedgerEntity? ledger;
  final String? errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get hasDateRange => startDate != null && endDate != null;
  double get openBalance => ledger?.openBalance ?? 0;
  double get paid => ledger?.paid ?? 0;
  double get refunded => ledger?.refunded ?? 0;
  double get netPaid => ledger?.netPaid ?? 0;
  double get inProcess => ledger?.inProcess ?? 0;
  double get unpaid => ledger?.unpaid ?? 0;
  List<FamilyLedgerPersonEntity> get students =>
      ledger?.students ?? const [];

  List<FamilyLedgerTransactionEntity> get filteredTransactions {
    final txns = ledger?.transactions ?? const [];
    Iterable<FamilyLedgerTransactionEntity> result = txns;
    if (hasDateRange) {
      final start =
          DateTime(startDate!.year, startDate!.month, startDate!.day);
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      result = txns.where((t) {
        if (t.date == null) return false;
        final d = DateTime(t.date!.year, t.date!.month, t.date!.day);
        return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
            (d.isAtSameMomentAs(end) || d.isBefore(end));
      });
    }
    // Preserve the API order (already newest-first by createdAt). We must NOT
    // re-sort by `date`, because payments carry a date-only `…T00:00:00Z` value
    // that would wrongly sort them below same-day invoices even though they were
    // created later.
    return result.toList();
  }

  /// Transactions visible in the current page window.
  List<FamilyLedgerTransactionEntity> get visibleTransactions =>
      filteredTransactions.take(displayCount).toList();

  /// Whether there are more transactions beyond the current page window.
  bool get hasMoreTransactions => filteredTransactions.length > displayCount;

  ParentBillingState copyWith({
    bool? isLoading,
    bool? isPaymentLoading,
    bool? isAutoPayLoading,
    int? displayCount,
    FamilyLedgerEntity? Function()? ledger,
    String? Function()? errorMessage,
    DateTime? startDate,
    DateTime? endDate,
    bool? autoPayBlocked,
  }) {
    return ParentBillingState(
      isLoading: isLoading ?? this.isLoading,
      isPaymentLoading: isPaymentLoading ?? this.isPaymentLoading,
      isAutoPayLoading: isAutoPayLoading ?? this.isAutoPayLoading,
      displayCount: displayCount ?? this.displayCount,
      ledger: ledger != null ? ledger() : this.ledger,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      autoPayBlocked: autoPayBlocked ?? this.autoPayBlocked,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isPaymentLoading,
        isAutoPayLoading,
        displayCount,
        ledger,
        errorMessage,
        startDate,
        endDate,
        autoPayBlocked,
      ];
}
