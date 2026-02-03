part of 'staff_cubit.dart';

class StaffState extends Equatable {
  const StaffState({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.isFromCache,
    required this.searchQuery,
    required this.statusFilter,
    required this.designationFilter,
    required this.errorMessage,
  });

  const StaffState.initial()
      : items = const [],
        currentPage = 0,
        hasMore = true,
        isLoading = true,
        isRefreshing = false,
        isLoadingMore = false,
        isFromCache = false,
        searchQuery = '',
        statusFilter = null,
        designationFilter = null,
        errorMessage = null;

  final List<StaffMember> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isFromCache;
  final String searchQuery;
  final String? statusFilter;
  final String? designationFilter;
  final String? errorMessage;

  StaffState copyWith({
    List<StaffMember>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isFromCache,
    String? searchQuery,
    String? statusFilter,
    String? designationFilter,
    String? errorMessage,
  }) {
    return StaffState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isFromCache: isFromCache ?? this.isFromCache,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      designationFilter: designationFilter ?? this.designationFilter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        currentPage,
        hasMore,
        isLoading,
        isRefreshing,
        isLoadingMore,
        isFromCache,
        searchQuery,
        statusFilter,
        designationFilter,
        errorMessage,
      ];
}


