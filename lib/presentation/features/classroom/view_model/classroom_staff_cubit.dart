import 'package:bloc/bloc.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/app_time.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/storage_keys.dart';
import '../../../../domain/features/attendance/usecases/get_staff_today_sign_in_status_map_usecase.dart';
import '../../../../domain/features/staff_classroom/entities/staff_classroom_item.dart';
import '../../../../domain/features/staff_classroom/usecases/get_staff_classrooms_usecase.dart';
import 'classroom_staff_state.dart';

class _StaffAttendanceCacheEntry {
  const _StaffAttendanceCacheEntry({
    required this.fetchedAt,
    required this.statusByCode,
  });

  final DateTime fetchedAt;
  final Map<String, String> statusByCode;
}

class ClassroomStaffCubit extends Cubit<ClassroomStaffState> {
  ClassroomStaffCubit({
    required GetStaffClassroomsUseCase getStaffClassroomsUseCase,
    required GetStaffTodaySignInStatusMapUseCase
    getStaffTodaySignInStatusMapUseCase,
    required StorageService storageService,
  }) : _getStaffClassroomsUseCase = getStaffClassroomsUseCase,
       _getStaffTodaySignInStatusMapUseCase =
           getStaffTodaySignInStatusMapUseCase,
       _storageService = storageService,
       super(const ClassroomStaffState.initial());

  final GetStaffClassroomsUseCase _getStaffClassroomsUseCase;
  final GetStaffTodaySignInStatusMapUseCase
  _getStaffTodaySignInStatusMapUseCase;
  final StorageService _storageService;

  String? _lastSuccessfulStaffListKey;

  /// Shared across every [ClassroomStaffCubit] instance (this cubit is
  /// registered as a fresh instance per screen visit) so switching tabs and
  /// coming back doesn't re-pay the roster-wide status fetch within the TTL
  /// window. Cleared on school switch via [clearAttendanceStatusCache].
  static const Duration _attendanceCacheTtl = Duration(minutes: 10);
  static final Map<String, _StaffAttendanceCacheEntry> _attendanceCacheByKey =
      <String, _StaffAttendanceCacheEntry>{};

  /// Guards against a slow, superseded visible-roster-status fetch
  /// clobbering a newer one's result.
  int _visibleAttendanceFetchToken = 0;
  Set<String> _lastVisibleAttendanceCodes = <String>{};

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _attendanceCacheKeyForRoomToday() {
    final classroomCode = (state.lastClassroomCode ?? '').trim();
    final date = _formatDate(AppTime.now());
    return 'staff:$classroomCode:$date';
  }

  /// Clears the process-wide today's-attendance cache shared by every
  /// [ClassroomStaffCubit] instance. Called on school switch so a newly
  /// selected school never shows the previous school's cached attendance
  /// status.
  static void clearAttendanceStatusCache() {
    _attendanceCacheByKey.clear();
  }

  /// Fetches today's sign-in status for [visibleStaffCodes] — the currently
  /// visible (post-filter) roster — serving a cached result (10-minute TTL,
  /// shared across cubit instances) when available before deciding whether a
  /// fresh fetch is even needed. Unlike the students-tab equivalent, staff's
  /// attendance-status filter (Expected/Present/Absent) reads fields already
  /// present on the roster item itself, not this map, so scoping the fetch
  /// to the visible subset can't hide a not-yet-fetched row behind its own
  /// filter.
  Future<void> refreshAttendanceStatusForVisible(
    List<String> visibleStaffCodes,
  ) async {
    final codes = visibleStaffCodes
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toSet();

    final cacheKey = _attendanceCacheKeyForRoomToday();
    final cached = _attendanceCacheByKey[cacheKey];
    if (cached != null &&
        AppTime.nowUtc().difference(cached.fetchedAt) <= _attendanceCacheTtl) {
      if (!isClosed) {
        emit(
          state.copyWith(
            attendanceStatusByStaffCode: Map<String, String>.from(
              cached.statusByCode,
            ),
            attendanceStatusLoading: false,
            attendanceStatusError: false,
          ),
        );
      }
    }

    if (codes.isEmpty) {
      _lastVisibleAttendanceCodes = <String>{};
      if (!isClosed) {
        emit(
          state.copyWith(
            attendanceStatusByStaffCode: const <String, String>{},
            attendanceStatusLoading: false,
            attendanceStatusError: false,
          ),
        );
      }
      return;
    }

    if (_setEquals(codes, _lastVisibleAttendanceCodes)) return;
    _lastVisibleAttendanceCodes = codes;

    final token = ++_visibleAttendanceFetchToken;
    if (!isClosed) {
      emit(
        state.copyWith(
          attendanceStatusLoading: true,
          attendanceStatusError: false,
        ),
      );
    }

    try {
      final map = await _getStaffTodaySignInStatusMapUseCase(
        staffCodes: codes.toList(),
      );
      if (isClosed || token != _visibleAttendanceFetchToken) return;
      emit(
        state.copyWith(
          attendanceStatusByStaffCode: Map<String, String>.from(map),
          attendanceStatusLoading: false,
          attendanceStatusError: false,
        ),
      );
      _attendanceCacheByKey[cacheKey] = _StaffAttendanceCacheEntry(
        fetchedAt: AppTime.nowUtc(),
        statusByCode: Map<String, String>.from(map),
      );
    } catch (_) {
      if (isClosed || token != _visibleAttendanceFetchToken) return;
      emit(
        state.copyWith(
          attendanceStatusByStaffCode: const <String, String>{},
          attendanceStatusLoading: false,
          attendanceStatusError: true,
        ),
      );
    }
  }

  /// Fetches today's sign-in status for just [selectedCodes] — always a
  /// live fetch, no TTL cache — used to re-check the CURRENTLY SELECTED
  /// staff immediately after a selection change, ahead of whatever the next
  /// visible-roster refresh happens to pick up.
  Future<void> refreshAttendanceStatusForSelection(
    List<String> selectedCodes,
  ) async {
    final codes = selectedCodes.where((c) => c.trim().isNotEmpty).toList();
    if (codes.isEmpty) {
      if (!isClosed) {
        emit(
          state.copyWith(
            attendanceStatusByStaffCode: const <String, String>{},
            attendanceStatusLoading: false,
            attendanceStatusError: false,
          ),
        );
      }
      return;
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          attendanceStatusLoading: true,
          attendanceStatusError: false,
        ),
      );
    }

    try {
      final map = await _getStaffTodaySignInStatusMapUseCase(staffCodes: codes);
      if (isClosed) return;
      emit(
        state.copyWith(
          attendanceStatusByStaffCode: Map<String, String>.from(map),
          attendanceStatusLoading: false,
          attendanceStatusError: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          attendanceStatusByStaffCode: const <String, String>{},
          attendanceStatusLoading: false,
          attendanceStatusError: true,
        ),
      );
    }
  }

  /// Invalidates the TTL cache entry for the current room+today (so the
  /// next [refreshAttendanceStatusForVisible] call doesn't serve stale
  /// data), clears the displayed attendance-status state, and resets the
  /// dedupe guard so that next call is guaranteed to actually fetch. Called
  /// whenever the View knows the underlying attendance data just changed
  /// (room switch, external refresh, post sign-in/out/transfer/absent
  /// action).
  void invalidateAttendanceStatus() {
    _attendanceCacheByKey.remove(_attendanceCacheKeyForRoomToday());
    _lastVisibleAttendanceCodes = <String>{};
    if (!isClosed) {
      emit(
        state.copyWith(
          attendanceStatusByStaffCode: const <String, String>{},
          attendanceStatusLoading: false,
          attendanceStatusError: false,
        ),
      );
    }
  }

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  static String staffListRequestKey({
    required String classroomCode,
    String? search,
    List<String>? status,
    List<String>? designation,
  }) {
    final st =
        List<String>.from(status ?? const <String>[])
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    final des =
        List<String>.from(designation ?? const <String>[])
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    return [
      classroomCode.trim(),
      's=${(search ?? '').trim().toLowerCase()}',
      'st=${st.join(',')}',
      'des=${des.join(',')}',
    ].join('|');
  }

  Future<void> loadInitial({
    required String classroomCode,
    String? search,
    List<String>? status,
    List<String>? designation,
  }) async {
    if (state.isLoading) return;

    final key = staffListRequestKey(
      classroomCode: classroomCode,
      search: search,
      status: status,
      designation: designation,
    );
    final preserve =
        key == _lastSuccessfulStaffListKey && state.staff.isNotEmpty;

    emit(
      state.copyWith(
        staff: preserve ? state.staff : [],
        isLoading: !preserve,
        isRefreshing: false,
        errorMessage: null,
        lastClassroomCode: classroomCode,
      ),
    );

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';

      final items = await _getStaffClassroomsUseCase(
        schoolCode: schoolCode,
        primaryClassroomCodes: [classroomCode],
        search: search,
        status: status,
        designation: designation,
        refresh: true,
      );

      if (isClosed) return;
      _lastSuccessfulStaffListKey = key;
      emit(
        state.copyWith(
          staff: items,
          isLoading: false,
          isRefreshing: false,
          errorMessage: null,
          lastClassroomCode: classroomCode,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
          lastClassroomCode: classroomCode,
        ),
      );
    }
  }

  Future<void> refresh({
    required String classroomCode,
    String? search,
    List<String>? status,
    List<String>? designation,
  }) async {
    if (state.isRefreshing) return;

    final key = staffListRequestKey(
      classroomCode: classroomCode,
      search: search,
      status: status,
      designation: designation,
    );

    emit(
      state.copyWith(
        isRefreshing: true,
        errorMessage: null,
        lastClassroomCode: classroomCode,
      ),
    );

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';

      final items = await _getStaffClassroomsUseCase(
        schoolCode: schoolCode,
        primaryClassroomCodes: [classroomCode],
        search: search,
        status: status,
        designation: designation,
        refresh: true,
      );

      if (isClosed) return;
      _lastSuccessfulStaffListKey = key;
      emit(
        state.copyWith(
          staff: items,
          isLoading: false,
          isRefreshing: false,
          errorMessage: null,
          lastClassroomCode: classroomCode,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
          lastClassroomCode: classroomCode,
        ),
      );
    }
  }

  static List<StaffClassroomItem> applyClientFilters(
    List<StaffClassroomItem> staff, {
    String? searchText,
    List<String>? designation,
  }) {
    final q = (searchText ?? '').trim().toLowerCase();
    final des = (designation ?? [])
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    return staff.where((s) {
      if (q.isNotEmpty && !s.fullName.toLowerCase().contains(q)) return false;
      if (des.isNotEmpty && !des.contains(s.designation.toUpperCase())) {
        return false;
      }
      return true;
    }).toList();
  }
}
