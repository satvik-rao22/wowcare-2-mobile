part of 'student_attendance_daily_cubit.dart';

class StudentAttendanceDailyState extends Equatable {
  const StudentAttendanceDailyState({
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
    this.signInAtFilter,
    this.signOutAtFilter,
    this.isExpectedNotMarked,
    this.search,
    this.expectedCount,
    this.presentCount,
    this.absentCount,
    this.signedOutCount,
    this.notMarkedCount,
    this.isSummaryLoading = false,
    this.activeCount,
    this.upcomingCount,
    this.enrolledCount,
    this.allowCrossClass = false,
    this.tagNameToCode,
    this.isLoadingTagMap = false,
  });

  const StudentAttendanceDailyState.initial()
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
      signInAtFilter = null,
      signOutAtFilter = null,
      isExpectedNotMarked = null,
      search = null,
      expectedCount = null,
      presentCount = null,
      absentCount = null,
      signedOutCount = null,
      notMarkedCount = null,
      isSummaryLoading = false,
      activeCount = null,
      upcomingCount = null,
      enrolledCount = null,
      allowCrossClass = false,
      tagNameToCode = null,
      isLoadingTagMap = false;

  const StudentAttendanceDailyState.loaded({
    required List<StudentAttendanceDailyItem> items,
    required bool isFromCache,
    this.currentPage = 0,
    this.hasMore = false,
    required DateTime attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int? expectedCount,
    int? presentCount,
    int? absentCount,
    int? signedOutCount,
    int? notMarkedCount,
    bool isSummaryLoading = false,
    int? activeCount,
    int? upcomingCount,
    int? enrolledCount,
    bool allowCrossClass = false,
    Map<String, String>? tagNameToCode,
    bool isLoadingTagMap = false,
  }) : items = items,
       isLoading = false,
       isRefreshing = false,
       isFromCache = isFromCache,
       isLoadingMore = false,
       errorMessage = null,
       attendanceDate = attendanceDate,
       classroomCodes = classroomCodes,
       tagCodes = tagCodes,
       signInAtFilter = signInAtFilter,
       signOutAtFilter = signOutAtFilter,
       isExpectedNotMarked = isExpectedNotMarked,
       search = search,
       expectedCount = expectedCount,
       presentCount = presentCount,
       absentCount = absentCount,
       signedOutCount = signedOutCount,
       notMarkedCount = notMarkedCount,
       isSummaryLoading = isSummaryLoading,
       activeCount = activeCount,
       upcomingCount = upcomingCount,
       enrolledCount = enrolledCount,
       allowCrossClass = allowCrossClass,
       tagNameToCode = tagNameToCode,
       isLoadingTagMap = isLoadingTagMap;

  final List<StudentAttendanceDailyItem> items;
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
  final String? signInAtFilter;
  final String? signOutAtFilter;
  final bool? isExpectedNotMarked;
  final String? search;
  final int? expectedCount;
  final int? presentCount;
  final int? absentCount;
  final int? signedOutCount;
  final int? notMarkedCount;
  final bool isSummaryLoading;
  final int? activeCount;
  final int? upcomingCount;
  final int? enrolledCount;
  final bool allowCrossClass;
  final Map<String, String>? tagNameToCode;
  final bool isLoadingTagMap;

  StudentAttendanceDailyState copyWith({
    List<StudentAttendanceDailyItem>? items,
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
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int? expectedCount,
    int? presentCount,
    int? absentCount,
    int? signedOutCount,
    int? notMarkedCount,
    bool? isSummaryLoading,
    int? activeCount,
    int? upcomingCount,
    int? enrolledCount,
    bool? allowCrossClass,
    Map<String, String>? tagNameToCode,
    bool? isLoadingTagMap,
  }) {
    return StudentAttendanceDailyState(
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
      signInAtFilter: signInAtFilter ?? this.signInAtFilter,
      signOutAtFilter: signOutAtFilter ?? this.signOutAtFilter,
      isExpectedNotMarked: isExpectedNotMarked ?? this.isExpectedNotMarked,
      search: search ?? this.search,
      expectedCount: expectedCount ?? this.expectedCount,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      signedOutCount: signedOutCount ?? this.signedOutCount,
      notMarkedCount: notMarkedCount ?? this.notMarkedCount,
      isSummaryLoading: isSummaryLoading ?? this.isSummaryLoading,
      activeCount: activeCount ?? this.activeCount,
      upcomingCount: upcomingCount ?? this.upcomingCount,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      allowCrossClass: allowCrossClass ?? this.allowCrossClass,
      tagNameToCode: tagNameToCode ?? this.tagNameToCode,
      isLoadingTagMap: isLoadingTagMap ?? this.isLoadingTagMap,
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
    signInAtFilter,
    signOutAtFilter,
    isExpectedNotMarked,
    search,
    expectedCount,
    presentCount,
    absentCount,
    signedOutCount,
    notMarkedCount,
    isSummaryLoading,
    activeCount,
    upcomingCount,
    enrolledCount,
    allowCrossClass,
    tagNameToCode,
    isLoadingTagMap,
  ];
}
