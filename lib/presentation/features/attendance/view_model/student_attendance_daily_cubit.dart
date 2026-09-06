import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/attendance_cross_class_resolver.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_counts_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import '../../../../domain/features/attendance/entities/student_attendance_daily.dart';
import '../../../../domain/features/attendance/usecases/get_cached_student_attendance_daily_usecase.dart';
import '../../../../domain/features/attendance/usecases/get_student_attendance_daily_usecase.dart';
import '../../../../domain/features/attendance/usecases/get_student_attendance_expected_summary_usecase.dart';

part 'student_attendance_daily_state.dart';

class StudentAttendanceDailyCubit extends Cubit<StudentAttendanceDailyState> {
  StudentAttendanceDailyCubit({
    required GetStudentAttendanceDailyUseCase getStudentAttendanceDailyUseCase,
    required GetStudentAttendanceExpectedSummaryUseCase
    getStudentAttendanceExpectedSummaryUseCase,
    required GetCachedStudentAttendanceDailyUseCase
    getCachedStudentAttendanceDailyUseCase,
    required GetStudentCountsUseCase getStudentCountsUseCase,
    required GetTagNameCodeMapForSchoolUseCase
    getTagNameCodeMapForSchoolUseCase,
    required StorageService storageService,
    required GetClassroomByCodeUseCase getClassroomByCodeUseCase,
  }) : _getStudentAttendanceDailyUseCase = getStudentAttendanceDailyUseCase,
       _getStudentAttendanceExpectedSummaryUseCase =
           getStudentAttendanceExpectedSummaryUseCase,
       _getCachedStudentAttendanceDailyUseCase =
           getCachedStudentAttendanceDailyUseCase,
       _getStudentCountsUseCase = getStudentCountsUseCase,
       _getTagNameCodeMapForSchoolUseCase = getTagNameCodeMapForSchoolUseCase,
       _storageService = storageService,
       _getClassroomByCodeUseCase = getClassroomByCodeUseCase,
       super(const StudentAttendanceDailyState.initial());

  final GetStudentAttendanceDailyUseCase _getStudentAttendanceDailyUseCase;
  final GetStudentAttendanceExpectedSummaryUseCase
  _getStudentAttendanceExpectedSummaryUseCase;
  final GetCachedStudentAttendanceDailyUseCase
  _getCachedStudentAttendanceDailyUseCase;
  final GetStudentCountsUseCase _getStudentCountsUseCase;
  final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  final StorageService _storageService;
  final GetClassroomByCodeUseCase _getClassroomByCodeUseCase;

  static const int _pageSize = 10;

  // Bumped by every state-replacing emit (both refresh() paths and the
  // loadInitial() cache-hit path) so loadNextPage() can tell, after its own
  // await returns, whether a newer request already replaced the list out
  // from under it — see loadNextPage()'s discard check.
  int _generation = 0;

  // The most recently REQUESTED refresh() call while one is already in
  // flight. refresh() used to silently drop a call that arrived mid-flight
  // (`if (state.isRefreshing) return`), so rapidly changing a filter could
  // leave the list showing an OLDER selection than the chips displayed.
  // Now it queues the latest request here and replays it once the in-flight
  // one finishes, so the user's last selection always wins.
  _PendingDailyRefresh? _pendingRefresh;

  /// Resolves a classroom's display name from its code — used by the View's
  /// own on-demand name cache when a row's classroom name isn't already
  /// known. Returns null (rather than throwing) on failure, matching the
  /// View's previous "keep code when lookup fails" behavior.
  Future<String?> fetchClassroomName(String code) async {
    try {
      final details = await _getClassroomByCodeUseCase(code: code);
      final name = details.name.trim();
      return name.isNotEmpty ? name : null;
    } catch (_) {
      return null;
    }
  }

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
    final hasServerTimeFilter =
        (signInAtFilter != null && signInAtFilter.trim().isNotEmpty) ||
        (signOutAtFilter != null && signOutAtFilter.trim().isNotEmpty);
    final hasServerLegendFilter =
        hasServerTimeFilter || isExpectedNotMarked == true;

    if (hasServerLegendFilter) {
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
    final cached = await _getCachedStudentAttendanceDailyUseCase(
      dateString,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
    );

    if (cached != null && !isClosed) {
      // This emit fully replaces items/currentPage, same as refresh()'s —
      // bump so a loadNextPage() already in flight can detect it was
      // superseded instead of appending onto this cache-hit result.
      _generation++;
      try {
        final summary = await _getStudentAttendanceExpectedSummaryUseCase(
          classroomCode: _classroomCodeForSummary(classroomCodes),
          // Even when the list comes from cache, the summary counts must be
          // live — otherwise a cached load re-emits stale counts and reverts
          // the numbers the refresh() path just fetched.
          forceRefresh: true,
        );
        if (isClosed) return;
        emit(
          StudentAttendanceDailyState.loaded(
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
            activeCount: state.activeCount,
            upcomingCount: state.upcomingCount,
            enrolledCount: state.enrolledCount,
            allowCrossClass: state.allowCrossClass,
            tagNameToCode: state.tagNameToCode,
            isLoadingTagMap: state.isLoadingTagMap,
          ),
        );
      } catch (_) {
        if (isClosed) return;
        // The live-summary fetch failed — fall back to the LAST KNOWN counts
        // instead of leaving them off entirely. `.loaded()` is a full state
        // reconstruction (not a copyWith), so omitting these fields here
        // reset the header to blank/0 on every transient summary failure,
        // even though the list itself loaded fine from cache.
        emit(
          StudentAttendanceDailyState.loaded(
            items: cached.items,
            currentPage: 0,
            hasMore: cached.hasMore,
            isFromCache: true,
            attendanceDate: attendanceDate,
            classroomCodes: classroomCodes,
            tagCodes: tagCodes,
            search: search,
            expectedCount: state.expectedCount,
            presentCount: state.presentCount,
            absentCount: state.absentCount,
            signedOutCount: state.signedOutCount,
            notMarkedCount: state.notMarkedCount,
            activeCount: state.activeCount,
            upcomingCount: state.upcomingCount,
            enrolledCount: state.enrolledCount,
            allowCrossClass: state.allowCrossClass,
            tagNameToCode: state.tagNameToCode,
            isLoadingTagMap: state.isLoadingTagMap,
          ),
        );
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

  // Refresh: Always load page 0 from API. Queues (rather than drops) a call
  // that arrives while a previous refresh is still in flight — see
  // [_pendingRefresh].
  Future<void> refresh({
    required DateTime attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
  }) async {
    if (state.isRefreshing) {
      _pendingRefresh = _PendingDailyRefresh(
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

    await _runRefresh(
      attendanceDate: attendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      signInAtFilter: signInAtFilter,
      signOutAtFilter: signOutAtFilter,
      isExpectedNotMarked: isExpectedNotMarked,
      search: search,
    );

    // One or more newer calls may have arrived (and been queued above)
    // while that refresh was in flight. Drain straight to the LAST one —
    // any intermediate queued request is superseded and would just be a
    // wasted round-trip — so the final list always matches the user's most
    // recent filter selection instead of whatever was in flight when they
    // changed it again.
    while (_pendingRefresh != null && !isClosed) {
      final next = _pendingRefresh!;
      _pendingRefresh = null;
      await _runRefresh(
        attendanceDate: next.attendanceDate,
        classroomCodes: next.classroomCodes,
        tagCodes: next.tagCodes,
        signInAtFilter: next.signInAtFilter,
        signOutAtFilter: next.signOutAtFilter,
        isExpectedNotMarked: next.isExpectedNotMarked,
        search: next.search,
      );
    }
  }

  Future<void> _runRefresh({
    required DateTime attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
  }) async {
    _generation++;
    final dateString = _formatDate(attendanceDate);

    emit(
      state.copyWith(
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
      ),
    );

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
      final summary = await _getStudentAttendanceExpectedSummaryUseCase(
        classroomCode: _classroomCodeForSummary(classroomCodes),
        // refresh() is the explicit-reload path (pull-to-refresh, after an
        // attendance action, filter change), so bypass the cached summary —
        // otherwise the counts never change from their first cached value.
        forceRefresh: true,
      );

      if (isClosed) return;

      emit(
        StudentAttendanceDailyState.loaded(
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
          activeCount: state.activeCount,
          upcomingCount: state.upcomingCount,
          enrolledCount: state.enrolledCount,
          allowCrossClass: state.allowCrossClass,
          tagNameToCode: state.tagNameToCode,
          isLoadingTagMap: state.isLoadingTagMap,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          isSummaryLoading: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// Loads the total active/upcoming/enrolled student counts for the
  /// header summary — a separate call from the paginated list/legend
  /// summary above.
  Future<void> loadStudentCounts() async {
    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;
      final counts = await _getStudentCountsUseCase(schoolCode: schoolCode);
      if (isClosed) return;
      final activeC = counts.activeCount;
      final upcomingC = counts.upcomingCount;
      emit(
        state.copyWith(
          activeCount: activeC,
          upcomingCount: upcomingC,
          enrolledCount: activeC + upcomingC,
        ),
      );
    } catch (_) {
      // Non-critical; keep existing values.
    }
  }

  /// Resolves whether the active school lets teachers do cross-class student
  /// attendance, flipping [StudentAttendanceDailyState.allowCrossClass] on
  /// when enabled. Never flips it back off (mirrors the View's prior
  /// behavior — once true for a session, stays true).
  Future<void> resolveCrossClassFlag() async {
    if (state.allowCrossClass) return;
    try {
      final enabled =
          await AttendanceCrossClassResolver.isEnabledForCurrentSchool(
            storage: _storageService,
          );
      if (isClosed || !enabled) return;
      emit(state.copyWith(allowCrossClass: true));
    } catch (_) {
      // Non-critical: default (scoped) behaviour stays in effect.
    }
  }

  Future<void> loadTagNameCodeMap() async {
    if (state.isLoadingTagMap) return;
    emit(state.copyWith(isLoadingTagMap: true));

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) {
        if (isClosed) return;
        emit(state.copyWith(isLoadingTagMap: false));
        return;
      }
      final map = await _getTagNameCodeMapForSchoolUseCase(
        schoolCode: schoolCode,
      );
      if (isClosed) return;
      emit(state.copyWith(tagNameToCode: map, isLoadingTagMap: false));
    } catch (e) {
      AppLogger.d('Failed to load tag name-to-code map: $e');
      if (isClosed) return;
      emit(state.copyWith(isLoadingTagMap: false));
    }
  }

  /// Resolves the logged-in user's display name (falling back to username)
  /// for the header greeting. Returns '' when neither is available.
  Future<String> resolveLoggedInUserName() async {
    final displayName =
        (await _storageService.getString(StorageKeys.displayName) ?? '').trim();
    if (displayName.isNotEmpty) return displayName;
    return (await _storageService.getString(StorageKeys.username) ?? '').trim();
  }

  // Load next page: Only if not loading and has more. Also bails while a
  // refresh() is in flight — that's about to replace items/currentPage for a
  // possibly different filter/date entirely, so starting a next-page fetch
  // against the CURRENT (soon-to-be-stale) state would be wasted at best.
  Future<void> loadNextPage() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        state.isRefreshing ||
        !state.hasMore) {
      return;
    }
    if (state.currentPage < 0) return; // Safety check
    if (state.attendanceDate == null) return;

    // Captured so the result can be discarded below if a refresh() started
    // (and possibly finished) DURING this method's own await — the guard
    // above only catches a refresh already in flight at call time, not one
    // that starts a moment later while this request is still on the wire.
    final myGeneration = _generation;
    final classroomCodes = state.classroomCodes;
    final tagCodes = state.tagCodes;
    final signInAtFilter = state.signInAtFilter;
    final signOutAtFilter = state.signOutAtFilter;
    final isExpectedNotMarked = state.isExpectedNotMarked;
    final search = state.search;

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final nextPageIndex = state.currentPage + 1;
      final dateString = _formatDate(state.attendanceDate!);

      final page = await _getStudentAttendanceDailyUseCase(
        attendanceDate: dateString,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        signInAtFilter: signInAtFilter,
        signOutAtFilter: signOutAtFilter,
        isExpectedNotMarked: isExpectedNotMarked,
        search: search,
        page: nextPageIndex,
        size: _pageSize,
      );

      if (isClosed) return;
      // A refresh() already replaced state.items/currentPage for a newer
      // request while this page was in flight — appending this now-stale
      // page onto the new list would corrupt it (wrong filter's rows) and
      // desync currentPage from what that refresh just set. The fresh
      // refresh already has the correct first page; just drop this one.
      if (myGeneration != _generation) return;

      emit(
        state.copyWith(
          items: [...state.items, ...page.items], // Append
          currentPage: page.page,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      if (myGeneration != _generation) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// A refresh() call queued while a previous one was still in flight — see
/// [StudentAttendanceDailyCubit._pendingRefresh].
class _PendingDailyRefresh {
  const _PendingDailyRefresh({
    required this.attendanceDate,
    this.classroomCodes,
    this.tagCodes,
    this.signInAtFilter,
    this.signOutAtFilter,
    this.isExpectedNotMarked,
    this.search,
  });

  final DateTime attendanceDate;
  final List<String>? classroomCodes;
  final List<String>? tagCodes;
  final String? signInAtFilter;
  final String? signOutAtFilter;
  final bool? isExpectedNotMarked;
  final String? search;
}
