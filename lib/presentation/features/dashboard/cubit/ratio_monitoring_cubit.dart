import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/entities/ratio_monitoring_classroom.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_ratio_monitoring_classrooms_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_staff_shifts_usecase.dart';

part 'ratio_monitoring_state.dart';

class RatioMonitoringCubit extends Cubit<RatioMonitoringState> {
  RatioMonitoringCubit({
    required GetRatioMonitoringClassroomsUseCase getRatioMonitoringClassroomsUseCase,
    required GetStudentAttendanceSummaryByClassroomsUseCase
        getStudentAttendanceSummaryByClassroomsUseCase,
    required GetStaffAttendanceSummaryByClassroomsUseCase
        getStaffAttendanceSummaryByClassroomsUseCase,
    required CacheManager cacheManager,
    required StorageService storageService,
    required GetStaffShiftsUseCase getStaffShiftsUseCase,
  })  : _getRatioMonitoringClassroomsUseCase = getRatioMonitoringClassroomsUseCase,
        _getStudentAttendanceSummaryByClassroomsUseCase =
            getStudentAttendanceSummaryByClassroomsUseCase,
        _getStaffAttendanceSummaryByClassroomsUseCase =
            getStaffAttendanceSummaryByClassroomsUseCase,
        _cacheManager = cacheManager,
        _storage = storageService,
        _getStaffShiftsUseCase = getStaffShiftsUseCase,
        super(const RatioMonitoringState.initial());

  final GetRatioMonitoringClassroomsUseCase _getRatioMonitoringClassroomsUseCase;
  final GetStudentAttendanceSummaryByClassroomsUseCase
      _getStudentAttendanceSummaryByClassroomsUseCase;
  final GetStaffAttendanceSummaryByClassroomsUseCase
      _getStaffAttendanceSummaryByClassroomsUseCase;
  final CacheManager _cacheManager;
  final StorageService _storage;
  final GetStaffShiftsUseCase _getStaffShiftsUseCase;

  bool _isFetching = false;

  /// Last completed fetch timestamp — used by callers to implement cooldowns.
  DateTime? get lastFetchAt => _lastFetchAt;
  DateTime? _lastFetchAt;

  // ── Staff shift classroom cache ─────────────────────────────────────────────
  // Shift classroom codes are memory-cached per week so they are not
  // re-fetched on every rebuild. The cache is invalidated:
  //   • on pull-to-refresh (forceRefresh=true)
  //   • when the ISO week changes (Monday rollover)
  Set<String> _cachedShiftClassroomCodes = const {};
  DateTime? _shiftCacheWeekStart;

  static const _shiftCacheTtl = Duration(minutes: 30);

  bool _isShiftCacheValid() {
    final cached = _shiftCacheWeekStart;
    if (cached == null) return false;
    final currentWeekStart = _mondayOf(DateTime.now());
    // Invalidate if the Monday has changed or TTL has expired.
    if (cached.year != currentWeekStart.year ||
        cached.month != currentWeekStart.month ||
        cached.day != currentWeekStart.day) {
      return false;
    }
    // TTL guard: re-fetch after 30 min to pick up shift changes.
    if (_lastFetchAt != null &&
        DateTime.now().difference(_lastFetchAt!) > _shiftCacheTtl) {
      return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads ratio monitoring data for [schoolCode].
  ///
  /// **Staff persona**: the classroom list is automatically scoped to the
  /// union of:
  ///   • classrooms from `staffAllowedClassroomCodes` storage (set at login)
  ///   • classrooms assigned via the staff-shifts API for the current week
  ///
  /// **Admin / director persona**: all classrooms are shown (no filtering).
  ///
  /// Load strategy:
  ///
  /// **First open** (`state.isInitial`):
  ///   Phase 1 — fetch classroom list → emit loaded state with all classrooms
  ///   at 0 counts so the table rows are immediately visible.
  ///   Phase 2 — fetch attendance data in parallel → update rows with live counts.
  ///
  /// **Silent background refresh** (`isSilent = true`, data already present):
  ///   No shimmer, no intermediate 0-state. Data updates atomically when both
  ///   attendance APIs respond.
  ///
  /// **Pull-to-refresh** (`forceRefresh = true`):
  ///   Invalidates classroom cache and shift cache, shows shimmer, full re-fetch.
  Future<void> loadRatioMonitoring({
    required String schoolCode,
    bool forceRefresh = false,
    bool isSilent = false,
    DateTime? date,
  }) async {
    final code = schoolCode.trim();
    if (code.isEmpty) {
      emit(const RatioMonitoringState.initial());
      return;
    }

    // Guard against concurrent fetches.
    if (_isFetching) return;
    _isFetching = true;

    // Show shimmer only when: not silent AND (no data yet OR force-refresh).
    if (!isSilent && (!state.isLoaded || forceRefresh)) {
      emit(state.copyWith(
        status: RatioMonitoringStatus.loading,
        classrooms: forceRefresh ? const [] : state.classrooms,
        schoolCode: forceRefresh ? '' : state.schoolCode,
        errorMessage: null,
      ));
    }

    // Invalidate classroom cache on explicit force-refresh.
    if (forceRefresh) {
      await _cacheManager.invalidateCache(
        CacheManager.buildCacheKey(
          feature: 'classroom',
          resource: 'ratio_classrooms',
          identifier: code,
        ),
      );
      // Also invalidate shift cache.
      _shiftCacheWeekStart = null;
      _cachedShiftClassroomCodes = const {};
    }

    try {
      // ── Resolve staff classroom scope (staff persona only) ────────────────
      final scope = await _resolveClassroomScope(schoolCode: code);

      // ── Phase 1: Fetch classroom master list ──────────────────────────────
      final allClassrooms = await _getRatioMonitoringClassroomsUseCase(
        schoolCode: code,
      );

      // Apply scope filter for staff users.
      final classrooms = scope.isScoped
          ? allClassrooms
              .where((c) => scope.contains(c.code))
              .toList(growable: false)
          : allClassrooms;

      if (classrooms.isEmpty) {
        if (!isClosed) {
          emit(RatioMonitoringState.loaded(
            schoolCode: code,
            classrooms: const [],
          ));
        }
        _lastFetchAt = DateTime.now();
        return;
      }

      // Phase 1 result: emit all classrooms immediately with 0 counts so the
      // table is never empty while attendance data is still loading.
      // Skip this intermediate emit on silent refresh to avoid visible flicker.
      final hasExistingData = state.isLoaded && state.classrooms.isNotEmpty;
      if (!hasExistingData && !isClosed) {
        emit(RatioMonitoringState.loaded(
          schoolCode: code,
          classrooms: classrooms
              .map(
                (c) => RatioMonitoringClassroom(
                  code: c.code,
                  name: c.name,
                  capacity: c.capacity,
                  allowedRatio: c.allowedRatio,
                  studentPresent: 0,
                  staffPresent: 0,
                ),
              )
              .toList(),
        ));
      }

      // ── Phase 2: Fetch attendance for the (scoped) classroom list ─────────
      final codes = classrooms.map((c) => c.code).toList();

      final results = await Future.wait([
        _getStudentAttendanceSummaryByClassroomsUseCase(
          classroomCodes: codes,
          date: date,
        ),
        _getStaffAttendanceSummaryByClassroomsUseCase(
          classroomCodes: codes,
          date: date,
        ),
      ]);

      final studentMap = results[0];
      final staffMap = results[1];

      // ── Phase 3: Merge classroom list + attendance maps ───────────────────
      final merged = classrooms.map((c) {
        final studentEntry = studentMap[c.code];
        final staffEntry = staffMap[c.code];
        return RatioMonitoringClassroom(
          code: c.code,
          name: c.name,
          capacity: c.capacity,
          allowedRatio: c.allowedRatio,
          studentPresent: studentEntry?.present ?? 0,
          staffPresent: staffEntry?.present ?? 0,
        );
      }).toList();

      if (!isClosed) {
        emit(RatioMonitoringState.loaded(
          schoolCode: code,
          classrooms: merged,
        ));
      }

      _lastFetchAt = DateTime.now();
    } catch (e) {
      if (!isClosed) {
        // On error: if Phase 1 already populated the state with classrooms,
        // keep those rows visible. Only switch to error if we have no data.
        final shouldShowError = !state.isLoaded || state.classrooms.isEmpty;
        emit(state.copyWith(
          status: shouldShowError
              ? RatioMonitoringStatus.error
              : RatioMonitoringStatus.loaded,
          errorMessage: shouldShowError
              ? ApiErrorHandler.extractErrorMessage(e)
              : null,
        ));
      }
    } finally {
      _isFetching = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Staff classroom scope resolution
  // ---------------------------------------------------------------------------

  /// Returns the set of classroom codes the current user may see.
  ///
  /// For admin / director personas the scope is OPEN (no filtering).
  /// For staff personas the scope is the union of:
  ///   • `staffAllowedClassroomCodes` from storage (set at login)
  ///   • classrooms found in staff-shift records for the current week
  ///   (If the shift API fails, the scope falls back to the stored allowed list.)
  Future<_ClassroomScope> _resolveClassroomScope({
    required String schoolCode,
  }) async {
    final isStaff = await _isStaffPersona();
    if (!isStaff) {
      return _ClassroomScope.open();
    }

    // ── Allowed classrooms from storage ────────────────────────────────────
    final allowedCodes = await _resolveAllowedCodesFromStorage();

    // ── Shift classrooms (memory-cached per week) ──────────────────────────
    final shiftCodes = await _resolveShiftClassroomCodes(schoolCode: schoolCode);

    // ── Union ──────────────────────────────────────────────────────────────
    final union = <String>{
      ...allowedCodes,
      ...shiftCodes,
    };

    AppLogger.d(
      '[RatioMonitoringCubit] staff scope — '
      'allowed=${allowedCodes.length} '
      'shifts=${shiftCodes.length} '
      'union=${union.length}',
    );

    return _ClassroomScope.scoped(union);
  }

  /// Returns true when the logged-in user is a non-admin staff persona.
  Future<bool> _isStaffPersona() async {
    // activeSchoolRole distinguishes between 'staff', 'admin', 'parent'.
    final activeRole =
        (await _storage.getString(StorageKeys.activeSchoolRole) ?? '')
            .trim()
            .toUpperCase();

    if (activeRole.isNotEmpty) {
      final isStaffRole =
          activeRole.contains('STAFF') || activeRole.contains('TEACHER');
      if (!isStaffRole) return false;
    }

    // Admins (SCHOOL_ADMIN, ORGANIZATION_ADMIN) see all classrooms.
    final staffType =
        (await _storage.getString(StorageKeys.staffType) ?? '')
            .trim()
            .toUpperCase();
    if (staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN') {
      return false;
    }

    // If no role stored at all, default to unscoped (safe fallback).
    if (activeRole.isEmpty && staffType.isEmpty) return false;

    return true;
  }

  /// Decodes the allowed classroom codes JSON stored at login time.
  Future<Set<String>> _resolveAllowedCodesFromStorage() async {
    final raw =
        (await _storage.getString(StorageKeys.staffAllowedClassroomCodes) ?? '')
            .trim();
    if (raw.isEmpty) return const {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final codes = decoded.map((e) {
          if (e is Map) return (e['code'] ?? '').toString().trim();
          return e.toString().trim();
        }).where((c) => c.isNotEmpty).toSet();
        return codes;
      }
    } catch (e) {
      AppLogger.w('[RatioMonitoringCubit] failed to decode allowedClassroomCodes: $e');
    }
    return const {};
  }

  /// Returns shift classroom codes for the current week, using the
  /// memory cache when valid to avoid repeated API hits.
  Future<Set<String>> _resolveShiftClassroomCodes({
    required String schoolCode,
  }) async {
    if (_isShiftCacheValid()) {
      return _cachedShiftClassroomCodes;
    }

    final staffCode =
        (await _storage.getString(StorageKeys.staffCode) ?? '').trim();
    final organizationCode =
        (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();

    if (staffCode.isEmpty || organizationCode.isEmpty) {
      _cachedShiftClassroomCodes = const {};
      _shiftCacheWeekStart = _mondayOf(DateTime.now());
      return const {};
    }

    final weekStart = _mondayOf(DateTime.now());
    final weekEnd = weekStart.add(const Duration(days: 6));

    try {
      final shifts = await _getStaffShiftsUseCase(
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        dateFrom: weekStart,
        dateTo: weekEnd,
      );

      final codes = shifts
          .map((s) => s.classroomCode.trim())
          .where((c) => c.isNotEmpty)
          .toSet();

      _cachedShiftClassroomCodes = codes;
      _shiftCacheWeekStart = weekStart;

      AppLogger.d(
        '[RatioMonitoringCubit] fetched ${shifts.length} shift(s) → '
        '${codes.length} classroom code(s)',
      );

      return codes;
    } catch (e) {
      AppLogger.w(
        '[RatioMonitoringCubit] shift fetch failed — '
        'falling back to allowed classrooms only: $e',
      );
      // Populate cache with empty set so we don't retry on every rebuild.
      _cachedShiftClassroomCodes = const {};
      _shiftCacheWeekStart = weekStart;
      return const {};
    }
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  /// Returns the Monday of the ISO week that contains [date].
  static DateTime _mondayOf(DateTime date) {
    final day = date.weekday; // 1 = Monday, 7 = Sunday
    return DateTime(date.year, date.month, date.day - (day - 1));
  }
}

// ---------------------------------------------------------------------------
// Classroom scope value object — avoids boolean flag ambiguity.
// ---------------------------------------------------------------------------

class _ClassroomScope {
  const _ClassroomScope._(this._codes, this.isScoped);

  /// No filtering — admin users see all classrooms.
  factory _ClassroomScope.open() => const _ClassroomScope._(null, false);

  /// Staff persona: only classrooms in [codes] are shown.
  factory _ClassroomScope.scoped(Set<String> codes) =>
      _ClassroomScope._(codes, true);

  final Set<String>? _codes;

  /// True when classroom list should be filtered.
  final bool isScoped;

  bool contains(String code) => _codes?.contains(code) ?? true;
}
