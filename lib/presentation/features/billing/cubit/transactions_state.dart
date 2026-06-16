part of 'transactions_cubit.dart';

class TransactionsState extends Equatable {
  const TransactionsState({
    required this.transactions,
    required this.searchQuery,
    this.overview,
    this.dateFrom,
    this.dateTo,
    this.errorMessage,
    this.successMessage,
  });

  TransactionsState.initial()
      : transactions = TransactionsCubit.seedTransactions(),
        searchQuery = '',
        overview = null,
        dateFrom = null,
        dateTo = null,
        errorMessage = null,
        successMessage = null;

  final List<TransactionRecord> transactions;
  final String searchQuery;

  /// Real billing totals from the overview API; null until loaded. When absent
  /// (not loaded yet or the request failed) the stat bar shows zeros.
  final InvoiceOverviewEntity? overview;

  final DateTime? dateFrom;
  final DateTime? dateTo;

  /// Last load error, surfaced as a top snackbar by the view.
  final String? errorMessage;

  /// One-shot success message (e.g. after cancel/delete), surfaced as a top
  /// snackbar by the view.
  final String? successMessage;

  List<TransactionRecord> get visibleTransactions {
    final query = searchQuery.trim().toLowerCase();
    return transactions.where((record) {
      final item = record.item;
      return query.isEmpty ||
          item.studentName.toLowerCase().contains(query) ||
          item.id.toString().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  // Live overview totals only; zeros when not loaded / on failure (never demo).
  double get totalInvoiced => overview?.amountInvoiced ?? 0;

  // Actual dollar amounts from the overview API (shown verbatim in the cards).
  double get netPaidAmount => overview?.netPaid ?? 0;
  double get paidAmount => overview?.paid ?? 0;
  double get refundedAmount => overview?.refunded ?? 0;
  double get inProcessAmount => overview?.inProcess ?? 0;
  double get outstandingAmount => overview?.outstanding ?? 0;

  /// "Net Paid" share of the invoiced amount.
  double get paidPercent => overview?.netPaidPercent ?? 0;

  /// Gross "Paid" share (before refunds) — shown in the expanded view.
  double get grossPaidPercent => overview?.paidPercent ?? 0;

  double get inProcessPercent => overview?.inProcessPercent ?? 0;

  double get unpaidPercent => overview?.outstandingPercent ?? 0;

  double get refundPercent => overview?.refundedPercent ?? 0;

  TransactionsState copyWith({
    List<TransactionRecord>? transactions,
    String? searchQuery,
    InvoiceOverviewEntity? Function()? overview,
    DateTime? Function()? dateFrom,
    DateTime? Function()? dateTo,
    String? errorMessage,
    String? successMessage,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      searchQuery: searchQuery ?? this.searchQuery,
      overview: overview != null ? overview() : this.overview,
      dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
      dateTo: dateTo != null ? dateTo() : this.dateTo,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        transactions,
        searchQuery,
        overview,
        dateFrom,
        dateTo,
        errorMessage,
        successMessage,
      ];
}
