import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_count_usecase.dart';

import '../../../../domain/features/attendance/entities/staff_attendance_daily.dart';
import '../../../../domain/features/attendance/usecases/get_staff_attendance_daily_usecase.dart';
import '../../../../domain/features/attendance/usecases/get_staff_attendance_expected_summary_usecase.dart';

part 'staff_attendance_daily_state.dart';

class StaffAttendanceDailyCubit extends Cubit<StaffAttendanceDailyState> {
  StaffAttendanceDailyCubit({
    required GetStaffAttendanceDailyUseCase getStaffAttendanceDailyUseCase,
    required GetStaffAttendanceExpectedSummaryUseCase
    getStaffAttendanceExpectedSummaryUseCase,
    required GetStaffCountUseCase getStaffCountUseCase,
    required StorageService storageService,
    required GetClassroomByCodeUseCase getClassroomByCodeUseCase,
  }) : _getStaffAttendanceDailyUseCase = getStaffAttendanceDailyUseCase,
       _getStaffAttendanceExpectedSummaryUseCase =
           getStaffAttendanceExpectedSummaryUseCase,
       _getStaffCountUseCase = getStaffCountUseCase,
       _storageService = storageService,
       _getClassroomByCodeUseCase = getClassroomByCodeUseCase,
       super(const StaffAttendanceDailyState.initial());

  final GetStaffAttendanceDailyUseCase _getStaffAttendanceDailyUseCase;
  final GetStaffAttendanceExpectedSummaryUseCase
  _getStaffAttendanceExpectedSummaryUseCase;
  final GetStaffCountUseCase _getStaffCountUseCase;
  final StorageService _storageService;
  final GetClassroomByCodeUseCase _getClassroomByCodeUseCase;

  static const int _pageSize = 10;

  // See StudentAttendanceDailyCubit for the full rationale — this cubit
  // mirrors that one's fetch/pagination shape and had the identical bugs.
  int _generation = 0;
  _PendingStaffDailyRefresh? _pendingRefresh;

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

  Future<void> loadInitial({
    required DateTime attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
  }) async {
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

  // Queues (rather than drops) a refresh() call that arrives while a
  // previous one is still in flight — see [_pendingRefresh].
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
      _pendingRefresh = _PendingStaffDailyRefresh(
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
      final firstPage = await _getStaffAttendanceDailyUseCase(
        fromAttendanceDate: dateString,
        toAttendanceDate: dateString,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        signInAtFilter: signInAtFilter,
        signOutAtFilter: signOutAtFilter,
        isExpectedNotMarked: isExpectedNotMarked,
        search: search,
        page: 0,
        size: _pageSize,
      );
      final summary = await _getStaffAttendanceExpectedSummaryUseCase(
        classroomCode: _classroomCodeForSummary(classroomCodes),
        // refresh() is the explicit-reload path (pull-to-refresh, after an
        // attendance action, filter change), so bypass the cached summary —
        // otherwise the counts never change from their first cached value.
        forceRefresh: true,
      );

      if (isClosed) return;

      emit(
        StaffAttendanceDailyState.loaded(
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
          totalStaffCount: state.totalStaffCount,
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

  /// Loads the total active/upcoming/total staff counts for the header
  /// summary — a separate call from the paginated list/legend summary above.
  Future<void> loadStaffCounts() async {
    try {
      final organizationCode =
          await _storageService.getString(StorageKeys.organizationCode) ?? '';
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (organizationCode.isEmpty || schoolCode.isEmpty) return;

      final staffCount = await _getStaffCountUseCase(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          activeCount: staffCount.active,
          upcomingCount: staffCount.upcoming,
          totalStaffCount: staffCount.active + staffCount.upcoming,
        ),
      );
    } catch (_) {
      // Non-fatal; list still works (same as StaffCubit count failures).
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

  Future<void> loadNextPage() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        state.isRefreshing ||
        !state.hasMore) {
      return;
    }
    if (state.currentPage < 0) return;
    if (state.attendanceDate == null) return;

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

      final page = await _getStaffAttendanceDailyUseCase(
        fromAttendanceDate: dateString,
        toAttendanceDate: dateString,
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
      if (myGeneration != _generation) return;

      emit(
        state.copyWith(
          items: [...state.items, ...page.items],
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
/// [StaffAttendanceDailyCubit._pendingRefresh].
class _PendingStaffDailyRefresh {
  const _PendingStaffDailyRefresh({
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
