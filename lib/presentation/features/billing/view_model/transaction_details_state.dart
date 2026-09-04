part of 'transaction_details_cubit.dart';

class TransactionDetailsState extends Equatable {
  const TransactionDetailsState({
    required this.siblingTransactions,
    required this.netPaidAmount,
    required this.amountUnpaid,
    required this.amountInProcess,
    required this.amountRefund,
    required this.openBalance,
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
        netPaidAmount = 0,
        amountUnpaid = 0,
        amountInProcess = 0,
        amountRefund = 0,
        openBalance = 0,
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
  final double netPaidAmount;
  final double amountUnpaid;
  final double amountInProcess;
  final double amountRefund;

  /// The family's outstanding balance (from the ledger), shown as the amount
  /// to collect in Receive Payment.
  final double openBalance;
  final bool isLoadingSiblings;
  final bool hasError;
  final String errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLoadingFamily;
  final List<BillingFamilyMember> familyChildren;
  final List<BillingFamilyMember> familyParents;
  final String familyName;
  final String familyError;
  final bool hasMoreData;
  final bool isLoadingMore;

  double get familyTotalInvoiced =>
      netPaidAmount + amountUnpaid + amountInProcess;

  TransactionDetailsState copyWith({
    List<TransactionItem>? siblingTransactions,
    double? netPaidAmount,
    double? amountUnpaid,
    double? amountInProcess,
    double? amountRefund,
    double? openBalance,
    bool? isLoadingSiblings,
    bool? hasError,
    String? errorMessage,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    bool? isLoadingFamily,
    List<BillingFamilyMember>? familyChildren,
    List<BillingFamilyMember>? familyParents,
    String? familyName,
    String? familyError,
    bool? hasMoreData,
    bool? isLoadingMore,
  }) {
    return TransactionDetailsState(
      siblingTransactions: siblingTransactions ?? this.siblingTransactions,
      netPaidAmount: netPaidAmount ?? this.netPaidAmount,
      amountUnpaid: amountUnpaid ?? this.amountUnpaid,
      amountInProcess: amountInProcess ?? this.amountInProcess,
      amountRefund: amountRefund ?? this.amountRefund,
      openBalance: openBalance ?? this.openBalance,
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
        netPaidAmount,
        amountUnpaid,
        amountInProcess,
        amountRefund,
        openBalance,
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
