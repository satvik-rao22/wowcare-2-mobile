part of 'student_attendance_absent_toggle_cubit.dart';

class StudentAttendanceAbsentToggleState extends Equatable {
  const StudentAttendanceAbsentToggleState({
    required this.items,
    required this.isLoading,
    required this.isRefreshing,
    this.currentPage = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.absenceDate,
    this.classroomCodes,
    this.tagCodes,
    this.search,
  });

  const StudentAttendanceAbsentToggleState.initial()
      : items = const [],
        isLoading = false,
        isRefreshing = false,
        currentPage = 0,
        hasMore = false,
        isLoadingMore = false,
        errorMessage = null,
        absenceDate = null,
        classroomCodes = null,
        tagCodes = null,
        search = null;

  const StudentAttendanceAbsentToggleState.loaded({
    required List<StudentAttendanceAbsentFormItem> items,
    this.currentPage = 0,
    this.hasMore = false,
    required DateTime absenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  })  : items = items,
        isLoading = false,
        isRefreshing = false,
        isLoadingMore = false,
        errorMessage = null,
        absenceDate = absenceDate,
        classroomCodes = classroomCodes,
        tagCodes = tagCodes,
        search = search;

  final List<StudentAttendanceAbsentFormItem> items;
  final bool isLoading;
  final bool isRefreshing;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;
  final DateTime? absenceDate;
  final List<String>? classroomCodes;
  final List<String>? tagCodes;
  final String? search;

  StudentAttendanceAbsentToggleState copyWith({
    List<StudentAttendanceAbsentFormItem>? items,
    bool? isLoading,
    bool? isRefreshing,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
    DateTime? absenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) {
    return StudentAttendanceAbsentToggleState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      absenceDate: absenceDate ?? this.absenceDate,
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
        absenceDate,
        classroomCodes,
        tagCodes,
        search,
      ];
}

