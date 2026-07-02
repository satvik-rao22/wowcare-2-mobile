part of 'transactions_cubit.dart';

class TransactionsState extends Equatable {
  const TransactionsState({
    required this.transactions,
    required this.searchQuery,
    this.overview,
    this.dateFrom,
    this.dateTo,
    this.activeFilter,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.page = 0,
    this.errorMessage,
    this.successMessage,
  });

  const TransactionsState.initial()
      : transactions = const [],
        searchQuery = '',
        overview = null,
        dateFrom = null,
        dateTo = null,
        activeFilter = null,
        isLoading = true,
        isLoadingMore = false,
        hasMore = false,
        page = 0,
        errorMessage = null,
        successMessage = null;

  final List<TransactionRecord> transactions;
  final String searchQuery;

  /// True during the initial / refresh transactions fetch (drives the shimmer).
  final bool isLoading;

  /// True while the next page is being appended (infinite scroll).
  final bool isLoadingMore;

  /// Whether the backend has more transaction pages after [page].
  final bool hasMore;

  /// Zero-based index of the last loaded transactions page.
  final int page;

  /// Real billing totals from the overview API; null until loaded. When absent
  /// (not loaded yet or the request failed) the stat bar shows zeros.
  final InvoiceOverviewEntity? overview;

  final DateTime? dateFrom;
  final DateTime? dateTo;

  /// The summary-card filter currently scoping the Transactions list, or null
  /// when the unfiltered list is shown. Drives the legend highlight.
  final TransactionFilter? activeFilter;

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
    TransactionFilter? Function()? activeFilter,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? errorMessage,
    String? successMessage,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      searchQuery: searchQuery ?? this.searchQuery,
      overview: overview != null ? overview() : this.overview,
      dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
      dateTo: dateTo != null ? dateTo() : this.dateTo,
      activeFilter: activeFilter != null ? activeFilter() : this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
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
        activeFilter,
        isLoading,
        isLoadingMore,
        hasMore,
        page,
        errorMessage,
        successMessage,
      ];
}
