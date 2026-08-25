part of 'transaction_details_cubit.dart';

class TransactionDetailsState extends Equatable {
  const TransactionDetailsState({
    required this.siblingTransactions,
    required this.siblingSummary,
    required this.isLoadingSiblings,
    required this.hasError,
    required this.errorMessage,
    required this.startDate,
    required this.endDate,
    required this.isLoadingFamily,
    required this.familyChildren,
    required this.familyParents,
    required this.familyName,
    required this.familyError,
    required this.hasMoreData,
    required this.isLoadingMore,
  });

  const TransactionDetailsState.initial()
    : siblingTransactions = const [],
      siblingSummary = const {},
      isLoadingSiblings = false,
      hasError = false,
      errorMessage = '',
      startDate = null,
      endDate = null,
      isLoadingFamily = false,
      familyChildren = const [],
      familyParents = const [],
      familyName = '',
      familyError = '',
      hasMoreData = false,
      isLoadingMore = false;

  final List<TransactionItem> siblingTransactions;
  final Map<String, dynamic> siblingSummary;
  final bool isLoadingSiblings;
  final bool hasError;
  final String errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLoadingFamily;
  final List<Map<String, dynamic>> familyChildren;
  final List<Map<String, dynamic>> familyParents;
  final String familyName;
  final String familyError;
  final bool hasMoreData;
  final bool isLoadingMore;

  double summaryDouble(String key) {
    final value = siblingSummary[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double get netPaidAmount => summaryDouble('netAmountPaid');
  double get amountUnpaid => summaryDouble('amountUnpaid');
  double get amountInProcess => summaryDouble('amountInProcess');
  double get amountRefund => summaryDouble('amountRefund');

  /// The family's outstanding balance (from the ledger), shown as the amount
  /// to collect in Receive Payment.
  double get openBalance => summaryDouble('openBalance');
  double get familyTotalInvoiced =>
      netPaidAmount + amountUnpaid + amountInProcess;

  TransactionDetailsState copyWith({
    List<TransactionItem>? siblingTransactions,
    Map<String, dynamic>? siblingSummary,
    bool? isLoadingSiblings,
    bool? hasError,
    String? errorMessage,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    bool? isLoadingFamily,
    List<Map<String, dynamic>>? familyChildren,
    List<Map<String, dynamic>>? familyParents,
    String? familyName,
    String? familyError,
    bool? hasMoreData,
    bool? isLoadingMore,
  }) {
    return TransactionDetailsState(
      siblingTransactions: siblingTransactions ?? this.siblingTransactions,
      siblingSummary: siblingSummary ?? this.siblingSummary,
      isLoadingSiblings: isLoadingSiblings ?? this.isLoadingSiblings,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      startDate: startDate != null ? startDate() : this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      isLoadingFamily: isLoadingFamily ?? this.isLoadingFamily,
      familyChildren: familyChildren ?? this.familyChildren,
      familyParents: familyParents ?? this.familyParents,
      familyName: familyName ?? this.familyName,
      familyError: familyError ?? this.familyError,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    siblingTransactions,
    siblingSummary,
    isLoadingSiblings,
    hasError,
    errorMessage,
    startDate,
    endDate,
    isLoadingFamily,
    familyChildren,
    familyParents,
    familyName,
    familyError,
    hasMoreData,
    isLoadingMore,
  ];
}
