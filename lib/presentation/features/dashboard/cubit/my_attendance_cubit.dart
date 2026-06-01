import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/attendance/models/student_attendance_models.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';

part 'my_attendance_state.dart';

/// Default page size for attendance profile requests.
const int _kPageSize = 20;

/// Cubit powering [MyAttendanceCard].
///
/// Fetches the logged-in staff member's attendance profile and absent records
/// from two existing repository methods:
///
///  • [AttendanceRepository.fetchStaffAttendanceProfile]
///    → `GET /api/v1/staff-attendance/profile`
///
///  • [AttendanceRepository.fetchStaffAttendanceProfileAbsentToggle]
///    → `GET /api/v1/staff-attendance/profile/absent/toggle`
///
/// Load strategy:
/// - **First open**: show shimmer → load attendance page 0.
/// - **Tab switch to Absent**: lazy-load absent page 0 only when first needed.
/// - **Load More**: append next page to the active list.
/// - **Date range change / force refresh**: reset both lists and reload.
class MyAttendanceCubit extends Cubit<MyAttendanceState> {
  MyAttendanceCubit({
    required AttendanceRepository attendanceRepository,
    required StorageService storageService,
  })  : _repo = attendanceRepository,
        _storage = storageService,
        super(const MyAttendanceState());

  final AttendanceRepository _repo;
  final StorageService _storage;

  bool _isFetching = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads the current month's attendance (page 0).
  /// Call this from [initState] / dashboard init.
  Future<void> load({bool forceRefresh = false}) async {
    if (_isFetching) return;
    if (!forceRefresh && state.attendanceLoaded) return;

    final staffCode = await _resolveStaffCode();
    if (staffCode.isEmpty) {
      AppLogger.w('[MyAttendanceCubit] staffCode not found in storage');
      return;
    }

    _isFetching = true;

    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = now;

    // Read display name from storage immediately so the profile row shows
    // even when the current month has no attendance records.
    final displayName =
        (await _storage.getString(StorageKeys.displayName) ?? '').trim();

    emit(state.copyWith(
      status: _Status.loading,
      staffCode: staffCode,
      staffName: displayName.isNotEmpty ? displayName : state.staffName,
      fromDate: from,
      toDate: to,
      clearError: true,
    ));

    await _fetchAttendance(
      staffCode: staffCode,
      fromDate: from,
      toDate: to,
      page: 0,
      append: false,
    );

    _isFetching = false;
  }

  /// Refreshes both lists (called on pull-to-refresh).
  Future<void> refresh() async {
    if (_isFetching) return;
    _isFetching = true;

    final staffCode = state.staffCode.isNotEmpty
        ? state.staffCode
        : await _resolveStaffCode();
    if (staffCode.isEmpty) {
      _isFetching = false;
      return;
    }

    final from = state.fromDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    final to = state.toDate ?? DateTime.now();

    await Future.wait([
      _fetchAttendance(
        staffCode: staffCode,
        fromDate: from,
        toDate: to,
        page: 0,
        append: false,
      ),
      _fetchAbsent(
        staffCode: staffCode,
        fromDate: from,
        toDate: to,
        page: 0,
        append: false,
      ),
    ]);

    _isFetching = false;
  }

  /// Switches between Attendance and Absent tabs.
  /// Lazy-fetches absent data on first switch.
  Future<void> switchTab(MyAttendanceTab tab) async {
    if (state.tab == tab) return;
    emit(state.copyWith(tab: tab));

    if (tab == MyAttendanceTab.absent && !state.absentLoaded) {
      final staffCode = state.staffCode.isNotEmpty
          ? state.staffCode
          : await _resolveStaffCode();
      if (staffCode.isEmpty) return;

      final from = state.fromDate ??
          DateTime(DateTime.now().year, DateTime.now().month, 1);
      final to = state.toDate ?? DateTime.now();

      await _fetchAbsent(
        staffCode: staffCode,
        fromDate: from,
        toDate: to,
        page: 0,
        append: false,
      );
    }
  }

  /// Loads the next page for the active tab.
  Future<void> loadMore() async {
    if (state.isLoadingMore) return;

    final staffCode = state.staffCode;
    if (staffCode.isEmpty) return;

    final from = state.fromDate!;
    final to = state.toDate!;

    if (state.tab == MyAttendanceTab.attendance) {
      if (!state.attendanceHasMore) return;
      await _fetchAttendance(
        staffCode: staffCode,
        fromDate: from,
        toDate: to,
        page: state.attendancePage + 1,
        append: true,
      );
    } else {
      if (!state.absentHasMore) return;
      await _fetchAbsent(
        staffCode: staffCode,
        fromDate: from,
        toDate: to,
        page: state.absentPage + 1,
        append: true,
      );
    }
  }

  /// Changes the active date range and reloads both tabs from page 0.
  Future<void> changeDateRange(DateTime from, DateTime to) async {
    if (_isFetching) return;
    _isFetching = true;

    final staffCode = state.staffCode.isNotEmpty
        ? state.staffCode
        : await _resolveStaffCode();
    if (staffCode.isEmpty) {
      _isFetching = false;
      return;
    }

    emit(state.copyWith(
      status: _Status.loading,
      fromDate: from,
      toDate: to,
      attendanceRecords: const [],
      attendancePage: 0,
      attendanceHasMore: false,
      attendanceLoaded: false,
      absentRecords: const [],
      absentPage: 0,
      absentHasMore: false,
      absentLoaded: false,
      clearError: true,
    ));

    await _fetchAttendance(
      staffCode: staffCode,
      fromDate: from,
      toDate: to,
      page: 0,
      append: false,
    );

    if (state.tab == MyAttendanceTab.absent) {
      await _fetchAbsent(
        staffCode: staffCode,
        fromDate: from,
        toDate: to,
        page: 0,
        append: false,
      );
    }

    _isFetching = false;
  }

  // ---------------------------------------------------------------------------
  // Private fetch helpers
  // ---------------------------------------------------------------------------

  Future<void> _fetchAttendance({
    required String staffCode,
    required DateTime fromDate,
    required DateTime toDate,
    required int page,
    required bool append,
  }) async {
    if (append) {
      emit(state.copyWith(status: _Status.loadingMore));
    }

    try {
      final raw = await _repo.fetchStaffAttendanceProfile(
        queryParameters: {
          'staffCode': staffCode,
          'fromAttendanceDate': _fmt(fromDate),
          'toAttendanceDate': _fmt(toDate),
          'page': page,
          'size': _kPageSize,
          'sort': 'attendanceDate,desc',
        },
      );

      if (raw == null) {
        emit(state.copyWith(
          status: _Status.loaded,
          attendanceLoaded: true,
        ));
        return;
      }

      final parsed = StaffAttendanceDailyPageModel.fromJson(raw);

      // Aggregation from the first item matching the staffCode.
      int attendedDays = state.attendedDays;
      int attendedHours = state.attendedHours;
      int attendedMinutes = state.attendedMinutes;
      String totalAttendedTime = state.totalAttendedTime;
      String staffName = state.staffName;

      if (page == 0) {
        // The API already scopes results to the requested staffCode, so
        // case/whitespace mismatches in a local filter would silently drop data.
        // Pick the first item that has a non-zero attendedDays, or just the first.
        final first = parsed.items
            .cast<StaffAttendanceDailyItemModel?>()
            .where((i) => (i?.attendedDays ?? 0) > 0)
            .firstOrNull ?? parsed.items.cast<StaffAttendanceDailyItemModel?>().firstOrNull;
        if (first != null) {
          attendedDays = first.attendedDays;
          attendedHours = first.attendedHours ?? 0;
          attendedMinutes = first.attendedMinutes ?? 0;
          totalAttendedTime = first.attendedTime ?? '';
          if (first.staffName.trim().isNotEmpty) staffName = first.staffName;
        }
      }

      final merged = append
          ? [...state.attendanceRecords, ...parsed.items]
          : parsed.items;

      emit(state.copyWith(
        status: _Status.loaded,
        staffName: staffName,
        attendanceRecords: merged,
        attendancePage: parsed.page,
        attendanceHasMore: parsed.hasMore,
        attendanceLoaded: true,
        attendedDays: attendedDays,
        attendedHours: attendedHours,
        attendedMinutes: attendedMinutes,
        totalAttendedTime: totalAttendedTime,
        clearError: true,
      ));

      AppLogger.d(
        '[MyAttendanceCubit] attendance page=$page '
        'items=${parsed.items.length} hasMore=${parsed.hasMore}',
      );
    } catch (e) {
      AppLogger.e('[MyAttendanceCubit] fetchAttendance error: $e');
      if (!append) {
        emit(state.copyWith(
          status: _Status.error,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
          attendanceLoaded: true,
        ));
      } else {
        // On load-more error keep existing data, just stop the spinner.
        emit(state.copyWith(status: _Status.loaded));
      }
    }
  }

  Future<void> _fetchAbsent({
    required String staffCode,
    required DateTime fromDate,
    required DateTime toDate,
    required int page,
    required bool append,
  }) async {
    if (append) {
      emit(state.copyWith(status: _Status.loadingMore));
    }

    try {
      final raw = await _repo.fetchStaffAttendanceProfileAbsentToggle(
        queryParameters: {
          'staffCode': staffCode,
          'fromAbsenceDate': _fmt(fromDate),
          'toAbsenceDate': _fmt(toDate),
          'page': page,
          'size': _kPageSize,
          'sort': 'absenceDate,desc',
        },
      );

      if (raw == null) {
        emit(state.copyWith(
          status: _Status.loaded,
          absentLoaded: true,
        ));
        return;
      }

      final parsed = StaffAttendanceAbsentPageModel.fromJson(raw);

      // Aggregation: absentDays from the first matching item.
      int absentDays = state.absentDays;
      if (page == 0) {
        final first = parsed.items.cast<StaffAttendanceAbsentItemModel?>().firstOrNull;
        if (first != null) {
          absentDays = first.absentDays;
        }
      }

      final merged = append
          ? [...state.absentRecords, ...parsed.items]
          : parsed.items;

      emit(state.copyWith(
        status: _Status.loaded,
        absentRecords: merged,
        absentPage: parsed.page,
        absentHasMore: parsed.hasMore,
        absentLoaded: true,
        absentDays: absentDays,
        clearError: true,
      ));

      AppLogger.d(
        '[MyAttendanceCubit] absent page=$page '
        'items=${parsed.items.length} hasMore=${parsed.hasMore}',
      );
    } catch (e) {
      AppLogger.e('[MyAttendanceCubit] fetchAbsent error: $e');
      if (!append) {
        emit(state.copyWith(
          status: _Status.loaded,
          absentLoaded: true,
        ));
      } else {
        emit(state.copyWith(status: _Status.loaded));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  Future<String> _resolveStaffCode() async {
    final code = (await _storage.getString(StorageKeys.staffCode))?.trim() ?? '';
    return code;
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
