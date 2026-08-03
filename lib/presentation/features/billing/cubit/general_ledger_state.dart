part of 'general_ledger_cubit.dart';

class GeneralLedgerState extends Equatable {
  const GeneralLedgerState({
    required this.allLedgers,
    required this.selectedCategory,
    required this.searchQuery,
    required this.statusFilter,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.hasMore,
    required this.currentPage,
    required this.errorMessage,
  });

  GeneralLedgerState.initial()
      : allLedgers = const [],
        selectedCategory = null,
        searchQuery = '',
        statusFilter = 'ACTIVE',
        isLoading = false,
        isRefreshing = false,
        isLoadingMore = false,
        hasMore = true,
        currentPage = 0,
        errorMessage = null;

  final List<LedgerAccountModel> allLedgers;
  final String? selectedCategory;
  final String searchQuery;
  final String? statusFilter;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  // Category filtering is server-side; visibleLedgers is just allLedgers.
  List<LedgerAccountModel> get visibleLedgers => allLedgers;

  GeneralLedgerState copyWith({
    List<LedgerAccountModel>? allLedgers,
    String? Function()? selectedCategory,
    String? searchQuery,
    String? Function()? statusFilter,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? Function()? errorMessage,
  }) {
    return GeneralLedgerState(
      allLedgers: allLedgers ?? this.allLedgers,
      selectedCategory: selectedCategory != null ? selectedCategory() : this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        allLedgers, selectedCategory, searchQuery, statusFilter,
        isLoading, isRefreshing, isLoadingMore, hasMore, currentPage, errorMessage,
      ];
}
