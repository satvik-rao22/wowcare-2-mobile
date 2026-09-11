import 'package:bloc/bloc.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/app_time.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/storage_keys.dart';
import '../../../../domain/features/activity/usecases/get_nap_start_students_usecase.dart';
import '../../../../domain/features/attendance/usecases/get_student_today_sign_in_status_map_usecase.dart';
import '../../../../domain/features/student_classroom/entities/student_classroom_item.dart';
import '../../../../domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import 'classroom_students_state.dart';

class _AttendanceCacheEntry {
  const _AttendanceCacheEntry({
    required this.fetchedAt,
    required this.statusByCode,
  });

  final DateTime fetchedAt;
  final Map<String, String> statusByCode;
}

class ClassroomStudentsCubit extends Cubit<ClassroomStudentsState> {
  ClassroomStudentsCubit({
    required GetStudentClassroomListUseCase getStudentClassroomListUseCase,
    required GetNapStartStudentsUseCase getNapStartStudentsUseCase,
    required GetStudentTodaySignInStatusMapUseCase
    getStudentTodaySignInStatusMapUseCase,
    required StorageService storageService,
  }) : _getStudentClassroomListUseCase = getStudentClassroomListUseCase,
       _getNapStartStudentsUseCase = getNapStartStudentsUseCase,
       _getStudentTodaySignInStatusMapUseCase =
           getStudentTodaySignInStatusMapUseCase,
       _storageService = storageService,
       super(const ClassroomStudentsState.initial());

  final GetStudentClassroomListUseCase _getStudentClassroomListUseCase;
  final GetNapStartStudentsUseCase _getNapStartStudentsUseCase;
  final GetStudentTodaySignInStatusMapUseCase
  _getStudentTodaySignInStatusMapUseCase;
  final StorageService _storageService;

  String? _lastSuccessfulStudentListKey;

  /// Shared across every [ClassroomStudentsCubit] instance (this cubit is
  /// registered as a fresh instance per screen visit) so switching tabs and
  /// coming back doesn't re-pay the roster-wide status fetch within the TTL
  /// window. Cleared on school switch via [clearAttendanceStatusCache].
  static const Duration _attendanceCacheTtl = Duration(minutes: 10);
  static final Map<String, _AttendanceCacheEntry> _attendanceCacheByKey =
      <String, _AttendanceCacheEntry>{};

  /// Guards against a slow, superseded roster-status fetch clobbering a
  /// newer one's result.
  int _visibleAttendanceFetchToken = 0;
  Set<String> _lastVisibleAttendanceCodes = <String>{};

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _attendanceCacheKeyForRoomToday() {
    final classroomCode = (state.lastClassroomCode ?? '').trim();
    final date = _formatDate(AppTime.now());
    return 'students:$classroomCode:$date';
  }

  /// Clears the process-wide today's-attendance cache shared by every
  /// [ClassroomStudentsCubit] instance. Called on school switch so a newly
  /// selected school never shows the previous school's cached attendance
  /// status.
  static void clearAttendanceStatusCache() {
    _attendanceCacheByKey.clear();
  }

  /// Fetches today's sign-in status for the **whole roster** for the room,
  /// serving a cached result (10-minute TTL, shared across cubit instances)
  /// when available before deciding whether a fresh fetch is even needed.
  ///
  /// Must be passed the unfiltered roster ([ClassroomStudentsState.students]),
  /// never a post-filter subset. The "Present" filter itself reads
  /// [ClassroomStudentsState.attendanceStatusByStudentCode]; if status were
  /// fetched only for students already passing the filter, a signed-in
  /// student whose status isn't in the map yet would be dropped before their
  /// status is ever requested — and stay hidden permanently (e.g. after
  /// toggling Napping).
  Future<void> refreshAttendanceStatusForRoster(
    List<StudentClassroomItem> rosterStudents,
  ) async {
    final codes = rosterStudents
        .map((s) => s.studentCode.trim())
        .where((c) => c.isNotEmpty)
        .toSet();

    final cacheKey = _attendanceCacheKeyForRoomToday();
    final cached = _attendanceCacheByKey[cacheKey];
    if (cached != null &&
        AppTime.nowUtc().difference(cached.fetchedAt) <= _attendanceCacheTtl) {
      if (!isClosed) {
        emit(
          state.copyWith(
            attendanceStatusByStudentCode: Map<String, String>.from(
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
            attendanceStatusByStudentCode: const <String, String>{},
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
      final map = await _getStudentTodaySignInStatusMapUseCase(
        studentCodes: codes.toList(),
      );
      if (isClosed || token != _visibleAttendanceFetchToken) return;
      emit(
        state.copyWith(
          attendanceStatusByStudentCode: Map<String, String>.from(map),
          attendanceStatusLoading: false,
          attendanceStatusError: false,
        ),
      );
      _attendanceCacheByKey[cacheKey] = _AttendanceCacheEntry(
        fetchedAt: AppTime.nowUtc(),
        statusByCode: Map<String, String>.from(map),
      );
    } catch (_) {
      if (isClosed || token != _visibleAttendanceFetchToken) return;
      emit(
        state.copyWith(
          attendanceStatusByStudentCode: const <String, String>{},
          attendanceStatusLoading: false,
          attendanceStatusError: true,
        ),
      );
    }
  }

  /// Fetches today's sign-in status for just [selectedCodes] — always a
  /// live fetch, no TTL cache — used to re-check the CURRENTLY SELECTED
  /// students immediately after a selection change, ahead of whatever the
  /// next roster-wide refresh happens to pick up. No fetch-token guard,
  /// matching the original View-side behaviour (a rapid selection change
  /// can still race a slightly slower earlier fetch — pre-existing).
  Future<void> refreshAttendanceStatusForSelection(
    List<String> selectedCodes,
  ) async {
    final codes = selectedCodes.where((c) => c.trim().isNotEmpty).toList();
    if (codes.isEmpty) {
      if (!isClosed) {
        emit(
          state.copyWith(
            attendanceStatusByStudentCode: const <String, String>{},
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
      final map = await _getStudentTodaySignInStatusMapUseCase(
        studentCodes: codes,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          attendanceStatusByStudentCode: Map<String, String>.from(map),
          attendanceStatusLoading: false,
          attendanceStatusError: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          attendanceStatusByStudentCode: const <String, String>{},
          attendanceStatusLoading: false,
          attendanceStatusError: true,
        ),
      );
    }
  }

  /// Invalidates the TTL cache entry for the current room+today (so the
  /// next [refreshAttendanceStatusForRoster] call doesn't serve stale data),
  /// clears the displayed attendance-status state, and resets the dedupe
  /// guard so that next call is guaranteed to actually fetch. Called
  /// whenever the View knows the underlying attendance data just changed
  /// (room switch, external refresh, post sign-in/out/transfer/absent
  /// action, post-activity-recorded refresh).
  void invalidateAttendanceStatus() {
    _attendanceCacheByKey.remove(_attendanceCacheKeyForRoomToday());
    _lastVisibleAttendanceCodes = <String>{};
    if (!isClosed) {
      emit(
        state.copyWith(
          attendanceStatusByStudentCode: const <String, String>{},
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

  /// Guards against a slow, superseded nap-codes fetch clobbering a newer
  /// one's result (e.g. rapid classroom switching).
  int _napCodesFetchToken = 0;

  /// Fetches which students in [classroomCode] are currently on a nap.
  /// [refresh] is accepted for call-site symmetry with [loadInitial]/
  /// [refresh] but — matching this endpoint's original View-side
  /// behaviour — isn't currently forwarded to the use case (no
  /// cache-bypass parameter exists on it).
  Future<void> loadNapStartStudentCodes({
    required String classroomCode,
    required bool refresh,
  }) async {
    final code = classroomCode.trim();
    if (code.isEmpty) return;

    final token = ++_napCodesFetchToken;
    if (!isClosed) emit(state.copyWith(napCodesLoading: true));

    try {
      final codes = await _getNapStartStudentsUseCase(classroomCode: code);
      final normalized = codes
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toSet();

      if (isClosed || token != _napCodesFetchToken) return;
      emit(state.copyWith(nappingStudentCodes: normalized));
    } catch (_) {
      // Keep the existing set on failure to avoid flicker.
      if (isClosed || token != _napCodesFetchToken) return;
    } finally {
      if (!isClosed && token == _napCodesFetchToken) {
        emit(state.copyWith(napCodesLoading: false));
      }
    }
  }

  static String studentListRequestKey({
    required String classroomCode,
    String? search,
    List<String>? studentCodes,
    List<String>? status,
    List<String>? tagCodes,
  }) {
    final sc =
        List<String>.from(studentCodes ?? const <String>[])
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    final st =
        List<String>.from(status ?? const <String>[])
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    final tg = List<String>.from(
      tagCodes ?? const <String>[],
    ).map((e) => e.trim()).where((e) => e.isNotEmpty).toList()..sort();
    return [
      classroomCode.trim(),
      's=${(search ?? '').trim().toLowerCase()}',
      'sc=${sc.join(',')}',
      'st=${st.join(',')}',
      'tg=${tg.join(',')}',
    ].join('|');
  }

  Future<void> loadInitial({
    required String classroomCode,
    String? search,
    List<String>? studentCodes,
    List<String>? status,
    List<String>? tagCodes,
    // When true, bypasses the repository's roster cache even though this
    // still goes through the "clear immediately on a different request" UX
    // below — used when switching to a classroom whose cached roster may be
    // stale (e.g. a student was just transferred into it elsewhere in the
    // app), as opposed to a plain first-mount load where a recent cache hit
    // is fine.
    bool forceRefresh = false,
  }) async {
    if (state.isLoading) return;

    final key = studentListRequestKey(
      classroomCode: classroomCode,
      search: search,
      studentCodes: studentCodes,
      status: status,
      tagCodes: tagCodes,
    );
    final preserve =
        key == _lastSuccessfulStudentListKey && state.students.isNotEmpty;

    emit(
      state.copyWith(
        students: preserve ? state.students : [],
        isLoading: !preserve,
        isRefreshing: false,
        errorMessage: null,
        lastClassroomCode: classroomCode,
      ),
    );

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      final items = await _getStudentClassroomListUseCase(
        schoolCode: schoolCode,
        classroomCode: classroomCode,
        search: search,
        studentCodes: studentCodes,
        status: status,
        tagCodes: tagCodes,
        refresh: forceRefresh,
      );

      if (isClosed) return;
      _lastSuccessfulStudentListKey = key;
      emit(
        state.copyWith(
          students: items,
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
    List<String>? studentCodes,
    List<String>? status,
    List<String>? tagCodes,
  }) async {
    if (state.isRefreshing) return;

    final key = studentListRequestKey(
      classroomCode: classroomCode,
      search: search,
      studentCodes: studentCodes,
      status: status,
      tagCodes: tagCodes,
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
      final items = await _getStudentClassroomListUseCase(
        schoolCode: schoolCode,
        classroomCode: classroomCode,
        search: search,
        studentCodes: studentCodes,
        status: status,
        tagCodes: tagCodes,
        refresh: true,
      );

      if (isClosed) return;
      _lastSuccessfulStudentListKey = key;
      emit(
        state.copyWith(
          students: items,
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

  static List<StudentClassroomItem> applyClientFilters(
    List<StudentClassroomItem> students, {
    bool presentOnly = false,
    bool nappingOnly = false,
    String? searchText,
  }) {
    final q = (searchText ?? '').trim().toLowerCase();

    return students.where((s) {
      if (presentOnly && !s.signedIn) return false;
      if (nappingOnly && !s.nap) return false;
      if (q.isNotEmpty && !s.fullName.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }
}
