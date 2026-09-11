part of 'staff_cubit.dart';

class StaffState extends Equatable {
  const StaffState({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    required this.staffCountTotal,
    required this.staffCountActive,
    required this.staffCountUpcoming,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.isFromCache,
    required this.searchQuery,
    required this.statusFilter,
    required this.designationFilter,
    required this.primaryClassroomCodes,
    required this.classCodes,
    required this.sortBy,
    required this.attendanceStatuses,
    required this.errorMessage,
  });

  const StaffState.initial()
    : items = const [],
      currentPage = 0,
      hasMore = true,
      staffCountTotal = 0,
      staffCountActive = 0,
      staffCountUpcoming = 0,
      isLoading = true,
      isRefreshing = false,
      isLoadingMore = false,
      isFromCache = false,
      searchQuery = '',
      statusFilter = null,
      designationFilter = null,
      primaryClassroomCodes = null,
      classCodes = null,
      sortBy = 'desc',
      attendanceStatuses = null,
      errorMessage = null;

  final List<StaffMember> items;
  final int currentPage;
  final bool hasMore;
  final int staffCountTotal;
  final int staffCountActive;
  final int staffCountUpcoming;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isFromCache;
  final String searchQuery;
  final String? statusFilter;
  final String? designationFilter;
  final List<String>? primaryClassroomCodes;
  final List<String>? classCodes;
  final String? sortBy;
  final List<String>? attendanceStatuses;
  final String? errorMessage;

  StaffState copyWith({
    List<StaffMember>? items,
    int? currentPage,
    bool? hasMore,
    int? staffCountTotal,
    int? staffCountActive,
    int? staffCountUpcoming,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isFromCache,
    String? searchQuery,
    String? statusFilter,
    String? designationFilter,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
    List<String>? attendanceStatuses,
    String? errorMessage,
  }) {
    return StaffState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      staffCountTotal: staffCountTotal ?? this.staffCountTotal,
      staffCountActive: staffCountActive ?? this.staffCountActive,
      staffCountUpcoming: staffCountUpcoming ?? this.staffCountUpcoming,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isFromCache: isFromCache ?? this.isFromCache,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      designationFilter: designationFilter ?? this.designationFilter,
      // Treat null as "don't change"; treat empty list as "clear" (set to null)
      primaryClassroomCodes: primaryClassroomCodes == null
          ? this.primaryClassroomCodes
          : (primaryClassroomCodes.isEmpty ? null : primaryClassroomCodes),
      classCodes: classCodes == null
          ? this.classCodes
          : (classCodes.isEmpty ? null : classCodes),
      sortBy: sortBy ?? this.sortBy,
      attendanceStatuses: attendanceStatuses == null
          ? this.attendanceStatuses
          : (attendanceStatuses.isEmpty ? null : attendanceStatuses),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    items,
    currentPage,
    hasMore,
    staffCountTotal,
    staffCountActive,
    staffCountUpcoming,
    isLoading,
    isRefreshing,
    isLoadingMore,
    isFromCache,
    searchQuery,
    statusFilter,
    designationFilter,
    primaryClassroomCodes,
    classCodes,
    sortBy,
    attendanceStatuses,
    errorMessage,
  ];
}
