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
    required GetStudentAttendanceSummaryByClassroomsUseCase getStudentAttendanceSummaryByClassroomsUseCase,
    required GetStaffAttendanceSummaryByClassroomsUseCase getStaffAttendanceSummaryByClassroomsUseCase,
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

  /// Loads ratio monitoring data.
  ///
  /// - First load (no cached data): emits loading → shimmer shown.
  /// - Navigate back (has data, [isSilent] = true): keeps old rows visible,
  ///   silently refreshes in background.
  /// - [forceRefresh]: clears caches, shows shimmer again (pull-to-refresh).
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

    if (_isFetching) return;
    _isFetching = true;

    // Show loading shimmer only when we have no data OR on a forced refresh.
    if (!isSilent && (!state.isLoaded || forceRefresh)) {
      emit(state.copyWith(
        status: RatioMonitoringStatus.loading,
        classrooms: forceRefresh ? const [] : state.classrooms,
        schoolCode: forceRefresh ? '' : state.schoolCode,
        errorMessage: null,
      ));
    }

    try {
      if (forceRefresh) {
        await _cacheManager.invalidateCache(
          CacheManager.buildCacheKey(
            feature: 'classroom',
            resource: 'ratio_classrooms',
            identifier: code,
          ),
        );
      }

      // Step 1 — fetch classroom list (cached after first hit).
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
        return;
      }

      // Step 2 — extract codes and fetch both attendance summaries in parallel.
      final codes = classrooms.map((c) => c.code).toList();

      final results = await Future.wait([
        _getStudentAttendanceSummaryByClassroomsUseCase(classroomCodes: codes),
        _getStaffAttendanceSummaryByClassroomsUseCase(classroomCodes: codes),
      ]);

      final studentMap = results[0];
      final staffMap = results[1];

      // Step 3 — merge into aggregate entities.
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
    } catch (e) {
      if (!isClosed) {
        // Preserve existing loaded data on error — card stays populated.
        emit(state.copyWith(
          status: state.isLoaded
              ? RatioMonitoringStatus.loaded
              : RatioMonitoringStatus.error,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ));
      }
    } finally {
      _isFetching = false;
    }
  }
}
