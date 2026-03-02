part of 'staff_attendance_daily_cubit.dart';

class StaffAttendanceDailyState extends Equatable {
  const StaffAttendanceDailyState({
    required this.items,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    this.currentPage = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.attendanceDate,
    this.classroomCodes,
    this.tagCodes,
    this.search,
  });

  const StaffAttendanceDailyState.initial()
      : items = const [],
        isLoading = false,
        isRefreshing = false,
        isFromCache = false,
        currentPage = 0,
        hasMore = false,
        isLoadingMore = false,
        errorMessage = null,
        attendanceDate = null,
        classroomCodes = null,
        tagCodes = null,
        search = null;

  const StaffAttendanceDailyState.loaded({
    required List<StaffAttendanceDailyItem> items,
    required bool isFromCache,
    this.currentPage = 0,
    this.hasMore = false,
    required DateTime attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  })  : items = items,
        isLoading = false,
        isRefreshing = false,
        isFromCache = isFromCache,
        isLoadingMore = false,
        errorMessage = null,
        attendanceDate = attendanceDate,
        classroomCodes = classroomCodes,
        tagCodes = tagCodes,
        search = search;

  final List<StaffAttendanceDailyItem> items;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;
  final DateTime? attendanceDate;
  final List<String>? classroomCodes;
  final List<String>? tagCodes;
  final String? search;

  StaffAttendanceDailyState copyWith({
    List<StaffAttendanceDailyItem>? items,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFromCache,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
    DateTime? attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) {
    return StaffAttendanceDailyState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      attendanceDate: attendanceDate ?? this.attendanceDate,
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
        attendanceDate,
        classroomCodes,
        tagCodes,
        search,
      ];
}

