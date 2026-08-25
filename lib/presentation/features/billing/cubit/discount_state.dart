part of 'discount_cubit.dart';

class DiscountState extends Equatable {
  const DiscountState({
    required this.allDiscounts,
    required this.searchQuery,
    required this.statusFilter,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.currentPage,
    required this.errorMessage,
  });

  DiscountState.initial()
    : allDiscounts = const [],
      searchQuery = '',
      statusFilter = 'ACTIVE',
      isLoading = false,
      isLoadingMore = false,
      hasMore = true,
      currentPage = 0,
      errorMessage = null;

  final List<DiscountAccountModel> allDiscounts;
  final String searchQuery;
  final String? statusFilter;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  /// Client-side name search over whatever's currently loaded — the backend
  /// `name` query param on this endpoint doesn't actually filter results, so
  /// search is applied here instead of relying on the API.
  List<DiscountAccountModel> get filteredDiscounts {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return allDiscounts;
    return allDiscounts.where((d) => d.name.toLowerCase().contains(q)).toList();
  }

  DiscountState copyWith({
    List<DiscountAccountModel>? allDiscounts,
    String? searchQuery,
    String? Function()? statusFilter,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? Function()? errorMessage,
  }) {
    return DiscountState(
      allDiscounts: allDiscounts ?? this.allDiscounts,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    allDiscounts,
    searchQuery,
    statusFilter,
    isLoading,
    isLoadingMore,
    hasMore,
    currentPage,
    errorMessage,
  ];
}
