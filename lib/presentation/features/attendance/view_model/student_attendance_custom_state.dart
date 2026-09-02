part of 'student_attendance_custom_cubit.dart';

class StudentAttendanceCustomState extends Equatable {
  const StudentAttendanceCustomState({
    required this.items,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    this.currentPage = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.fromDate,
    this.toDate,
    this.classroomCodes,
    this.tagCodes,
    this.search,
  });

  const StudentAttendanceCustomState.initial()
    : items = const [],
      isLoading = false,
      isRefreshing = false,
      isFromCache = false,
      currentPage = 0,
      hasMore = false,
      isLoadingMore = false,
      errorMessage = null,
      fromDate = null,
      toDate = null,
      classroomCodes = null,
      tagCodes = null,
      search = null;

  const StudentAttendanceCustomState.loaded({
    required List<StudentAttendanceCustomItem> items,
    required bool isFromCache,
    this.currentPage = 0,
    this.hasMore = false,
    required DateTime fromDate,
    required DateTime toDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) : items = items,
       isLoading = false,
       isRefreshing = false,
       isFromCache = isFromCache,
       isLoadingMore = false,
       errorMessage = null,
       fromDate = fromDate,
       toDate = toDate,
       classroomCodes = classroomCodes,
       tagCodes = tagCodes,
       search = search;

  final List<StudentAttendanceCustomItem> items;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<String>? classroomCodes;
  final List<String>? tagCodes;
  final String? search;

  StudentAttendanceCustomState copyWith({
    List<StudentAttendanceCustomItem>? items,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFromCache,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) {
    return StudentAttendanceCustomState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      classroomCodes: classroomCodes ?? this.classroomCodes,
      tagCodes: tagCodes ?? this.tagCodes,
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [
    items,
    isLoading,
    isRefreshing,
    isFromCache,
    currentPage,
    hasMore,
    isLoadingMore,
    errorMessage,
    fromDate,
    toDate,
    classroomCodes,
    tagCodes,
    search,
  ];
}
