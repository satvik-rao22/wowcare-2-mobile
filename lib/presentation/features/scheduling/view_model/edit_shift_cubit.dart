import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/api_error_handler.dart';
import '../../../../core/utils/storage_keys.dart';
import '../../../../domain/features/classroom/entities/classroom.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/scheduling/entities/staff_shift.dart';
import '../../../../domain/features/scheduling/repositories/staff_shift_repository.dart';
import '../../../../domain/features/scheduling/usecases/bootstrap_scheduling_school_timezone_usecase.dart';
import '../../../../domain/features/scheduling/usecases/get_staff_shifts_usecase.dart';
import '../../../../domain/features/scheduling/usecases/update_staff_shift_series_usecase.dart';
import '../../../../domain/features/scheduling/usecases/update_staff_shift_usecase.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../domain/features/scheduling/services/scheduling_school_time.dart';
import '../utils/school_hours_resolver.dart';
import '../view/edit_shift_screen.dart';

part 'edit_shift_state.dart';

/// Backs [EditShiftScreen]. Owns the edit form state plus the save flow for
/// both modes — single occurrence (`UpdateStaffShiftUseCase`) and entire
/// series (`UpdateStaffShiftSeriesUseCase`). Mirrors [AddShiftCubit]'s
/// validation and absence/conflict orchestration; the interactive bottom
/// sheets are delegated back to the view via callbacks in [save].
class EditShiftCubit extends Cubit<EditShiftState> {
  EditShiftCubit({
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required StaffRepository staffRepository,
    required StaffShiftRepository staffShiftRepository,
    required GetStaffShiftsUseCase getStaffShiftsUseCase,
    required UpdateStaffShiftUseCase updateStaffShiftUseCase,
    required UpdateStaffShiftSeriesUseCase updateStaffShiftSeriesUseCase,
    required StorageService storageService,
    required BootstrapSchedulingSchoolTimezoneUseCase
        bootstrapSchedulingSchoolTimezoneUseCase,
  }) : _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
       _staffRepository = staffRepository,
       _staffShiftRepository = staffShiftRepository,
       _getStaffShiftsUseCase = getStaffShiftsUseCase,
       _updateStaffShiftUseCase = updateStaffShiftUseCase,
       _updateStaffShiftSeriesUseCase = updateStaffShiftSeriesUseCase,
       _storageService = storageService,
       _bootstrapSchedulingSchoolTimezoneUseCase =
           bootstrapSchedulingSchoolTimezoneUseCase,
       super(const EditShiftState());

  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final StaffRepository _staffRepository;
  final StaffShiftRepository _staffShiftRepository;
  final GetStaffShiftsUseCase _getStaffShiftsUseCase;
  final UpdateStaffShiftUseCase _updateStaffShiftUseCase;
  final UpdateStaffShiftSeriesUseCase _updateStaffShiftSeriesUseCase;
  final StorageService _storageService;
  final BootstrapSchedulingSchoolTimezoneUseCase
      _bootstrapSchedulingSchoolTimezoneUseCase;

  // Immutable identity of the shift being edited — set once in [init].
  late EditShiftMode _mode;
  late String _shiftCode;
  String? _seriesCode;
  late String _staffCode;

  bool get isSeriesMode => _mode == EditShiftMode.entireSeries;

  /// Seeds the form from the screen's constructor arguments, then kicks off the
  /// background loads (school hours, admin classrooms, school timezone).
  void init({
    required EditShiftMode mode,
    required String shiftCode,
    String? seriesCode,
    required String staffCode,
    required String classroomCode,
    required DateTime initialDate,
    required TimeOfDay shiftStart,
    required TimeOfDay shiftEnd,
    TimeOfDay? breakStart,
    TimeOfDay? breakEnd,
    Set<String> selectedDays = const <String>{},
    DateTime? untilDate,
    bool isPublished = true,
  }) {
    _mode = mode;
    _shiftCode = shiftCode;
    _seriesCode = seriesCode;
    _staffCode = staffCode;
    emit(
      state.copyWith(
        date: initialDate,
        untilDate: untilDate,
        selectedClassroomCode: classroomCode.isEmpty ? null : classroomCode,
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
        breakStart: breakStart,
        breakEnd: breakEnd,
        selectedDays: Set<String>.of(selectedDays),
        publish: isPublished,
      ),
    );
    // ignore: discarded_futures
    _loadSchoolHours();
    // ignore: discarded_futures
    _loadAdminClassrooms();
    // ignore: discarded_futures
    _bootstrapSchedulingSchoolTimezoneUseCase();
  }

  Future<void> _loadAdminClassrooms() async {
    try {
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '')
              .trim();
      if (schoolCode.isEmpty) return;
      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: schoolCode,
        typeOverride: 'ADMIN',
      );
      if (isClosed) return;
      emit(state.copyWith(adminClassrooms: classrooms));
    } catch (_) {
      // Best-effort: missing admin locations just keeps the dropdown to the
      // existing CLASSROOM-type list.
    }
  }

  Future<void> _loadSchoolHours() async {
    try {
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '')
              .trim();
      if (schoolCode.isEmpty) return;
      final days = await _staffRepository.getSchoolRegularSchedules(
        schoolCode: schoolCode,
      );
      if (isClosed) return;
      emit(
        state.copyWith(schoolHoursResolver: SchoolHoursResolver.fromDays(days)),
      );
    } catch (_) {
      // Best-effort: without school hours the hard-rule check no-ops.
    }
  }

  // ─── Form mutations ────────────────────────────────────────────────────────

  void setDate(DateTime date) {
    emit(state.copyWith(date: date, schoolHoursError: null));
  }

  void setClassroom(String? code) {
    emit(state.copyWith(selectedClassroomCode: code));
  }

  void setShiftStart(TimeOfDay? time) {
    emit(
      state.copyWith(
        shiftStart: time,
        shiftStartError: null,
        schoolHoursError: null,
      ),
    );
  }

  void setShiftEnd(TimeOfDay? time) {
    emit(
      state.copyWith(
        shiftEnd: time,
        shiftEndError: null,
        schoolHoursError: null,
      ),
    );
  }

  void setBreakStart(TimeOfDay? time) {
    emit(
      state.copyWith(
        breakStart: time,
        breakStartError: null,
        schoolHoursError: null,
      ),
    );
  }

  void setBreakEnd(TimeOfDay? time) {
    emit(
      state.copyWith(
        breakEnd: time,
        breakEndError: null,
        schoolHoursError: null,
      ),
    );
  }

  void setUntilDate(DateTime date) {
    emit(state.copyWith(untilDate: date, untilDateError: null));
  }

  void setPublish(bool value) {
    emit(state.copyWith(publish: value));
  }

  void toggleSelectAll() {
    final available = state.availableWeekDays;
    final selectedDays = state.selectedDays.length == available.length
        ? <String>{}
        : <String>{...available};
    emit(state.copyWith(selectedDays: selectedDays, daysError: null));
  }

  void toggleDay(String day, bool selected) {
    final selectedDays = <String>{...state.selectedDays};
    if (selected) {
      selectedDays.add(day);
    } else {
      selectedDays.remove(day);
    }
    emit(state.copyWith(selectedDays: selectedDays, daysError: null));
  }

  // ─── Derived helpers ───────────────────────────────────────────────────────

  bool get isFormValid {
    if (state.date == null) return false;
    if (state.selectedClassroomCode == null ||
        state.selectedClassroomCode!.isEmpty) {
      return false;
    }
    if (state.shiftStart == null || state.shiftEnd == null) return false;
    if (isSeriesMode) {
      if (state.selectedDays.isEmpty) return false;
      if (state.untilDate == null) return false;
    }
    return true;
  }

  StaffMember? _findStaff(String code, List<StaffMember> list) {
    if (code.isEmpty) return null;
    for (final s in list) {
      if (s.code == code) return s;
    }
    return null;
  }

  /// Whether the edited shift's staff has one of the four teacher designations
  /// that should see ADMIN-type locations merged into the Classroom dropdown.
  bool _isTeacherDesignation(List<StaffMember> staff) {
    final member = _findStaff(_staffCode, staff);
    if (member == null) return false;
    final designation = member.designation.trim().toUpperCase();
    if (designation.isEmpty) return false;
    return _teacherDesignationCodes.contains(designation);
  }

  /// Returns `code → name` for the classroom dropdown, merging ADMIN-type
  /// locations for teacher designations. [fallbackName] keeps the originally
  /// passed classroom name visible even if the cubit's classroom list hasn't
  /// caught up.
  Map<String, String> classroomOptions({
    required List<Classroom> classrooms,
    required List<StaffMember> staff,
  }) {
    final result = <String, String>{for (final c in classrooms) c.code: c.name};
    if (_isTeacherDesignation(staff)) {
      for (final c in state.adminClassrooms) {
        final code = c.code.trim();
        if (code.isEmpty) continue;
        final name = c.name.trim();
        result.putIfAbsent(code, () => name.isNotEmpty ? name : code);
      }
    }
    return result;
  }

  /// Live view of whether the picked shift time falls outside the staff's
  /// work-schedule window for the selected date. Single-mode only.
  String? staffAvailabilityError(List<StaffMember> staff) {
    if (isSeriesMode) return null;
    final date = state.date;
    if (date == null) return null;
    if (state.shiftStart == null || state.shiftEnd == null) return null;
    if (_staffCode.isEmpty) return null;
    final selectedStaff = _findStaff(_staffCode, staff);
    if (selectedStaff == null) return null;
    if (_shiftFitsStaffSchedule(selectedStaff, date.weekday)) return null;
    return 'Selected shift time is outside this staff availability.';
  }

  bool _shiftFitsStaffSchedule(StaffMember staff, int weekday) {
    final shiftStart = state.shiftStart;
    final shiftEnd = state.shiftEnd;
    if (shiftStart == null || shiftEnd == null) return true;
    final dayKey = _weekdayDayKey[weekday] ?? '';
    if (dayKey.isEmpty) return true;
    final window = _parseTimeRange(staff.workScheduleByDay[dayKey]);
    if (window == null) return true;
    final shiftStartMin = _minutesOf(shiftStart);
    final shiftEndMin = _minutesOf(shiftEnd);
    final winStartMin = _minutesOf(window.$1);
    final winEndMin = _minutesOf(window.$2);
    if (shiftStartMin < winStartMin || shiftEndMin > winEndMin) return false;
    final breakStart = state.breakStart;
    final breakEnd = state.breakEnd;
    if (breakStart != null && breakEnd != null) {
      final bStart = _minutesOf(breakStart);
      final bEnd = _minutesOf(breakEnd);
      if (bStart < winStartMin || bEnd > winEndMin) return false;
    }
    return true;
  }

  bool _staffHasNoScheduleForSelection(StaffMember staff) {
    if (isSeriesMode && state.selectedDays.isNotEmpty) {
      for (final day in state.selectedDays) {
        final raw = staff.workScheduleByDay[day.toUpperCase()]?.trim() ?? '';
        if (raw.isEmpty) return true;
      }
      return false;
    }
    final date = state.date;
    if (date == null) return false;
    final dayKey = _weekdayDayKey[date.weekday] ?? '';
    if (dayKey.isEmpty) return false;
    final raw = staff.workScheduleByDay[dayKey]?.trim() ?? '';
    return raw.isEmpty;
  }

  // ─── Validation ────────────────────────────────────────────────────────────

  bool validate() {
    emit(
      state.copyWith(
        shiftStartError: null,
        shiftEndError: null,
        breakStartError: null,
        breakEndError: null,
        untilDateError: null,
        daysError: null,
        schoolHoursError: null,
      ),
    );

    final shiftStart = state.shiftStart;
    final shiftEnd = state.shiftEnd;
    if (shiftStart == null || shiftEnd == null) return false;

    final shiftStartMin = _minutesOf(shiftStart);
    final shiftEndMin = _minutesOf(shiftEnd);

    if (shiftEndMin <= shiftStartMin) {
      emit(
        state.copyWith(shiftEndError: 'Shift end must be after shift start'),
      );
      return false;
    }

    final breakStart = state.breakStart;
    final breakEnd = state.breakEnd;
    final hasBreakStart = breakStart != null;
    final hasBreakEnd = breakEnd != null;
    if (hasBreakStart != hasBreakEnd) {
      emit(
        state.copyWith(
          breakStartError: !hasBreakStart ? 'Break start is required' : null,
          breakEndError: !hasBreakEnd ? 'Break end is required' : null,
        ),
      );
      return false;
    }

    if (hasBreakStart && hasBreakEnd) {
      final breakStartMin = _minutesOf(breakStart);
      final breakEndMin = _minutesOf(breakEnd);
      if (breakEndMin <= breakStartMin) {
        emit(
          state.copyWith(breakEndError: 'Break end must be after break start'),
        );
        return false;
      }
      if (breakStartMin < shiftStartMin || breakEndMin > shiftEndMin) {
        emit(
          state.copyWith(
            breakStartError: 'Break must be within shift',
            breakEndError: 'Break must be within shift',
          ),
        );
        return false;
      }
    }

    final date = state.date;
    if (isSeriesMode && state.untilDate != null && date != null) {
      if (state.untilDate!.isBefore(date) &&
          !_isSameDay(state.untilDate!, date)) {
        emit(
          state.copyWith(untilDateError: 'Must be on or after the shift date'),
        );
        return false;
      }
    }

    final windows = <(TimeOfDay, TimeOfDay)>[];
    if (isSeriesMode && state.selectedDays.isNotEmpty) {
      for (final day in state.selectedDays) {
        final weekday = _weekDayIndex[day];
        if (weekday == null) continue;
        final w = state._schoolHoursForWeekday(weekday);
        if (w != null) windows.add(w);
      }
    } else if (date != null) {
      final w = state._schoolHoursForDate(date);
      if (w != null) windows.add(w);
    }
    for (final window in windows) {
      final schoolStartMin = _minutesOf(window.$1);
      final schoolEndMin = _minutesOf(window.$2);
      final windowLabel =
          '${_formatTime(window.$1)} – ${_formatTime(window.$2)}';
      if (shiftStartMin < schoolStartMin || shiftEndMin > schoolEndMin) {
        emit(
          state.copyWith(
            schoolHoursError:
                'Shift must be within school hours ($windowLabel).',
          ),
        );
        return false;
      }
      if (hasBreakStart && hasBreakEnd) {
        final breakStartMin = _minutesOf(breakStart);
        final breakEndMin = _minutesOf(breakEnd);
        if (breakStartMin < schoolStartMin || breakEndMin > schoolEndMin) {
          emit(
            state.copyWith(
              schoolHoursError:
                  'Break must be within school hours ($windowLabel).',
            ),
          );
          return false;
        }
      }
    }

    return true;
  }

  // ─── Save ──────────────────────────────────────────────────────────────────

  /// Runs the full update flow. [validate] must have already passed. The four
  /// callbacks surface the interactive bottom sheets; each returns the user's
  /// answer so the cubit can branch.
  Future<EditShiftSubmitOutcome> save({
    required List<StaffMember> staff,
    required String notes,
    required Future<void> Function(DateTime absentDate) onAbsentBlock,
    required Future<bool> Function() onNoScheduleConfirm,
    required Future<void> Function() onNoAvailability,
    required Future<bool> Function(List<DateTime> conflicts) onConflictConfirm,
  }) async {
    if (state.saving) return const EditShiftSubmitOutcome.cancelled();

    final date = state.date;
    final classroomCode = state.selectedClassroomCode;
    final shiftStart = state.shiftStart;
    final shiftEnd = state.shiftEnd;
    if (date == null ||
        classroomCode == null ||
        classroomCode.isEmpty ||
        shiftStart == null ||
        shiftEnd == null) {
      return const EditShiftSubmitOutcome.cancelled();
    }

    final seriesMode = isSeriesMode;
    final untilDate = state.untilDate;
    final selectedDayIndices = state.selectedDays
        .map((d) => _weekDayIndex[d])
        .whereType<int>()
        .toSet();

    // Absence pre-check.
    emit(state.copyWith(saving: true));
    final absentRangeTo = seriesMode && untilDate != null ? untilDate : date;
    List<DateTime> absentDates;
    try {
      absentDates = await _staffShiftRepository.getStaffAbsentDatesInRange(
        staffCode: _staffCode,
        from: date,
        to: absentRangeTo,
      );
    } catch (e) {
      if (!isClosed) emit(state.copyWith(saving: false));
      return EditShiftSubmitOutcome.error(
        ApiErrorHandler.extractErrorMessage(e),
      );
    }

    if (!seriesMode) {
      final blocking = absentDates.where((d) => _isSameDay(d, date));
      if (blocking.isNotEmpty) {
        if (!isClosed) emit(state.copyWith(saving: false));
        await onAbsentBlock(blocking.first);
        return const EditShiftSubmitOutcome.cancelled();
      }
    }

    var seriesAbsentDates = const <DateTime>[];
    if (seriesMode) {
      seriesAbsentDates = absentDates
          .where((d) {
            if (selectedDayIndices.isEmpty) return true;
            return selectedDayIndices.contains(d.weekday);
          })
          .toList(growable: false);
    }

    if (!isClosed) emit(state.copyWith(saving: false));

    // No-schedule check.
    var forceAdd = false;
    final selectedStaff = _findStaff(_staffCode, staff);
    if (selectedStaff != null &&
        _staffHasNoScheduleForSelection(selectedStaff)) {
      if (seriesMode) {
        await onNoAvailability();
        return const EditShiftSubmitOutcome.cancelled();
      }
      final confirmed = await onNoScheduleConfirm();
      if (!confirmed) return const EditShiftSubmitOutcome.cancelled();
      forceAdd = true;
    }

    // Recurring: each selected weekday must fit the staff's window.
    if (seriesMode && selectedStaff != null) {
      final anyOutside = selectedDayIndices.any(
        (wd) => !_shiftFitsStaffSchedule(selectedStaff, wd),
      );
      if (anyOutside) {
        await onNoAvailability();
        return const EditShiftSubmitOutcome.cancelled();
      }
    }

    emit(state.copyWith(saving: true));
    try {
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '')
              .trim();
      final orgCode =
          (await _storageService.getString(StorageKeys.organizationCode) ?? '')
              .trim();

      if (schoolCode.isEmpty || orgCode.isEmpty) {
        throw Exception('Missing school/organization context');
      }

      // Time-aware conflict detection, excluding the shift being edited (single
      // mode) or every shift already in this series (series mode) so we don't
      // flag a shift as conflicting with itself.
      final dateTo = seriesMode && untilDate != null ? untilDate : date;
      final existing = await _getStaffShiftsUseCase(
        staffCode: _staffCode,
        schoolCode: schoolCode,
        organizationCode: orgCode,
        dateFrom: date,
        dateTo: dateTo,
      );

      final newStartMin = _minutesOf(shiftStart);
      final newEndMin = _minutesOf(shiftEnd);
      final conflicts = <DateTime>[];
      final seriesCode = (_seriesCode ?? '').trim();
      for (final shift in existing) {
        if (shift.shiftCode == _shiftCode) continue;
        if (seriesMode &&
            seriesCode.isNotEmpty &&
            shift.seriesCode == seriesCode) {
          continue;
        }
        final existingStartMin = _minutesOf(shift.startTime);
        final existingEndMin = _minutesOf(shift.endTime);
        final overlaps =
            newStartMin < existingEndMin && existingStartMin < newEndMin;
        if (!overlaps) continue;
        if (seriesMode) {
          if (selectedDayIndices.isEmpty ||
              selectedDayIndices.contains(shift.shiftDate.weekday)) {
            conflicts.add(shift.shiftDate);
          }
        } else {
          if (_isSameDay(shift.shiftDate, date)) {
            conflicts.add(shift.shiftDate);
          }
        }
      }

      if (conflicts.isNotEmpty) {
        final confirmed = await onConflictConfirm(conflicts);
        if (!confirmed) {
          if (!isClosed) emit(state.copyWith(saving: false));
          return const EditShiftSubmitOutcome.cancelled();
        }
      }

      final trimmedNotes = notes.trim();
      final notesOrNull = trimmedNotes.isEmpty ? null : trimmedNotes;

      if (seriesMode) {
        if (seriesCode.isEmpty) {
          throw Exception('Missing series code for series update');
        }
        // Wire format: 0=Mon … 6=Sun.
        final repeatDaysWire = selectedDayIndices
            .map((d) => d - 1)
            .toList(growable: false);
        final request = StaffShiftSeriesUpdateRequest(
          seriesCode: seriesCode,
          shiftCode: _shiftCode,
          staffCode: _staffCode,
          schoolCode: schoolCode,
          organizationCode: orgCode,
          shiftDate: date,
          classroomCode: classroomCode,
          startTime: shiftStart,
          endTime: shiftEnd,
          breakStartTime: state.breakStart,
          breakEndTime: state.breakEnd,
          notes: notesOrNull,
          overrideConflicts: true,
          repeat: true,
          repeatDays: repeatDaysWire,
          repeatUntilDate: untilDate,
          publish: state.publish,
        );
        await _updateStaffShiftSeriesUseCase(request);

        // Strip shifts that landed on absent days, same as Add screen.
        if (seriesAbsentDates.isNotEmpty) {
          try {
            await _staffShiftRepository.markStaffShiftAbsentDays(
              staffCode: _staffCode,
              schoolCode: schoolCode,
              absentDates: seriesAbsentDates,
            );
          } catch (e) {
            debugPrint('markStaffShiftAbsentDays failed: $e');
          }
        }
      } else {
        final request = StaffShiftUpdateRequest(
          shiftCode: _shiftCode,
          staffCode: _staffCode,
          schoolCode: schoolCode,
          organizationCode: orgCode,
          classroomCode: classroomCode,
          shiftDate: date,
          startTime: shiftStart,
          endTime: shiftEnd,
          breakStartTime: state.breakStart,
          breakEndTime: state.breakEnd,
          notes: notesOrNull,
          overrideConflicts: true,
          forceAdd: forceAdd,
          publish: state.publish,
        );
        await _updateStaffShiftUseCase(request);
      }

      if (!isClosed) emit(state.copyWith(saving: false));
      return const EditShiftSubmitOutcome.success();
    } catch (e) {
      if (!isClosed) emit(state.copyWith(saving: false));
      return EditShiftSubmitOutcome.error(
        ApiErrorHandler.extractErrorMessage(e),
      );
    }
  }
}

/// Result of [EditShiftCubit.save]. `cancelled` means the user backed out of a
/// prompt (no toast); `success` always maps to "Shift updated successfully".
class EditShiftSubmitOutcome {
  const EditShiftSubmitOutcome._({
    required this.success,
    required this.cancelled,
    this.errorMessage,
  });

  const EditShiftSubmitOutcome.success()
    : this._(success: true, cancelled: false);

  const EditShiftSubmitOutcome.cancelled()
    : this._(success: false, cancelled: true);

  const EditShiftSubmitOutcome.error(String message)
    : this._(success: false, cancelled: false, errorMessage: message);

  final bool success;
  final bool cancelled;
  final String? errorMessage;
}

// ─── Weekday lookup tables (shared by cubit + state) ─────────────────────────

const List<String> _weekDaysOrder = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const Map<String, int> _weekDayIndex = <String, int>{
  'Monday': DateTime.monday,
  'Tuesday': DateTime.tuesday,
  'Wednesday': DateTime.wednesday,
  'Thursday': DateTime.thursday,
  'Friday': DateTime.friday,
  'Saturday': DateTime.saturday,
  'Sunday': DateTime.sunday,
};

const Map<int, String> _weekdayDayKey = <int, String>{
  DateTime.monday: 'MONDAY',
  DateTime.tuesday: 'TUESDAY',
  DateTime.wednesday: 'WEDNESDAY',
  DateTime.thursday: 'THURSDAY',
  DateTime.friday: 'FRIDAY',
  DateTime.saturday: 'SATURDAY',
  DateTime.sunday: 'SUNDAY',
};

const Set<String> _teacherDesignationCodes = <String>{
  'LEAD_TEACHER',
  'ASSOCIATE_TEACHER',
  'ASSISTANT_TEACHER',
  'FLOATER',
};

// ─── Pure time helpers (shared by cubit + state) ─────────────────────────────

int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Context-free 12-hour formatter (e.g. `8:05 AM`) for the school-hours error
/// label — keeps the message deterministic without a `BuildContext`.
String _formatTime(TimeOfDay t) {
  final period = t.hour < 12 ? 'AM' : 'PM';
  var hour = t.hour % 12;
  if (hour == 0) hour = 12;
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour:$minute $period';
}

// TimeOfDay? _parse24hTime(String raw) {
//   final trimmed = raw.trim();
//   if (trimmed.isEmpty) return null;
//   final parts = trimmed.split(':');
//   if (parts.length < 2) return null;
//   final h = int.tryParse(parts[0]);
//   final m = int.tryParse(parts[1]);
//   if (h == null || m == null) return null;
//   if (h < 0 || h > 23 || m < 0 || m > 59) return null;
//   return TimeOfDay(hour: h, minute: m);
// }

(TimeOfDay, TimeOfDay)? _parseTimeRange(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final parts = trimmed.split('-');
  if (parts.length != 2) return null;
  final start = _parseClockTime(parts[0]);
  final end = _parseClockTime(parts[1]);
  if (start == null || end == null) return null;
  return (start, end);
}

TimeOfDay? _parseClockTime(String raw) {
  final upper = raw.trim().toUpperCase();
  if (upper.isEmpty) return null;
  final isPm = upper.endsWith('PM');
  final isAm = upper.endsWith('AM');
  if (!isAm && !isPm) return null;
  final body = upper.substring(0, upper.length - 2).trim();
  final segments = body.split(':');
  if (segments.length < 2) return null;
  var hour = int.tryParse(segments[0]);
  final minute = int.tryParse(segments[1]);
  if (hour == null || minute == null) return null;
  if (isPm && hour < 12) hour += 12;
  if (isAm && hour == 12) hour = 0;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}
