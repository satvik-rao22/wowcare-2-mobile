part of 'student_cubit.dart';

class StudentState extends Equatable {
  static const Object _unset = Object();

  const StudentState({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.isFromCache,
    required this.searchQuery,
    this.statusFilter,
    this.codeFilter,
    this.firstNameFilter,
    this.lastNameFilter,
    this.classroomCodesFilter,
    this.tagCodesFilter,
    this.guardianCodesFilter,
    this.attendanceStatusesFilter,
    this.errorMessage,
  });

  const StudentState.initial()
    : items = const [],
      currentPage = 0,
      hasMore = true,
      isLoading = true,
      isRefreshing = false,
      isLoadingMore = false,
      isFromCache = false,
      searchQuery = '',
      statusFilter = 'ACTIVE',
      codeFilter = null,
      firstNameFilter = null,
      lastNameFilter = null,
      classroomCodesFilter = null,
      tagCodesFilter = null,
      guardianCodesFilter = null,
      attendanceStatusesFilter = null,
      errorMessage = null;

  final List<Student> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isFromCache;
  final String searchQuery;
  final String? statusFilter;
  final String? codeFilter;
  final String? firstNameFilter;
  final String? lastNameFilter;
  final List<String>? classroomCodesFilter;
  final List<String>? tagCodesFilter;
  final List<String>? guardianCodesFilter;
  final List<String>? attendanceStatusesFilter;
  final String? errorMessage;

  StudentState copyWith({
    List<Student>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isFromCache,
    String? searchQuery,
    Object? statusFilter = _unset,
    Object? codeFilter = _unset,
    Object? firstNameFilter = _unset,
    Object? lastNameFilter = _unset,
    Object? classroomCodesFilter = _unset,
    Object? tagCodesFilter = _unset,
    Object? guardianCodesFilter = _unset,
    Object? attendanceStatusesFilter = _unset,
    String? errorMessage,
  }) {
    return StudentState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isFromCache: isFromCache ?? this.isFromCache,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter == _unset
          ? this.statusFilter
          : statusFilter as String?,
      codeFilter: codeFilter == _unset
          ? this.codeFilter
          : codeFilter as String?,
      firstNameFilter: firstNameFilter == _unset
          ? this.firstNameFilter
          : firstNameFilter as String?,
      lastNameFilter: lastNameFilter == _unset
          ? this.lastNameFilter
          : lastNameFilter as String?,
      classroomCodesFilter: classroomCodesFilter == _unset
          ? this.classroomCodesFilter
          : classroomCodesFilter as List<String>?,
      tagCodesFilter: tagCodesFilter == _unset
          ? this.tagCodesFilter
          : tagCodesFilter as List<String>?,
      guardianCodesFilter: guardianCodesFilter == _unset
          ? this.guardianCodesFilter
          : guardianCodesFilter as List<String>?,
      attendanceStatusesFilter: attendanceStatusesFilter == _unset
          ? this.attendanceStatusesFilter
          : attendanceStatusesFilter as List<String>?,
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
    codeFilter,
    firstNameFilter,
    lastNameFilter,
    classroomCodesFilter,
    tagCodesFilter,
    guardianCodesFilter,
    attendanceStatusesFilter,
    errorMessage,
  ];
}
