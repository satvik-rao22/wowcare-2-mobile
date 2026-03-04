part of 'student_cubit.dart';

class StudentState extends Equatable {
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
    String? statusFilter,
    String? codeFilter,
    String? firstNameFilter,
    String? lastNameFilter,
    List<String>? classroomCodesFilter,
    List<String>? tagCodesFilter,
    List<String>? guardianCodesFilter,
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
      statusFilter: statusFilter ?? this.statusFilter,
      codeFilter: codeFilter ?? this.codeFilter,
      firstNameFilter: firstNameFilter ?? this.firstNameFilter,
      lastNameFilter: lastNameFilter ?? this.lastNameFilter,
      classroomCodesFilter: classroomCodesFilter ?? this.classroomCodesFilter,
      tagCodesFilter: tagCodesFilter ?? this.tagCodesFilter,
      guardianCodesFilter: guardianCodesFilter ?? this.guardianCodesFilter,
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
        errorMessage,
      ];
}

