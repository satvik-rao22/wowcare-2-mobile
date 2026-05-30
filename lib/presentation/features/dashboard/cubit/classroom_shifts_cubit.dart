import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/scheduling/entities/classroom_forecast_block.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_ratio_monitoring_classrooms_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_classroom_forecast_usecase.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/presentation/features/scheduling/model/scheduling_models.dart';
import 'package:wowcare/presentation/features/scheduling/utils/forecast_slot_mapper.dart';
import 'package:wowcare/presentation/features/scheduling/utils/school_hours_resolver.dart';
part 'classroom_shifts_state.dart';

/// One classroom row in the Classroom Shifts dashboard card.
class ClassroomShiftEntry extends Equatable {
  const ClassroomShiftEntry({
    required this.classroomCode,
    required this.name,
    required this.ratioStatus,
  });

  final String classroomCode;
  final String name;

  /// Derived from forecast `blockStatus` using the same logic as the
  /// scheduling page: [ForecastSlotMapper.ratioFromBlocksForWeek].
  final ClassroomRatioStatus ratioStatus;

  @override
  List<Object?> get props => [classroomCode, name, ratioStatus];
}

/// Cubit that powers [ClassroomShiftsCard].
///
/// Uses the **exact same** API chain as the scheduling page:
/// 1. School regular schedules → resolve `startTime/endTime/durationMinutes`
/// 2. Classroom forecast API → list of [ClassroomForecastBlock] per classroom
/// 3. [ForecastSlotMapper.ratioFromBlocksForWeek] → [ClassroomRatioStatus]
///    (only `withinMonitoringWindow` blocks are considered; skips zero-count
///    blocks; any `underRatio` block marks the classroom as under-ratio)
class ClassroomShiftsCubit extends Cubit<ClassroomShiftsState> {
  ClassroomShiftsCubit({
    required GetRatioMonitoringClassroomsUseCase
    getRatioMonitoringClassroomsUseCase,
    required GetClassroomForecastUseCase getClassroomForecastUseCase,
    required StaffRepository staffRepository,
    required StorageService storageService,
  }) : _getClassrooms = getRatioMonitoringClassroomsUseCase,
       _getForecast = getClassroomForecastUseCase,
       _staffRepository = staffRepository,
       _storage = storageService,
       super(const ClassroomShiftsState.initial());

  final GetRatioMonitoringClassroomsUseCase _getClassrooms;
  final GetClassroomForecastUseCase _getForecast;
  final StaffRepository _staffRepository;
  final StorageService _storage;

  bool _isFetching = false;

  String? _schoolCode;
  String? _organizationCode;

  Future<String> _resolveSchoolCode() async {
    _schoolCode ??=
        (await _storage.getString(StorageKeys.schoolCode))?.trim() ?? '';
    return _schoolCode!;
  }

  Future<String> _resolveOrganizationCode() async {
    _organizationCode ??=
        (await _storage.getString(StorageKeys.organizationCode))?.trim() ?? '';
    return _organizationCode!;
  }

  /// Load classroom ratio statuses for [date].
  ///
  /// Mirrors [SchedulingCubit._buildClassroomsWithForecast]:
  /// - Fetches school regular schedules to get the proper forecast time window
  /// - Calls the forecast API with real school hours + block duration
  /// - Derives [ClassroomRatioStatus] via [ForecastSlotMapper.ratioFromBlocksForWeek]
  Future<void> load(DateTime date) async {
    if (_isFetching) return;
    _isFetching = true;
    emit(state.copyWith(status: ClassroomShiftsStatus.loading, date: date));

    try {
      final schoolCode = await _resolveSchoolCode();
      final organizationCode = await _resolveOrganizationCode();

      if (schoolCode.isEmpty || organizationCode.isEmpty) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: ClassroomShiftsStatus.error,
              errorMessage: 'School context missing. Please sign in again.',
            ),
          );
        }
        return;
      }

      // ── Phase 1: classroom list + school hours (in parallel) ──────────────
      final results = await Future.wait([
        _getClassrooms(schoolCode: schoolCode),
        _staffRepository.getSchoolRegularSchedules(schoolCode: schoolCode),
      ]);

      final classrooms =
          results[0] as List<dynamic>; // RatioMonitoringClassroomItem
      final scheduleDays = results[1] as List<dynamic>;

      if (classrooms.isEmpty) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: ClassroomShiftsStatus.loaded,
              entries: const [],
            ),
          );
        }
        return;
      }

      // ── Phase 2: resolve school hours for [date] ──────────────────────────
      final resolver = SchoolHoursResolver.fromDays(scheduleDays.cast());
      final schoolHours = resolver.hoursFor(date);

      // Fall back to a full-day window when no schedule is configured.
      final startTime =
          schoolHours?.startTimeOfDay ?? const TimeOfDay(hour: 6, minute: 0);
      final endTime =
          schoolHours?.endTimeOfDay ?? const TimeOfDay(hour: 22, minute: 0);
      final blockMinutes = schoolHours?.durationMinutes ?? 30;

      // ── Phase 3: forecast for all classrooms on [date] ────────────────────
      final codes = classrooms.map((c) => c.code as String).toList();

      final forecastBlocks = await _getForecast(
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        date: date,
        startTime: startTime,
        endTime: endTime,
        durationMinutes: blockMinutes,
        classroomCodes: codes,
      );

      // Group blocks by classroom code.
      final blocksByClassroom = <String, List<ClassroomForecastBlock>>{};
      for (final block in forecastBlocks) {
        final code = block.classroomCode.trim();
        if (code.isEmpty) continue;
        blocksByClassroom.putIfAbsent(code, () => []).add(block);
      }

      // ── Phase 4: derive ratio status per classroom ────────────────────────
      // Uses ForecastSlotMapper.ratioFromBlocksForWeek — same function as the
      // scheduling page. Only withinMonitoringWindow blocks are considered;
      // any underRatio block marks the classroom as under-ratio.
      final entries = classrooms.map((c) {
        final code = c.code as String;
        final ratioStatus = ForecastSlotMapper.ratioFromBlocksForWeek(
          blocksByClassroom[code] ?? const [],
          filterDate: date,
        );
        return ClassroomShiftEntry(
          classroomCode: code,
          name: c.name as String,
          ratioStatus: ratioStatus,
        );
      }).toList();

      if (!isClosed) {
        emit(
          state.copyWith(
            status: ClassroomShiftsStatus.loaded,
            entries: entries,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: ClassroomShiftsStatus.error,
            errorMessage: ApiErrorHandler.extractErrorMessage(e),
          ),
        );
      }
    } finally {
      _isFetching = false;
    }
  }
}
