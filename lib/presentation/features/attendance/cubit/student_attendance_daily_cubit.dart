import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import '../../../../domain/features/attendance/entities/student_attendance_daily.dart';
import '../../../../domain/features/attendance/repositories/attendance_repository.dart';
import '../../../../domain/features/attendance/usecases/get_student_attendance_daily_usecase.dart';
import '../../../../domain/features/attendance/usecases/get_student_attendance_expected_summary_usecase.dart';

part 'student_attendance_daily_state.dart';

class StudentAttendanceDailyCubit
    extends Cubit<StudentAttendanceDailyState> {
  StudentAttendanceDailyCubit({
    required GetStudentAttendanceDailyUseCase getStudentAttendanceDailyUseCase,
    required GetStudentAttendanceExpectedSummaryUseCase
        getStudentAttendanceExpectedSummaryUseCase,
    required AttendanceRepository repository,
  })  : _getStudentAttendanceDailyUseCase = getStudentAttendanceDailyUseCase,
        _getStudentAttendanceExpectedSummaryUseCase =
            getStudentAttendanceExpectedSummaryUseCase,
        _repository = repository,
        super(const StudentAttendanceDailyState.initial());

  final GetStudentAttendanceDailyUseCase _getStudentAttendanceDailyUseCase;
  final GetStudentAttendanceExpectedSummaryUseCase
      _getStudentAttendanceExpectedSummaryUseCase;
  final AttendanceRepository _repository;

  static const int _pageSize = 10;

  String? _classroomCodeForSummary(List<String>? classroomCodes) {
    if (classroomCodes == null || classroomCodes.isEmpty) return null;
    final code = classroomCodes.first.trim();
    return code.isEmpty ? null : code;
  }

  // Initial load: Try cache first, then API
  Future<void> loadInitial({
    required DateTime attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
  }) async {
    final dateString = _formatDate(attendanceDate);
    final hasServerTimeFilter = (signInAtFilter != null &&
            signInAtFilter.trim().isNotEmpty) ||
        (signOutAtFilter != null && signOutAtFilter.trim().isNotEmpty);

    if (hasServerTimeFilter) {
      await refresh(
        attendanceDate: attendanceDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        signInAtFilter: signInAtFilter,
        signOutAtFilter: signOutAtFilter,
        isExpectedNotMarked: isExpectedNotMarked,
        search: search,
      );
      return;
    }

    // Try cache first
    final cached = await (_repository is AttendanceRepositoryWithCache
        ? (_repository as AttendanceRepositoryWithCache)
            .loadCachedStudentAttendanceDaily(
          dateString,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        )
        : Future.value(null));

    if (cached != null && !isClosed) {
      try {
        final summary =
            await _getStudentAttendanceExpectedSummaryUseCase(
          classroomCode: _classroomCodeForSummary(classroomCodes),
          // Even when the list comes from cache, the summary counts must be
          // live — otherwise a cached load re-emits stale counts and reverts
          // the numbers the refresh() path just fetched.
          forceRefresh: true,
        );
        if (isClosed) return;
        emit(StudentAttendanceDailyState.loaded(
          items: cached.items,
          currentPage: 0,
          hasMore: cached.hasMore,
          isFromCache: true,
          attendanceDate: attendanceDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
          expectedCount: summary.expected,
          presentCount: summary.present,
          absentCount: summary.absent,
          signedOutCount: summary.signOut,
          notMarkedCount: summary.notMarked,
        ));
      } catch (_) {
        if (isClosed) return;
        emit(StudentAttendanceDailyState.loaded(
          items: cached.items,
          currentPage: 0,
          hasMore: cached.hasMore,
          isFromCache: true,
          attendanceDate: attendanceDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        ));
      }
      return; // Don't hit API if cache is valid
    }

    // No cache - load from API
    await refresh(
      attendanceDate: attendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      signInAtFilter: signInAtFilter,
      signOutAtFilter: signOutAtFilter,
      isExpectedNotMarked: isExpectedNotMarked,
      search: search,
    );
  }

  // Refresh: Always load page 0 from API
  Future<void> refresh({
    required DateTime attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
  }) async {
    if (state.isRefreshing) return;

    final dateString = _formatDate(attendanceDate);

    emit(state.copyWith(
      isLoading: state.items.isEmpty,
      isRefreshing: true,
      errorMessage: null,
      attendanceDate: attendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      signInAtFilter: signInAtFilter,
      signOutAtFilter: signOutAtFilter,
      isExpectedNotMarked: isExpectedNotMarked,
      search: search,
      isSummaryLoading: true,
    ));

    try {
      final firstPage = await _getStudentAttendanceDailyUseCase(
        attendanceDate: dateString,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        signInAtFilter: signInAtFilter,
        signOutAtFilter: signOutAtFilter,
        isExpectedNotMarked: isExpectedNotMarked,
        search: search,
        page: 0,
        size: _pageSize,
      );
      final summary =
          await _getStudentAttendanceExpectedSummaryUseCase(
        classroomCode: _classroomCodeForSummary(classroomCodes),
        // refresh() is the explicit-reload path (pull-to-refresh, after an
        // attendance action, filter change), so bypass the cached summary —
        // otherwise the counts never change from their first cached value.
        forceRefresh: true,
      );

      if (isClosed) return;

      emit(StudentAttendanceDailyState.loaded(
        items: firstPage.items,
        currentPage: firstPage.page,
        hasMore: firstPage.hasMore,
        isFromCache: false,
        attendanceDate: attendanceDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        signInAtFilter: signInAtFilter,
        signOutAtFilter: signOutAtFilter,
        isExpectedNotMarked: isExpectedNotMarked,
        search: search,
        expectedCount: summary.expected,
        presentCount: summary.present,
        absentCount: summary.absent,
        signedOutCount: summary.signOut,
        notMarkedCount: summary.notMarked,
        isSummaryLoading: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isSummaryLoading: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  // Load next page: Only if not loading and has more
  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.currentPage < 0) return; // Safety check
    if (state.attendanceDate == null) return;

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final nextPageIndex = state.currentPage + 1;
      final dateString = _formatDate(state.attendanceDate!);

      final page = await _getStudentAttendanceDailyUseCase(
        attendanceDate: dateString,
        classroomCodes: state.classroomCodes,
        tagCodes: state.tagCodes,
        signInAtFilter: state.signInAtFilter,
        signOutAtFilter: state.signOutAtFilter,
        isExpectedNotMarked: state.isExpectedNotMarked,
        search: state.search,
        page: nextPageIndex,
        size: _pageSize,
      );

      if (isClosed) return;

      emit(state.copyWith(
        items: [...state.items, ...page.items], // Append
        currentPage: page.page,
        hasMore: page.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
