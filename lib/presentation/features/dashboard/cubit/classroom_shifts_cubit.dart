import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/scheduling/entities/classroom_forecast_block.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_ratio_monitoring_classrooms_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_classroom_forecast_usecase.dart';
import 'package:wowcare/domain/features/scheduling/entities/staff_shift.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_school_staff_shifts_usecase.dart';
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
    this.staff = const [],
  });

  final String classroomCode;
  final String name;

  /// Derived from forecast `blockStatus` — same logic as the scheduling page.
  final ClassroomRatioStatus ratioStatus;

  /// Staff shifts for this classroom on the loaded date.
  /// Each entry carries the data needed by [StaffRowLeft] and [StaffTimeRangePill].
  final List<StaffScheduleEntry> staff;

  @override
  List<Object?> get props => [classroomCode, name, ratioStatus, staff];
}

/// Cubit that powers [ClassroomShiftsCard].
///
/// Phases (mirrors [SchedulingCubit._buildClassroomsWithForecast]):
/// 1. School regular schedules → resolve `startTime/endTime/durationMinutes`
/// 2. Forecast API → [ClassroomRatioStatus] via [ForecastSlotMapper]
/// 3. Staff-shifts API → [StaffScheduleEntry] list per classroom (same endpoint
///    as the scheduling screen, so data is consistent)
class ClassroomShiftsCubit extends Cubit<ClassroomShiftsState> {
  ClassroomShiftsCubit({
    required GetRatioMonitoringClassroomsUseCase
    getRatioMonitoringClassroomsUseCase,
    required GetClassroomForecastUseCase getClassroomForecastUseCase,
    required GetSchoolStaffShiftsUseCase getSchoolStaffShiftsUseCase,
    required StaffRepository staffRepository,
    required StorageService storageService,
  }) : _getClassrooms = getRatioMonitoringClassroomsUseCase,
       _getForecast = getClassroomForecastUseCase,
       _getStaffShifts = getSchoolStaffShiftsUseCase,
       _staffRepository = staffRepository,
       _storage = storageService,
       super(const ClassroomShiftsState.initial());

  final GetRatioMonitoringClassroomsUseCase _getClassrooms;
  final GetClassroomForecastUseCase _getForecast;
  final GetSchoolStaffShiftsUseCase _getStaffShifts;
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

  Future<void> load(DateTime date) async {
    if (_isFetching) return;
    _isFetching = true;
    emit(state.copyWith(status: ClassroomShiftsStatus.loading, date: date));

    try {
      final schoolCode = await _resolveSchoolCode();
      final organizationCode = await _resolveOrganizationCode();

      if (schoolCode.isEmpty || organizationCode.isEmpty) {
        if (!isClosed) {
          emit(state.copyWith(
            status: ClassroomShiftsStatus.error,
            errorMessage: 'School context missing. Please sign in again.',
          ));
        }
        return;
      }

      // ── Phase 1: classroom list + school hours (parallel) ─────────────────
      final results = await Future.wait([
        _getClassrooms(schoolCode: schoolCode),
        _staffRepository.getSchoolRegularSchedules(schoolCode: schoolCode),
      ]);

      final classrooms = results[0] as List<dynamic>;
      final scheduleDays = results[1] as List<dynamic>;

      if (classrooms.isEmpty) {
        if (!isClosed) {
          emit(state.copyWith(
            status: ClassroomShiftsStatus.loaded,
            entries: const [],
          ));
        }
        return;
      }

      // ── Phase 2: resolve school hours for [date] ──────────────────────────
      final resolver = SchoolHoursResolver.fromDays(scheduleDays.cast());
      final schoolHours = resolver.hoursFor(date);

      final forecastStart = schoolHours?.scheduleMonitorStartTimeOfDay ??
          schoolHours?.startTimeOfDay ??
          const TimeOfDay(hour: 6, minute: 0);
      final forecastEnd = schoolHours?.scheduleMonitorEndTimeOfDay ??
          schoolHours?.endTimeOfDay ??
          const TimeOfDay(hour: 22, minute: 0);
      final blockMinutes = schoolHours?.durationMinutes ?? 30;

      // ── Phase 3: forecast + staff shifts (parallel) ───────────────────────
      final codes = classrooms.map((c) => c.code as String).toList();

      final parallel = await Future.wait([
        _getForecast(
          schoolCode: schoolCode,
          organizationCode: organizationCode,
          date: date,
          startTime: forecastStart,
          endTime: forecastEnd,
          durationMinutes: blockMinutes,
          classroomCodes: codes,
        ),
        _getStaffShifts(
          schoolCode: schoolCode,
          organizationCode: organizationCode,
          dateFrom: date,
          dateTo: date,
        ).catchError((_) => <StaffShift>[]), // non-fatal — UI degrades gracefully
      ]);

      final forecastBlocks = parallel[0] as List<ClassroomForecastBlock>;
      final rawShifts = parallel[1] as List<dynamic>; // List<StaffShift>

      // Group forecast blocks by classroom.
      final blocksByClassroom = <String, List<ClassroomForecastBlock>>{};
      for (final block in forecastBlocks) {
        final code = block.classroomCode.trim();
        if (code.isEmpty) continue;
        blocksByClassroom.putIfAbsent(code, () => []).add(block);
      }

      // Group staff shifts by classroom code → List<StaffScheduleEntry>.
      final staffByClassroom = <String, List<StaffScheduleEntry>>{};
      for (final dynamic raw in rawShifts) {
        final code = (raw.classroomCode as String).trim();
        if (code.isEmpty) continue;
        staffByClassroom.putIfAbsent(code, () => []).add(
          StaffScheduleEntry(
            staffName: raw.staffName as String? ?? '',
            staffCode: raw.staffCode as String? ?? '',
            startTime: _fmtTime(raw.startTime as TimeOfDay),
            endTime: _fmtTime(raw.endTime as TimeOfDay),
            isPublished: raw.isPublished as bool? ?? false,
            shiftCode: raw.shiftCode as String?,
            scheduledHours: (raw.scheduledHours as int? ?? 0).toDouble(),
            availableHours: (raw.availableHours as int? ?? 0).toDouble(),
            unscheduledHours: (raw.unscheduledHours as int? ?? 0).toDouble(),
          ),
        );
      }

      // ── Phase 4: assemble entries ─────────────────────────────────────────
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
          staff: staffByClassroom[code] ?? const [],
        );
      }).toList();

      if (!isClosed) {
        emit(state.copyWith(
          status: ClassroomShiftsStatus.loaded,
          entries: entries,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: ClassroomShiftsStatus.error,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ));
      }
    } finally {
      _isFetching = false;
    }
  }

  /// Converts [TimeOfDay] → "09:00 AM" format expected by [StaffTimeRangePill].
  static String _fmtTime(TimeOfDay t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:$m $period';
  }
}
