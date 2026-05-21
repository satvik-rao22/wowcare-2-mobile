import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/scheduling/entities/classroom_forecast_block.dart';
import '../../../../domain/features/scheduling/entities/staff_shift.dart';
import '../../../../domain/features/scheduling/usecases/get_classroom_forecast_range_usecase.dart';
import '../../../../domain/features/scheduling/usecases/get_classroom_forecast_usecase.dart';
import '../../../../domain/features/scheduling/usecases/get_school_staff_shifts_usecase.dart';
import '../../../../domain/features/staff/entities/school_regular_schedule_day.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../model/scheduling_models.dart';
import '../utils/forecast_slot_mapper.dart';
import '../utils/school_hours_resolver.dart';

part 'scheduling_state.dart';

class SchedulingCubit extends Cubit<SchedulingState> {
  SchedulingCubit({
    required GetSchoolStaffShiftsUseCase getSchoolStaffShiftsUseCase,
    required GetClassroomForecastUseCase getClassroomForecastUseCase,
    required GetClassroomForecastRangeUseCase getClassroomForecastRangeUseCase,
    required StaffRepository staffRepository,
    required StorageService storageService,
  })  : _getSchoolStaffShiftsUseCase = getSchoolStaffShiftsUseCase,
        _getClassroomForecastUseCase = getClassroomForecastUseCase,
        _getClassroomForecastRangeUseCase = getClassroomForecastRangeUseCase,
        _staffRepository = staffRepository,
        _storageService = storageService,
        super(SchedulingState.initial());

  final GetSchoolStaffShiftsUseCase _getSchoolStaffShiftsUseCase;
  final GetClassroomForecastUseCase _getClassroomForecastUseCase;
  final GetClassroomForecastRangeUseCase _getClassroomForecastRangeUseCase;
  final StaffRepository _staffRepository;
  final StorageService _storageService;

  String? _schoolCode;
  String? _organizationCode;
  SchoolHoursResolver? _schoolHoursResolver;

  Map<String, String> _classroomNamesByCode = const {};
  List<String> _allClassroomCodes = const [];
  List<StaffShift> _lastShifts = const [];

  Future<String> _resolveSchoolCode() async {
    if (_schoolCode != null) return _schoolCode!;
    _schoolCode = await _storageService.getString(StorageKeys.schoolCode) ?? '';
    return _schoolCode!;
  }

  Future<String> _resolveOrganizationCode() async {
    if (_organizationCode != null) return _organizationCode!;
    _organizationCode =
        await _storageService.getString(StorageKeys.organizationCode) ?? '';
    return _organizationCode!;
  }

  /// Loads regular-schedule, shifts, and forecast data for [selectedDay].
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final schoolCode = await _resolveSchoolCode();
      final organizationCode = await _resolveOrganizationCode();

      if (schoolCode.isEmpty || organizationCode.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            classrooms: const <ClassroomDaySchedule>[],
            errorMessage: 'School context is missing. Please sign in again.',
          ),
        );
        return;
      }

      final day = state.selectedDay;

      final results = await Future.wait<dynamic>([
        _getSchoolStaffShiftsUseCase(
          schoolCode: schoolCode,
          organizationCode: organizationCode,
          dateFrom: day,
          dateTo: day,
        ),
        _staffRepository.getSchoolRegularSchedules(schoolCode: schoolCode),
      ]);

      if (isClosed) return;

      final shifts = results[0] as List<StaffShift>;
      _schoolHoursResolver = SchoolHoursResolver.fromDays(
        results[1] as List<SchoolRegularScheduleDay>,
      );

      _lastShifts = shifts;
      final classrooms = await _buildClassroomsWithForecast(
        shifts: shifts,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        day: day,
      );

      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          classrooms: classrooms,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  Future<List<ClassroomDaySchedule>> _buildClassroomsWithForecast({
    required List<StaffShift> shifts,
    required String schoolCode,
    required String organizationCode,
    required DateTime day,
  }) async {
    var codes = _allClassroomCodes.isNotEmpty
        ? List<String>.from(_allClassroomCodes)
        : shifts
            .map((s) => s.classroomCode.trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList(growable: false);

    var base = _mergeClassroomSchedules(
      _groupShiftsByClassroom(shifts),
      classroomCodes: codes,
    );

    if (codes.isEmpty && base.isEmpty) return base;

    final schoolHours = _schoolHoursResolver?.hoursFor(day);
    if (schoolHours?.startTimeOfDay == null ||
        schoolHours?.endTimeOfDay == null) {
      return base;
    }

    final start = schoolHours!.startTimeOfDay!;
    final end = schoolHours.endTimeOfDay!;
    final blockMinutes = schoolHours.durationMinutes ?? 30;
    final windowStart = ForecastSlotMapper.minutesOf(start);
    final windowEnd = ForecastSlotMapper.minutesOf(end);

    if (codes.isEmpty) {
      codes.addAll(
        base.map((c) => c.classroomCode).where((c) => c.isNotEmpty),
      );
    }
    if (codes.isEmpty) return base;

    List<ClassroomForecastBlock> forecastBlocks;
    try {
      if (state.viewMode == SchedulingViewMode.week) {
        forecastBlocks = await _getClassroomForecastRangeUseCase(
          schoolCode: schoolCode,
          organizationCode: organizationCode,
          startDate: day,
          endDate: day,
          startTime: start,
          endTime: end,
          durationMinutes: blockMinutes,
          classroomCodes: codes,
        );
      } else {
        forecastBlocks = await _getClassroomForecastUseCase(
          schoolCode: schoolCode,
          organizationCode: organizationCode,
          date: day,
          startTime: start,
          endTime: end,
          durationMinutes: blockMinutes,
          classroomCodes: codes,
        );
      }
    } catch (_) {
      return base;
    }

    final blocksByClassroom = <String, List<ClassroomForecastBlock>>{};
    for (final block in forecastBlocks) {
      final code = block.classroomCode.trim();
      if (code.isEmpty) continue;
      blocksByClassroom.putIfAbsent(code, () => <ClassroomForecastBlock>[]).add(
            block,
          );
    }

    if (state.viewMode == SchedulingViewMode.week) {
      return base
          .map(
            (c) => _applyWeekForecast(
              classroom: c,
              blocks: blocksByClassroom[c.classroomCode] ?? const [],
              day: day,
            ),
          )
          .toList(growable: false);
    }

    return base
        .map(
          (c) => _applyDayForecast(
            classroom: c,
            blocks: blocksByClassroom[c.classroomCode] ?? const [],
            shifts: shifts,
            day: day,
            windowStart: windowStart,
            windowEnd: windowEnd,
            blockMinutes: blockMinutes,
          ),
        )
        .toList(growable: false);
  }

  /// Ensures every active classroom appears even when it has no shift rows.
  List<ClassroomDaySchedule> _mergeClassroomSchedules(
    List<ClassroomDaySchedule> fromShifts, {
    required List<String> classroomCodes,
  }) {
    if (classroomCodes.isEmpty) return fromShifts;

    final byCode = <String, ClassroomDaySchedule>{
      for (final c in fromShifts) c.classroomCode: c,
    };

    for (final code in classroomCodes) {
      final trimmed = code.trim();
      if (trimmed.isEmpty || byCode.containsKey(trimmed)) continue;
      final name = _classroomNamesByCode[trimmed]?.trim();
      byCode[trimmed] = ClassroomDaySchedule(
        classroomCode: trimmed,
        classroomName: name != null && name.isNotEmpty ? name : trimmed,
        ratioStatus: ClassroomRatioStatus.inRatio,
        staff: const <StaffScheduleEntry>[],
      );
    }

    final ordered = <ClassroomDaySchedule>[];
    for (final code in classroomCodes) {
      final trimmed = code.trim();
      final row = byCode.remove(trimmed);
      if (row != null) ordered.add(row);
    }
    ordered.addAll(byCode.values);
    return ordered;
  }

  ClassroomDaySchedule _applyWeekForecast({
    required ClassroomDaySchedule classroom,
    required List<ClassroomForecastBlock> blocks,
    required DateTime day,
  }) {
    return ClassroomDaySchedule(
      classroomCode: classroom.classroomCode,
      classroomName: classroom.classroomName,
      ratioStatus: ForecastSlotMapper.ratioFromBlocksForWeek(
        blocks,
        filterDate: day,
      ),
      staff: classroom.staff,
    );
  }

  ClassroomDaySchedule _applyDayForecast({
    required ClassroomDaySchedule classroom,
    required List<ClassroomForecastBlock> blocks,
    required List<StaffShift> shifts,
    required DateTime day,
    required int windowStart,
    required int windowEnd,
    required int blockMinutes,
  }) {
    final classroomShifts = shifts
        .where((s) => s.classroomCode.trim() == classroom.classroomCode.trim())
        .toList(growable: false);

    final classTimeline = ForecastSlotMapper.buildTimeline(
      windowStartMinutes: windowStart,
      windowEndMinutes: windowEnd,
      slotMinutes: blockMinutes,
      blocks: blocks,
      filterDate: day,
      shiftsForScheduledCount: classroomShifts,
    );

    final staffEntries = classroom.staff.map((entry) {
      final shiftCode = entry.shiftCode?.trim() ?? '';
      if (shiftCode.isEmpty) return entry;

      final staffStart = _parseClockMinutes(entry.startTime);
      final staffEnd = _parseClockMinutes(entry.endTime);
      if (staffStart == null || staffEnd == null || staffEnd <= staffStart) {
        return entry;
      }

      var staffTimeline = ForecastSlotMapper.buildTimeline(
        windowStartMinutes: staffStart,
        windowEndMinutes: staffEnd,
        slotMinutes: blockMinutes,
        blocks: blocks,
        filterDate: day,
        staffShiftCodesFilter: [shiftCode],
        shiftsForScheduledCount: classroomShifts,
      );

      final hasColouredSlot = staffTimeline.slots.any(
        (s) => s != TimeSlotStatus.empty,
      );
      if (!hasColouredSlot) {
        staffTimeline = ForecastSlotMapper.buildTimeline(
          windowStartMinutes: staffStart,
          windowEndMinutes: staffEnd,
          slotMinutes: blockMinutes,
          blocks: blocks,
          filterDate: day,
          shiftsForScheduledCount: classroomShifts,
        );
      }

      return StaffScheduleEntry(
        staffName: entry.staffName,
        scheduledHours: entry.scheduledHours,
        availableHours: entry.availableHours,
        unscheduledHours: entry.unscheduledHours,
        startTime: entry.startTime,
        endTime: entry.endTime,
        isPublished: entry.isPublished,
        shiftCode: entry.shiftCode,
        photoUrl: entry.photoUrl,
        daySlots: staffTimeline.slots,
        slotDetails: staffTimeline.details,
        timelineStartMinutes: staffTimeline.dayStartMinutes,
        slotMinutes: staffTimeline.slotMinutes,
      );
    }).toList(growable: false);

    return ClassroomDaySchedule(
      classroomCode: classroom.classroomCode,
      classroomName: classroom.classroomName,
      ratioStatus: ForecastSlotMapper.ratioFromBlocksForWeek(
        blocks,
        filterDate: day,
      ),
      staff: staffEntries,
      daySlots: classTimeline.slots,
      slotDetails: classTimeline.details,
      timelineStartMinutes: classTimeline.dayStartMinutes,
      slotMinutes: classTimeline.slotMinutes,
    );
  }

  void setClassroomFilter(String? name) {
    emit(state.copyWith(classroomFilter: name));
  }

  void setClassroomNames(Map<String, String> namesByCode) {
    final codes = namesByCode.keys
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList(growable: false);
    final namesChanged = !_mapsEqual(_classroomNamesByCode, namesByCode);
    final codesChanged = !_codeSetsEqual(_allClassroomCodes, codes);
    if (!namesChanged && !codesChanged) return;
    _classroomNamesByCode = namesByCode;
    _allClassroomCodes = codes;
    if (_lastShifts.isEmpty) return;
    load();
  }

  static bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static bool _codeSetsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final setB = b.toSet();
    return a.every(setB.contains);
  }

  void selectDay(DateTime day) {
    final DateTime normalized = DateTime(day.year, day.month, day.day);
    if (normalized == state.selectedDay) return;
    emit(state.copyWith(selectedDay: normalized));
    load();
  }

  void shiftSelectedDay(int deltaDays) {
    selectDay(state.selectedDay.add(Duration(days: deltaDays)));
  }

  void setViewMode(SchedulingViewMode mode) {
    if (state.viewMode == mode) return;
    emit(state.copyWith(viewMode: mode));
    if (_lastShifts.isNotEmpty || _allClassroomCodes.isNotEmpty) {
      load();
    }
  }

  static int? _parseClockMinutes(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(' ');
    final timePart = parts.first;
    final period = parts.length > 1 ? parts[1].toUpperCase() : '';
    final segments = timePart.split(':');
    if (segments.length < 2) return null;
    var hour = int.tryParse(segments[0]);
    final minute = int.tryParse(segments[1]);
    if (hour == null || minute == null) return null;
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  List<ClassroomDaySchedule> _groupShiftsByClassroom(List<StaffShift> shifts) {
    if (shifts.isEmpty) return const <ClassroomDaySchedule>[];

    final byClassroom = <String, _ClassroomBucket>{};
    for (final shift in shifts) {
      final code = shift.classroomCode.trim();
      if (code.isEmpty) continue;
      final bucket = byClassroom.putIfAbsent(
        code,
        () {
          final shiftName = shift.classroomName.trim();
          if (shiftName.isNotEmpty) {
            return _ClassroomBucket(code: code, name: shiftName);
          }
          final lookup = _classroomNamesByCode[code]?.trim() ?? '';
          return _ClassroomBucket(
            code: code,
            name: lookup.isNotEmpty ? lookup : code,
          );
        },
      );
      bucket.shifts.add(shift);
    }

    return byClassroom.values
        .map((b) => b.toClassroomDaySchedule())
        .toList(growable: false);
  }
}

class _ClassroomBucket {
  _ClassroomBucket({required this.code, required this.name});

  final String code;
  final String name;
  final List<StaffShift> shifts = <StaffShift>[];

  ClassroomDaySchedule toClassroomDaySchedule() {
    final staffEntries = shifts.map((s) {
      return StaffScheduleEntry(
        staffName: s.staffName.isNotEmpty ? s.staffName : s.staffCode,
        scheduledHours: s.scheduledHours.toDouble(),
        availableHours: s.availableHours.toDouble(),
        unscheduledHours: s.unscheduledHours.toDouble(),
        startTime: _formatTimeOfDay(s.startTime),
        endTime: _formatTimeOfDay(s.endTime),
        isPublished: s.isPublished,
        shiftCode: s.shiftCode,
      );
    }).toList(growable: false);

    return ClassroomDaySchedule(
      classroomCode: code,
      classroomName: name,
      ratioStatus: ClassroomRatioStatus.inRatio,
      staff: staffEntries,
    );
  }

  static String _formatTimeOfDay(TimeOfDay t) {
    final period = t.hour >= 12 ? 'PM' : 'AM';
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }
}
