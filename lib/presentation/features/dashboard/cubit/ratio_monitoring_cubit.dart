import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/domain/features/classroom/entities/ratio_monitoring_classroom.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_ratio_monitoring_classrooms_usecase.dart';

part 'ratio_monitoring_state.dart';

class RatioMonitoringCubit extends Cubit<RatioMonitoringState> {
  RatioMonitoringCubit({
    required GetRatioMonitoringClassroomsUseCase getRatioMonitoringClassroomsUseCase,
    required GetStudentAttendanceSummaryByClassroomsUseCase
        getStudentAttendanceSummaryByClassroomsUseCase,
    required GetStaffAttendanceSummaryByClassroomsUseCase
        getStaffAttendanceSummaryByClassroomsUseCase,
    required CacheManager cacheManager,
  })  : _getRatioMonitoringClassroomsUseCase = getRatioMonitoringClassroomsUseCase,
        _getStudentAttendanceSummaryByClassroomsUseCase =
            getStudentAttendanceSummaryByClassroomsUseCase,
        _getStaffAttendanceSummaryByClassroomsUseCase =
            getStaffAttendanceSummaryByClassroomsUseCase,
        _cacheManager = cacheManager,
        super(const RatioMonitoringState.initial());

  final GetRatioMonitoringClassroomsUseCase _getRatioMonitoringClassroomsUseCase;
  final GetStudentAttendanceSummaryByClassroomsUseCase
      _getStudentAttendanceSummaryByClassroomsUseCase;
  final GetStaffAttendanceSummaryByClassroomsUseCase
      _getStaffAttendanceSummaryByClassroomsUseCase;
  final CacheManager _cacheManager;

  bool _isFetching = false;

  /// Last completed fetch timestamp — used by callers to implement cooldowns.
  DateTime? get lastFetchAt => _lastFetchAt;
  DateTime? _lastFetchAt;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads ratio monitoring data for [schoolCode].
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
  ///   Invalidates classroom cache, shows shimmer, full re-fetch.
  Future<void> loadRatioMonitoring({
    required String schoolCode,
    bool forceRefresh = false,
    bool isSilent = false,
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

    try {
      // ── Cache invalidation on explicit force-refresh ──────────────────────
      if (forceRefresh) {
        await _cacheManager.invalidateCache(
          CacheManager.buildCacheKey(
            feature: 'classroom',
            resource: 'ratio_classrooms',
            identifier: code,
          ),
        );
      }

      // ── Phase 1: Fetch classroom master list ──────────────────────────────
      final classrooms = await _getRatioMonitoringClassroomsUseCase(
        schoolCode: code,
      );

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

      // ── Phase 2: Fetch attendance for all classrooms in parallel ──────────
      final codes = classrooms.map((c) => c.code).toList();

      final results = await Future.wait([
        _getStudentAttendanceSummaryByClassroomsUseCase(classroomCodes: codes),
        _getStaffAttendanceSummaryByClassroomsUseCase(classroomCodes: codes),
      ]);

      final studentMap = results[0];
      final staffMap = results[1];

      // ── Phase 3: Merge classroom list + attendance maps ───────────────────
      // Every classroom in the master list always produces a row.
      // Missing attendance entries default to 0 — no row is ever suppressed.
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
        // On error: if Phase 1 already populated the state with classrooms
        // (the intermediate 0-count emit), keep those rows visible.
        // Only switch to error status if we have absolutely no data to show.
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
}
