part of 'parent_billing_cubit.dart';

class ParentBillingState extends Equatable {
  const ParentBillingState({
    required this.siblings,
    required this.transactions,
    required this.startDate,
    required this.endDate,
    required this.isInitialLoadingTransactions,
    required this.isPaymentLoading,
    required this.isAutoPayLoading,
  });

  const ParentBillingState.initial()
      : siblings = const [],
        transactions = const [],
        startDate = null,
        endDate = null,
        isInitialLoadingTransactions = false,
        isPaymentLoading = false,
        isAutoPayLoading = false;

  final List<Map<String, String>> siblings;
  final List<DemoTransaction> transactions;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isInitialLoadingTransactions;
  final bool isPaymentLoading;
  final bool isAutoPayLoading;

  /// Whether a date range is active.
  bool get hasDateRange => startDate != null && endDate != null;

  /// Transactions scoped to the active date range (if any), newest first.
  List<DemoTransaction> get filteredTransactions {
    Iterable<DemoTransaction> result = transactions;
    if (hasDateRange) {
      final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      result = transactions.where((txn) {
        final txnDate = DateTime(txn.date.year, txn.date.month, txn.date.day);
        return (txnDate.isAtSameMomentAs(start) || txnDate.isAfter(start)) &&
            (txnDate.isAtSameMomentAs(end) || txnDate.isBefore(end));
      });
    }
    return result.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  ParentBillingState copyWith({
    List<Map<String, String>>? siblings,
    List<DemoTransaction>? transactions,
    DateTime? startDate,
    DateTime? endDate,
    bool? isInitialLoadingTransactions,
    bool? isPaymentLoading,
    bool? isAutoPayLoading,
  }) {
    return ParentBillingState(
      siblings: siblings ?? this.siblings,
      transactions: transactions ?? this.transactions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isInitialLoadingTransactions:
          isInitialLoadingTransactions ?? this.isInitialLoadingTransactions,
      isPaymentLoading: isPaymentLoading ?? this.isPaymentLoading,
      isAutoPayLoading: isAutoPayLoading ?? this.isAutoPayLoading,
    );
  }

  @override
  List<Object?> get props => [
        siblings,
        transactions,
        startDate,
        endDate,
        isInitialLoadingTransactions,
        isPaymentLoading,
        isAutoPayLoading,
      ];
}
