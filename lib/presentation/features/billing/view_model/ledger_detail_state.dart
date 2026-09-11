part of 'ledger_detail_cubit.dart';

class LedgerDetailState extends Equatable {
  const LedgerDetailState({
    required this.transactions,
    required this.isLoading,
    required this.isLoadingMore,
    required this.isAddingTransaction,
    required this.hasMore,
    required this.currentPage,
    required this.totalElements,
    required this.pageSize,
    required this.numberOfElements,
    required this.fromDate,
    required this.toDate,
    required this.errorMessage,
    this.ledger,
    this.isLoadingLedger = false,
  });

  LedgerDetailState.initial()
      : transactions = const [],
        isLoading = false,
        isLoadingMore = false,
        isAddingTransaction = false,
        hasMore = true,
        currentPage = 0,
        totalElements = 0,
        pageSize = 10,
        numberOfElements = 0,
        fromDate = null,
        toDate = null,
        errorMessage = null,
        ledger = null,
        isLoadingLedger = false;

  final List<LedgerTransactionEntity> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isAddingTransaction;
  final bool hasMore;
  final int currentPage;
  final int totalElements;
  final int pageSize;
  final int numberOfElements;
  final String? fromDate;
  final String? toDate;
  final String? errorMessage;
  final LedgerAccountModel? ledger;
  final bool isLoadingLedger;

  bool get hasError => errorMessage != null;

  // "Showing X to Y of Z entries"
  int get fromEntry =>
      totalElements == 0 ? 0 : currentPage * pageSize + 1;
  int get toEntry => currentPage * pageSize + numberOfElements;

  LedgerDetailState copyWith({
    List<LedgerTransactionEntity>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isAddingTransaction,
    bool? hasMore,
    int? currentPage,
    int? totalElements,
    int? pageSize,
    int? numberOfElements,
    String? Function()? fromDate,
    String? Function()? toDate,
    String? Function()? errorMessage,
    LedgerAccountModel? ledger,
    bool? isLoadingLedger,
  }) {
    return LedgerDetailState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isAddingTransaction: isAddingTransaction ?? this.isAddingTransaction,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalElements: totalElements ?? this.totalElements,
      pageSize: pageSize ?? this.pageSize,
      numberOfElements: numberOfElements ?? this.numberOfElements,
      fromDate: fromDate != null ? fromDate() : this.fromDate,
      toDate: toDate != null ? toDate() : this.toDate,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      ledger: ledger ?? this.ledger,
      isLoadingLedger: isLoadingLedger ?? this.isLoadingLedger,
    );
  }

  @override
  List<Object?> get props => [
        transactions,
        isLoading,
        isLoadingMore,
        isAddingTransaction,
        hasMore,
        currentPage,
        totalElements,
        pageSize,
        numberOfElements,
        fromDate,
        toDate,
        errorMessage,
        ledger,
        isLoadingLedger,
      ];
}
