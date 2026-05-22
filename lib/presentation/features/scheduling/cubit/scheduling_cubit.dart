import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/scheduling/entities/staff_shift.dart';
import '../../../../domain/features/scheduling/usecases/get_school_staff_shifts_usecase.dart';
import '../model/scheduling_models.dart';

part 'scheduling_state.dart';

class SchedulingCubit extends Cubit<SchedulingState> {
  SchedulingCubit({
    required GetSchoolStaffShiftsUseCase getSchoolStaffShiftsUseCase,
    required StorageService storageService,
  })  : _getSchoolStaffShiftsUseCase = getSchoolStaffShiftsUseCase,
        _storageService = storageService,
        super(SchedulingState.initial());

  final GetSchoolStaffShiftsUseCase _getSchoolStaffShiftsUseCase;
  final StorageService _storageService;

  String? _schoolCode;
  String? _organizationCode;

  /// Classroom code → display name. Populated by the screen from
  /// [ClassroomCubit] so we can resolve human-readable names since the
  /// `staff-shifts` API only returns `classroomCode`.
  Map<String, String> _classroomNamesByCode = const {};

  /// Most-recently fetched shifts, kept so [setClassroomNames] can re-group
  /// without re-hitting the API when classroom names arrive late.
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

  /// Loads shifts for the currently selected day. The scheduling screen has
  /// no date-range picker, so both `dateFrom` and `dateTo` use the same day.
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
      final shifts = await _getSchoolStaffShiftsUseCase(
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        dateFrom: day,
        dateTo: day,
      );

      if (isClosed) return;
      _lastShifts = shifts;
      emit(
        state.copyWith(
          isLoading: false,
          classrooms: _groupShiftsByClassroom(shifts),
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

  void setClassroomFilter(String? name) {
    emit(state.copyWith(classroomFilter: name));
  }

  /// Pushes the latest classroom code→name map from [ClassroomCubit]. Re-groups
  /// the most-recent shifts so any rows currently rendering a fallback code
  /// pick up the resolved name (and vice versa if names disappear).
  void setClassroomNames(Map<String, String> namesByCode) {
    if (_mapsEqual(_classroomNamesByCode, namesByCode)) return;
    _classroomNamesByCode = namesByCode;
    if (_lastShifts.isEmpty) return;
    emit(state.copyWith(classrooms: _groupShiftsByClassroom(_lastShifts)));
  }

  static bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
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
  }

  // ---------------- Mapping ----------------

  /// Buckets [shifts] into one [ClassroomDaySchedule] per classroomCode. Each
  /// shift becomes a [StaffScheduleEntry] preserving the staff name + start /
  /// end times. We don't have ratio info from the API yet so every classroom
  /// is reported as `inRatio` and `daySlots` is left empty (the timeline
  /// strips render no bars until ratio data is available).
  List<ClassroomDaySchedule> _groupShiftsByClassroom(List<StaffShift> shifts) {
    if (shifts.isEmpty) return const <ClassroomDaySchedule>[];

    final byClassroom = <String, _ClassroomBucket>{};
    for (final shift in shifts) {
      final code = shift.classroomCode.trim();
      if (code.isEmpty) continue;
      final bucket = byClassroom.putIfAbsent(
        code,
        () {
          // Prefer the name baked into the shift (some endpoints include it),
          // then the lookup map from ClassroomCubit, then fall back to the
          // code so the row is at least identifiable.
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
      // Per-shift duration computed from start/end. The API's `scheduledHours`
      // is a per-staff-per-day aggregate — repeating it across every shift
      // row is misleading, so we compute the actual duration of THIS shift.
      final scheduled = _hoursBetween(s.startTime, s.endTime);
      // Available hours stay as the API aggregate (staff's total work
      // window for the day); fall back to scheduled if backend omitted it.
      final available =
          s.availableHours > 0 ? s.availableHours.toDouble() : scheduled;
      return StaffScheduleEntry(
        staffName: s.staffName.isNotEmpty ? s.staffName : s.staffCode,
        scheduledHours: scheduled,
        availableHours: available,
        startTime: _formatTimeOfDay(s.startTime),
        endTime: _formatTimeOfDay(s.endTime),
        isPublished: s.isPublished,
      );
    }).toList(growable: false);

    return ClassroomDaySchedule(
      classroomCode: code,
      classroomName: name,
      ratioStatus: ClassroomRatioStatus.inRatio,
      staff: staffEntries,
    );
  }

  static double _hoursBetween(TimeOfDay start, TimeOfDay end) {
    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;
    final diff = (endMin - startMin).clamp(0, 24 * 60);
    return diff / 60.0;
  }

  static String _formatTimeOfDay(TimeOfDay t) {
    final period = t.hour >= 12 ? 'PM' : 'AM';
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }
}
