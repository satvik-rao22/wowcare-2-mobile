part of 'student_cubit.dart';

/// Single owner of the list's async DISPLAY phase — replaces the former
/// `isLoading`/`isRefreshing`/`isLoadingMore` booleans so they can't drift into
/// contradictory combinations. Concurrency (blocking a re-entrant refresh) is a
/// separate concern handled by the cubit's guard on [StudentListStatus.refreshing]
/// plus the `_generation` staleness check.
enum StudentListStatus { loading, refreshing, loadingMore, loaded, error }

class StudentState extends Equatable {
  static const Object _unset = Object();

  const StudentState({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    required this.status,
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
    this.selectedFilters = const {},
    this.showInactive = false,
    this.selection = const [],
    this.activeCount = 0,
    this.upcomingCount = 0,
    this.expectedTotal = 0,
    this.expectedSignedIn = 0,
    this.expectedAbsent = 0,
    this.expectedSignedOut = 0,
    this.expectedNotMarked = 0,
    this.tagNameToCode = const {},
    this.guardianNameToCode = const {},
    this.attendanceStatusByStudentCode = const {},
    this.attendanceStatusLoading = false,
    this.attendanceStatusError = false,
    this.classroomNameByDetailApi = const {},
    this.classroomDetailFetchFailed = const {},
    this.noAccessibleClassrooms = false,
  });

  const StudentState.initial()
    : items = const [],
      currentPage = 0,
      hasMore = true,
      status = StudentListStatus.loading,
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
      errorMessage = null,
      selectedFilters = const {
        'Status': ['Active'],
      },
      showInactive = false,
      selection = const [],
      activeCount = 0,
      upcomingCount = 0,
      expectedTotal = 0,
      expectedSignedIn = 0,
      expectedAbsent = 0,
      expectedSignedOut = 0,
      expectedNotMarked = 0,
      tagNameToCode = const {},
      guardianNameToCode = const {},
      attendanceStatusByStudentCode = const {},
      attendanceStatusLoading = false,
      attendanceStatusError = false,
      classroomNameByDetailApi = const {},
      classroomDetailFetchFailed = const {},
      noAccessibleClassrooms = false;

  final List<Student> items;
  final int currentPage;
  final bool hasMore;
  final StudentListStatus status;
  final bool isFromCache;

  /// Backward-compatible display getters derived from [status]. The full-screen
  /// loader (init + empty), the background refresh indicator, and the paginate
  /// spinner each read one of these; keeping them means no widget/test churn.
  bool get isLoading => status == StudentListStatus.loading;
  bool get isRefreshing => status == StudentListStatus.refreshing;
  bool get isLoadingMore => status == StudentListStatus.loadingMore;
  bool get hasError => status == StudentListStatus.error;
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

  /// The authoritative UI filter SELECTION (display names, e.g.
  /// {'Status': ['Active'], 'Classroom': ['Blue-A']}). Single source of truth
  /// for the filter chips and the filter sheet; the resolved *code* filters
  /// above are derived from this when a filter change is applied.
  final Map<String, List<String>> selectedFilters;

  /// Whether the list is showing inactive students (drives the Active/Inactive
  /// toggle). Kept here so the widget no longer owns a competing copy.
  final bool showInactive;

  /// Per-row multi-select flags, parallel to [items] (index-aligned). Owned here
  /// so selection has a single authoritative owner; the widget derives
  /// "select all" from this rather than keeping a competing bool.
  final List<bool> selection;

  /// Server-provided roster counts (the summary stat cards) — moved off the
  /// widget so the cubit is the single owner. Active/Upcoming drive the first
  /// card; the expected-* set drives the attendance summary card.
  final int activeCount;
  final int upcomingCount;
  final int expectedTotal;
  final int expectedSignedIn;
  final int expectedAbsent;
  final int expectedSignedOut;
  final int expectedNotMarked;

  /// Filter name→code lookups (tag names / guardian names → codes) — moved off
  /// the widget so the cubit owns them; used to resolve the display selection
  /// into API code filters.
  final Map<String, String> tagNameToCode;
  final Map<String, String> guardianNameToCode;

  /// Per-student today's sign-in status (studentCode → status), plus its
  /// load/error flags — drives the per-row attendance badges and gates the
  /// attendance-action / activities buttons. Recomputed for the current row
  /// selection; owned here so the widget no longer holds a competing copy.
  final Map<String, String> attendanceStatusByStudentCode;
  final bool attendanceStatusLoading;
  final bool attendanceStatusError;

  /// Classroom names resolved via the per-code detail API (code → name), for
  /// classrooms the `ClassroomCubit` roster didn't already name, plus the set of
  /// codes whose detail fetch failed/returned blank (so we don't retry them).
  /// Owned here so the widget no longer holds competing caches.
  final Map<String, String> classroomNameByDetailApi;
  final Set<String> classroomDetailFetchFailed;

  /// True only when the empty list is caused by a scoped staff/teacher persona
  /// having NO accessible classrooms (a scope/permission condition), so the UI
  /// can show a "no classrooms assigned" message instead of the generic
  /// "No students found" — an empty result here is not the same as no students
  /// existing. Reset to false on every normal roster load.
  final bool noAccessibleClassrooms;

  StudentState copyWith({
    List<Student>? items,
    int? currentPage,
    bool? hasMore,
    StudentListStatus? status,
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
    Map<String, List<String>>? selectedFilters,
    bool? showInactive,
    List<bool>? selection,
    int? activeCount,
    int? upcomingCount,
    int? expectedTotal,
    int? expectedSignedIn,
    int? expectedAbsent,
    int? expectedSignedOut,
    int? expectedNotMarked,
    Map<String, String>? tagNameToCode,
    Map<String, String>? guardianNameToCode,
    Map<String, String>? attendanceStatusByStudentCode,
    bool? attendanceStatusLoading,
    bool? attendanceStatusError,
    Map<String, String>? classroomNameByDetailApi,
    Set<String>? classroomDetailFetchFailed,
    bool? noAccessibleClassrooms,
  }) {
    return StudentState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      status: status ?? this.status,
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
      selectedFilters: selectedFilters ?? this.selectedFilters,
      showInactive: showInactive ?? this.showInactive,
      selection: selection ?? this.selection,
      activeCount: activeCount ?? this.activeCount,
      upcomingCount: upcomingCount ?? this.upcomingCount,
      expectedTotal: expectedTotal ?? this.expectedTotal,
      expectedSignedIn: expectedSignedIn ?? this.expectedSignedIn,
      expectedAbsent: expectedAbsent ?? this.expectedAbsent,
      expectedSignedOut: expectedSignedOut ?? this.expectedSignedOut,
      expectedNotMarked: expectedNotMarked ?? this.expectedNotMarked,
      tagNameToCode: tagNameToCode ?? this.tagNameToCode,
      guardianNameToCode: guardianNameToCode ?? this.guardianNameToCode,
      attendanceStatusByStudentCode:
          attendanceStatusByStudentCode ?? this.attendanceStatusByStudentCode,
      attendanceStatusLoading:
          attendanceStatusLoading ?? this.attendanceStatusLoading,
      attendanceStatusError:
          attendanceStatusError ?? this.attendanceStatusError,
      classroomNameByDetailApi:
          classroomNameByDetailApi ?? this.classroomNameByDetailApi,
      classroomDetailFetchFailed:
          classroomDetailFetchFailed ?? this.classroomDetailFetchFailed,
      noAccessibleClassrooms:
          noAccessibleClassrooms ?? this.noAccessibleClassrooms,
    );
  }

  @override
  List<Object?> get props => [
    items,
    currentPage,
    hasMore,
    status,
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
    selectedFilters,
    showInactive,
    selection,
    activeCount,
    upcomingCount,
    expectedTotal,
    expectedSignedIn,
    expectedAbsent,
    expectedSignedOut,
    expectedNotMarked,
    tagNameToCode,
    guardianNameToCode,
    attendanceStatusByStudentCode,
    attendanceStatusLoading,
    attendanceStatusError,
    classroomNameByDetailApi,
    classroomDetailFetchFailed,
    noAccessibleClassrooms,
  ];
}
