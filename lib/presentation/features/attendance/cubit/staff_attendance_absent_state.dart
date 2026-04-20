part of 'staff_attendance_absent_cubit.dart';

class StaffAttendanceAbsentState extends Equatable {
  const StaffAttendanceAbsentState({
    required this.items,
    required this.isLoading,
    required this.isRefreshing,
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

  const StaffAttendanceAbsentState.initial()
      : items = const [],
        isLoading = false,
        isRefreshing = false,
        currentPage = 0,
        hasMore = false,
        isLoadingMore = false,
        errorMessage = null,
        fromDate = null,
        toDate = null,
        classroomCodes = null,
        tagCodes = null,
        search = null;

  const StaffAttendanceAbsentState.loaded({
    required List<StaffAttendanceAbsentItem> items,
    this.currentPage = 0,
    this.hasMore = false,
    required DateTime fromDate,
    required DateTime toDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  })  : items = items,
        isLoading = false,
        isRefreshing = false,
        isLoadingMore = false,
        errorMessage = null,
        fromDate = fromDate,
        toDate = toDate,
        classroomCodes = classroomCodes,
        tagCodes = tagCodes,
        search = search;

  final List<StaffAttendanceAbsentItem> items;
  final bool isLoading;
  final bool isRefreshing;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<String>? classroomCodes;
  final List<String>? tagCodes;
  final String? search;

  StaffAttendanceAbsentState copyWith({
    List<StaffAttendanceAbsentItem>? items,
    bool? isLoading,
    bool? isRefreshing,
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
    return StaffAttendanceAbsentState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
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

