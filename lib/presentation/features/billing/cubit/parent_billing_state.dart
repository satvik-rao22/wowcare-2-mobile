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
  });

  const ParentBillingState.initial()
      : isLoading = false,
        isPaymentLoading = false,
        isAutoPayLoading = false,
        displayCount = 10,
        ledger = null,
        errorMessage = null,
        startDate = null,
        endDate = null;

  final bool isLoading;
  final bool isPaymentLoading;
  final bool isAutoPayLoading;

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
    return result.toList()
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });
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
      ];
}
