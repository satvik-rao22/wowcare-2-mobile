part of 'transactions_cubit.dart';

class TransactionsState extends Equatable {
  const TransactionsState({
    required this.transactions,
    required this.searchQuery,
    required this.page,
    required this.hasMore,
    required this.isLoadingList,
    required this.isLoadingMore,
    this.overview,
    this.dateFrom,
    this.dateTo,
    this.errorMessage,
    this.successMessage,
  });

  const TransactionsState.initial()
      : transactions = const <TransactionRecord>[],
        searchQuery = '',
        page = 0,
        hasMore = false,
        isLoadingList = false,
        isLoadingMore = false,
        overview = null,
        dateFrom = null,
        dateTo = null,
        errorMessage = null,
        successMessage = null;

  final List<TransactionRecord> transactions;
  final String searchQuery;

  /// Last loaded 0-indexed page of the invoice list.
  final int page;

  /// Whether more pages are available to [TransactionsCubit.loadNextPage].
  final bool hasMore;

  /// True while page 0 (initial / refresh / search) is loading.
  final bool isLoadingList;

  /// True while a subsequent page is being appended.
  final bool isLoadingMore;

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

  /// Search is performed server-side, so the loaded rows are already filtered.
  List<TransactionRecord> get visibleTransactions => transactions;

  // Live overview totals only; zeros when not loaded / on failure (never demo).
  double get totalInvoiced => overview?.amountInvoiced ?? 0;

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
    int? page,
    bool? hasMore,
    bool? isLoadingList,
    bool? isLoadingMore,
    InvoiceOverviewEntity? Function()? overview,
    DateTime? Function()? dateFrom,
    DateTime? Function()? dateTo,
    String? errorMessage,
    String? successMessage,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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
        page,
        hasMore,
        isLoadingList,
        isLoadingMore,
        overview,
        dateFrom,
        dateTo,
        errorMessage,
        successMessage,
      ];
}
