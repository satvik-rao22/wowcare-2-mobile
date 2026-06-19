import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/classroom/entities/classroom.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/scheduling/entities/staff_shift.dart';
import '../../../../domain/features/scheduling/repositories/staff_shift_repository.dart';
import '../../../../domain/features/scheduling/usecases/create_staff_shift_usecase.dart';
import '../../../../domain/features/scheduling/usecases/get_staff_shifts_usecase.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../utils/scheduling_school_time.dart';
import '../utils/school_hours_resolver.dart';

part 'add_shift_state.dart';

/// Backs [AddShiftScreen]. Owns every piece of form state (date, times,
/// repeat-days, validation errors, publish/saving flags) plus all async data
/// orchestration (school hours, admin classrooms, absence/conflict checks, and
/// the shift create POST) that used to live inline in the widget's `setState`
/// soup.
///
/// Interactive bottom sheets (absence block, no-schedule confirm, conflict
/// override) are the one thing a cubit can't own — they need a `BuildContext`
/// and a user answer mid-flow — so [submit] delegates those back to the view
/// through callbacks, keeping the decision flow itself here.
class AddShiftCubit extends Cubit<AddShiftState> {
  AddShiftCubit({
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required StaffRepository staffRepository,
    required StaffShiftRepository staffShiftRepository,
    required GetStaffShiftsUseCase getStaffShiftsUseCase,
    required CreateStaffShiftUseCase createStaffShiftUseCase,
    required StorageService storageService,
  })  : _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
        _staffRepository = staffRepository,
        _staffShiftRepository = staffShiftRepository,
        _getStaffShiftsUseCase = getStaffShiftsUseCase,
        _createStaffShiftUseCase = createStaffShiftUseCase,
        _storageService = storageService,
        super(AddShiftState(date: schedulingSchoolToday()));

  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final StaffRepository _staffRepository;
  final StaffShiftRepository _staffShiftRepository;
  final GetStaffShiftsUseCase _getStaffShiftsUseCase;
  final CreateStaffShiftUseCase _createStaffShiftUseCase;
  final StorageService _storageService;

  /// Tracks the (staffCode|yyyy-MM-dd) combo we've already prefilled times for,
  /// so the build-time fallback prefill only fires once per new combo.
  String? _lastPrefilledKey;

  /// Whether the caller passed `initialDate` — when false the default date is
  /// refreshed once the school timezone resolves.
  bool _hasExplicitInitialDate = false;

  String _prefillKey(String? staffCode, DateTime date) =>
      '${staffCode ?? ''}|${date.toIso8601String().substring(0, 10)}';

  // ─── Bootstrap ─────────────────────────────────────────────────────────────

  /// Seeds the form from the screen's constructor arguments, then kicks off the
  /// background loads (school hours, admin classrooms, school timezone).
  void init({
    DateTime? initialDate,
    String? initialClassroomCode,
    String? initialStaffCode,
    TimeOfDay? initialShiftStart,
    TimeOfDay? initialShiftEnd,
    bool initialPublish = false,
    bool prefillStaff = true,
  }) {
    _hasExplicitInitialDate = initialDate != null;
    final seededDate = initialDate ?? schedulingSchoolToday();
    final hasExplicitTimes =
        initialShiftStart != null || initialShiftEnd != null;
    if (hasExplicitTimes && initialStaffCode != null) {
      _lastPrefilledKey = _prefillKey(initialStaffCode, seededDate);
    }
    emit(
      state.copyWith(
        date: seededDate,
        selectedClassroomCode: initialClassroomCode,
        selectedStaffCode: prefillStaff ? initialStaffCode : null,
        shiftStart: initialShiftStart,
        shiftEnd: initialShiftEnd,
        publish: initialPublish,
      ),
    );
    // Shift/break times are intentionally not seeded with hardcoded defaults —
    // they get prefilled from the selected staff's work/break schedule.
    // ignore: discarded_futures
    _loadSchoolHours();
    // ignore: discarded_futures
    _bootstrapSchoolZone();
    // ignore: discarded_futures
    _loadAdminClassrooms();
  }

  Future<void> _loadAdminClassrooms() async {
    try {
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
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

  Future<void> _bootstrapSchoolZone() async {
    try {
      await bootstrapSchedulingSchoolTimezone();
      if (isClosed) return;
      // Refresh the default date once the school zone resolves, but only when
      // the caller didn't pass a specific initialDate.
      if (!_hasExplicitInitialDate) {
        emit(state.copyWith(date: schedulingSchoolToday()));
      }
    } catch (_) {}
  }

  Future<void> _loadSchoolHours() async {
    try {
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
      if (schoolCode.isEmpty) return;
      final days =
          await _staffRepository.getSchoolRegularSchedules(schoolCode: schoolCode);
      if (isClosed) return;
      emit(
        state.copyWith(schoolHoursResolver: SchoolHoursResolver.fromDays(days)),
      );
    } catch (_) {
      // Best-effort: without school hours the hard-rule check no-ops.
    }
  }

  // ─── Form mutations ────────────────────────────────────────────────────────

  void setDate(DateTime date, {StaffMember? selectedStaff}) {
    emit(state.copyWith(date: date, schoolHoursError: null));
    // Re-prefill so the times reflect the new weekday's schedule for the
    // currently selected staff member, if any.
    prefillTimesFromSchedule(selectedStaff);
  }

  void setClassroom(String? code) {
    emit(state.copyWith(selectedClassroomCode: code));
  }

  void setShiftStart(TimeOfDay? time) {
    emit(state.copyWith(
      shiftStart: time,
      shiftStartError: null,
      schoolHoursError: null,
    ));
  }

  void setShiftEnd(TimeOfDay? time) {
    emit(state.copyWith(
      shiftEnd: time,
      shiftEndError: null,
      schoolHoursError: null,
    ));
  }

  void setBreakStart(TimeOfDay? time) {
    emit(state.copyWith(
      breakStart: time,
      breakStartError: null,
      schoolHoursError: null,
    ));
  }

  void setBreakEnd(TimeOfDay? time) {
    emit(state.copyWith(
      breakEnd: time,
      breakEndError: null,
      schoolHoursError: null,
    ));
  }

  void setUntilDate(DateTime date) {
    emit(state.copyWith(untilDate: date, untilDateError: null));
  }

  void setPublish(bool value) {
    emit(state.copyWith(publish: value));
  }

  void toggleRepeat(bool value) {
    if (!value) {
      emit(state.copyWith(
        repeatOn: false,
        selectedDays: const <String>{},
        untilDate: null,
        daysError: null,
        untilDateError: null,
      ));
      return;
    }
    // Pre-select the weekday of the currently chosen date so the user doesn't
    // have to tap it again — only when the day is in the school's open-days set.
    final selectedDays = <String>{...state.selectedDays};
    final dayName = _weekdayName[state.date.weekday];
    if (dayName != null && state.availableWeekDays.contains(dayName)) {
      selectedDays.add(dayName);
    }
    emit(state.copyWith(repeatOn: true, selectedDays: selectedDays));
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

  /// When the user picks a staff member, default the classroom to their primary
  /// one (if any) and prefill shift / break times from the staff's schedule.
  void onStaffSelected(String? code, List<StaffMember> staff) {
    final member = staff.firstWhere(
      (s) => s.code == code,
      orElse: () => const StaffMember(
        code: '',
        name: '',
        primaryClassroomCode: '',
        allowedClassroomCodes: <String>[],
        designation: '',
        phoneNumber: '',
        status: '',
        email: '',
      ),
    );
    final primary = member.primaryClassroomCode.trim();
    final allowed = member.allowedClassroomCodes.toSet();
    Object? classroom = _unset;
    if (primary.isNotEmpty) {
      classroom = primary;
    } else if (allowed.isNotEmpty) {
      classroom = allowed.first;
    } else if (state.selectedClassroomCode != null &&
        allowed.isNotEmpty &&
        !allowed.contains(state.selectedClassroomCode)) {
      classroom = null;
    }
    emit(state.copyWith(
      selectedStaffCode: code,
      selectedClassroomCode: classroom,
    ));
    prefillTimesFromSchedule(code == null || code.isEmpty ? null : member);
  }

  /// Prefills shift start/end and break start/end from the staff's per-day
  /// work + break schedules for the selected date's weekday. If the staff has
  /// no entry for that weekday, both shift and break are cleared.
  void prefillTimesFromSchedule(StaffMember? staff) {
    final key = _prefillKey(staff?.code, state.date);
    _lastPrefilledKey = key;

    if (staff == null) {
      if (state.noScheduleForSelectedDate) {
        emit(state.copyWith(noScheduleForSelectedDate: false));
      }
      return;
    }

    final dayKey = _weekdayDayKey[state.date.weekday] ?? '';
    if (dayKey.isEmpty) return;

    final work = _parseTimeRange(staff.workScheduleByDay[dayKey]);
    final brk = _parseTimeRange(staff.breakScheduleByDay[dayKey]);

    emit(state.copyWith(
      shiftStartError: null,
      shiftEndError: null,
      breakStartError: null,
      breakEndError: null,
      noScheduleForSelectedDate: work == null,
      shiftStart: work?.$1,
      shiftEnd: work?.$2,
      breakStart: brk?.$1,
      breakEnd: brk?.$2,
    ));
  }

  /// Whether the build-time fallback prefill should fire for [staff] — true
  /// when we haven't already prefilled for this (staffCode + date) combo.
  bool shouldPrefillFor(StaffMember staff) {
    final key = _prefillKey(staff.code, state.date);
    return _lastPrefilledKey != key;
  }

  // ─── Validation ────────────────────────────────────────────────────────────

  /// Validates shift/break ordering, break-within-shift, until-date and the
  /// school-hours hard rule. Emits inline error fields on the state and returns
  /// whether the form is good to submit. The school-hours violation also lands
  /// in [AddShiftState.schoolHoursError] so the view can raise a snackbar.
  bool validate() {
    emit(state.copyWith(
      shiftStartError: null,
      shiftEndError: null,
      breakStartError: null,
      breakEndError: null,
      untilDateError: null,
      schoolHoursError: null,
    ));

    final shiftStart = state.shiftStart;
    final shiftEnd = state.shiftEnd;
    if (shiftStart == null || shiftEnd == null) return false;

    final shiftStartMin = _minutesOf(shiftStart);
    final shiftEndMin = _minutesOf(shiftEnd);

    if (shiftEndMin <= shiftStartMin) {
      emit(state.copyWith(shiftEndError: 'Shift end must be after shift start'));
      return false;
    }

    final breakStart = state.breakStart;
    final breakEnd = state.breakEnd;
    final hasBreakStart = breakStart != null;
    final hasBreakEnd = breakEnd != null;
    if (hasBreakStart != hasBreakEnd) {
      emit(state.copyWith(
        breakStartError: !hasBreakStart ? 'Break start is required' : null,
        breakEndError: !hasBreakEnd ? 'Break end is required' : null,
      ));
      return false;
    }

    if (hasBreakStart && hasBreakEnd) {
      final breakStartMin = _minutesOf(breakStart);
      final breakEndMin = _minutesOf(breakEnd);
      if (breakEndMin <= breakStartMin) {
        emit(state.copyWith(
          breakEndError: 'Break end must be after break start',
        ));
        return false;
      }
      if (breakStartMin < shiftStartMin || breakEndMin > shiftEndMin) {
        emit(state.copyWith(
          breakStartError: 'Break must be within shift',
          breakEndError: 'Break must be within shift',
        ));
        return false;
      }
    }

    if (state.repeatOn && state.untilDate != null) {
      if (state.untilDate!.isBefore(state.date) &&
          !_isSameDay(state.untilDate!, state.date)) {
        emit(state.copyWith(
          untilDateError: 'Must be on or after the shift date',
        ));
        return false;
      }
    }

    // Hard rule: shift + break times must fall within the school's open/close
    // hours for the targeted day(s). Skip when school hours haven't loaded yet
    // or the school is closed that day.
    final windows = <(TimeOfDay, TimeOfDay)>[];
    if (state.repeatOn && state.selectedDays.isNotEmpty) {
      for (final day in state.selectedDays) {
        final weekday = _weekDayIndex[day];
        if (weekday == null) continue;
        final w = state._schoolHoursForWeekday(weekday);
        if (w != null) windows.add(w);
      }
    } else {
      final w = state._schoolHoursForDate(state.date);
      if (w != null) windows.add(w);
    }
    for (final window in windows) {
      final schoolStartMin = _minutesOf(window.$1);
      final schoolEndMin = _minutesOf(window.$2);
      final windowLabel =
          '${_formatTime(window.$1)} – ${_formatTime(window.$2)}';
      if (shiftStartMin < schoolStartMin || shiftEndMin > schoolEndMin) {
        emit(state.copyWith(
          schoolHoursError: 'Shift must be within school hours ($windowLabel).',
        ));
        return false;
      }
      if (hasBreakStart && hasBreakEnd) {
        final breakStartMin = _minutesOf(breakStart);
        final breakEndMin = _minutesOf(breakEnd);
        if (breakStartMin < schoolStartMin || breakEndMin > schoolEndMin) {
          emit(state.copyWith(
            schoolHoursError:
                'Break must be within school hours ($windowLabel).',
          ));
          return false;
        }
      }
    }

    return true;
  }

  /// Live view of whether the currently picked shift time falls outside the
  /// selected staff's work-schedule window for the selected date. Returns null
  /// when the rule doesn't apply.
  String? staffAvailabilityError(List<StaffMember> staff) {
    if (state.repeatOn) return null;
    if (state.shiftStart == null || state.shiftEnd == null) return null;
    final code = state.selectedStaffCode;
    if (code == null || code.isEmpty) return null;
    final selectedStaff = findStaff(code, staff);
    if (selectedStaff == null) return null;
    if (_shiftFitsStaffSchedule(selectedStaff, state.date.weekday)) return null;
    return 'Selected shift time is outside this staff availability.';
  }

  /// Returns true iff the current shift + break (if any) sit entirely within
  /// the staff's work-schedule window for [weekday]. Returns true when the
  /// staff has no entry for that day.
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

  /// Returns true when the selected staff has no work schedule entry for the
  /// day(s) the user is targeting.
  bool _staffHasNoScheduleForSelection(StaffMember staff) {
    if (state.repeatOn && state.selectedDays.isNotEmpty) {
      for (final day in state.selectedDays) {
        final raw = staff.workScheduleByDay[day.toUpperCase()]?.trim() ?? '';
        if (raw.isEmpty) return true;
      }
      return false;
    }
    final dayKey = _weekdayDayKey[state.date.weekday] ?? '';
    if (dayKey.isEmpty) return false;
    final raw = staff.workScheduleByDay[dayKey]?.trim() ?? '';
    return raw.isEmpty;
  }

  StaffMember? findStaff(String? code, List<StaffMember> staff) {
    if (code == null || code.isEmpty) return null;
    for (final s in staff) {
      if (s.code == code) return s;
    }
    return null;
  }

  bool _isTeacherDesignation(StaffMember? staff) {
    if (staff == null) return false;
    final designation = staff.designation.trim().toUpperCase();
    if (designation.isEmpty) return false;
    return _teacherDesignationCodes.contains(designation);
  }

  /// Returns `code → name` for the classroom dropdown. If a staff is selected,
  /// restrict to their allowed classrooms; otherwise fall back to [classrooms].
  /// For teacher designations, ADMIN-type locations from
  /// [AddShiftState.adminClassrooms] are merged in.
  Map<String, String> classroomOptions({
    required List<Classroom> classrooms,
    required StaffMember? selectedStaff,
  }) {
    final fullList = <String, String>{
      for (final c in classrooms) c.code: c.name,
    };
    if (selectedStaff == null) return fullList;

    final isTeacher = _isTeacherDesignation(selectedStaff);
    final allowed = selectedStaff.allowedClassroomCodes;

    final Map<String, String> result;
    if (allowed.isEmpty) {
      result = Map<String, String>.from(fullList);
    } else {
      result = <String, String>{};
      for (final code in allowed) {
        final trimmed = code.trim();
        if (trimmed.isEmpty) continue;
        final name = (fullList[trimmed] ??
                selectedStaff.allowedClassroomNameByCode[trimmed] ??
                '')
            .trim();
        result[trimmed] = name.isNotEmpty ? name : trimmed;
      }
      final primary = selectedStaff.primaryClassroomCode.trim();
      if (primary.isNotEmpty && !result.containsKey(primary)) {
        final primaryName =
            (fullList[primary] ?? selectedStaff.primaryClassroomName.trim());
        result[primary] = primaryName.isNotEmpty ? primaryName : primary;
      }
    }

    if (isTeacher) {
      for (final c in state.adminClassrooms) {
        final code = c.code.trim();
        if (code.isEmpty) continue;
        final name = c.name.trim();
        result.putIfAbsent(code, () => name.isNotEmpty ? name : code);
      }
    }
    return result;
  }

  // ─── Submit ──────────────────────────────────────────────────────────────

  /// Runs the full create flow. [validate] must have already passed. The four
  /// callbacks surface the interactive bottom sheets the original widget showed
  /// inline; each returns the user's answer so the cubit can branch.
  Future<AddShiftSubmitOutcome> submit({
    required List<StaffMember> staff,
    required String notes,
    required Future<void> Function(DateTime absentDate) onAbsentBlock,
    required Future<bool> Function() onNoScheduleConfirm,
    required Future<void> Function() onNoAvailability,
    required Future<bool> Function(List<DateTime> conflicts) onConflictConfirm,
  }) async {
    if (state.saving) return const AddShiftSubmitOutcome.cancelled();

    final staffCode = state.selectedStaffCode;
    final classroomCode = state.selectedClassroomCode;
    final shiftStart = state.shiftStart;
    final shiftEnd = state.shiftEnd;
    if (staffCode == null ||
        staffCode.isEmpty ||
        classroomCode == null ||
        classroomCode.isEmpty ||
        shiftStart == null ||
        shiftEnd == null) {
      return const AddShiftSubmitOutcome.cancelled();
    }

    final repeatOn = state.repeatOn;
    final untilDate = state.untilDate;
    final date = state.date;

    // Absence pre-check: GET the staff's absent days across the targeted window.
    emit(state.copyWith(saving: true));
    final absentRangeTo = repeatOn && untilDate != null ? untilDate : date;
    List<DateTime> absentDates;
    try {
      absentDates = await _staffShiftRepository.getStaffAbsentDatesInRange(
        staffCode: staffCode,
        from: date,
        to: absentRangeTo,
      );
    } catch (e) {
      if (!isClosed) emit(state.copyWith(saving: false));
      return AddShiftSubmitOutcome.error(
        ApiErrorHandler.extractErrorMessage(e),
      );
    }

    if (!repeatOn) {
      final blocking = absentDates.where((d) => _isSameDay(d, date));
      if (blocking.isNotEmpty) {
        if (!isClosed) emit(state.copyWith(saving: false));
        await onAbsentBlock(blocking.first);
        return const AddShiftSubmitOutcome.cancelled();
      }
    }

    // For recurring shifts, only absent dates on a selected weekday matter.
    final selectedDayIndices =
        state.selectedDays.map((d) => _weekDayIndex[d]).whereType<int>().toSet();
    var seriesAbsentDates = const <DateTime>[];
    if (repeatOn) {
      seriesAbsentDates = absentDates.where((d) {
        if (selectedDayIndices.isEmpty) return true;
        return selectedDayIndices.contains(d.weekday);
      }).toList(growable: false);
    }

    if (!isClosed) emit(state.copyWith(saving: false));

    // No work schedule defined for the targeted day(s): recurring → hard block,
    // single-day → soft prompt that sends `forceAdd: true` on confirm.
    var forceAdd = false;
    final selectedStaff = findStaff(staffCode, staff);
    if (selectedStaff != null &&
        _staffHasNoScheduleForSelection(selectedStaff)) {
      if (repeatOn) {
        await onNoAvailability();
        return const AddShiftSubmitOutcome.cancelled();
      }
      final confirmed = await onNoScheduleConfirm();
      if (!confirmed) return const AddShiftSubmitOutcome.cancelled();
      forceAdd = true;
    }

    // Recurring shift: each selected weekday must fit the staff's window.
    if (repeatOn && selectedStaff != null) {
      final anyOutside = selectedDayIndices
          .any((wd) => !_shiftFitsStaffSchedule(selectedStaff, wd));
      if (anyOutside) {
        await onNoAvailability();
        return const AddShiftSubmitOutcome.cancelled();
      }
    }

    emit(state.copyWith(saving: true));
    try {
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
      final orgCode =
          (await _storageService.getString(StorageKeys.organizationCode) ?? '')
              .trim();

      if (schoolCode.isEmpty || orgCode.isEmpty) {
        throw Exception('Missing school/organization context');
      }

      // GET existing shifts in the chosen range and prompt to confirm conflicts.
      // The POST always sends `overrideConflicts: true`; the prompt is a UX gate.
      final dateTo = repeatOn && untilDate != null ? untilDate : date;
      final existing = await _getStaffShiftsUseCase(
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: orgCode,
        dateFrom: date,
        dateTo: dateTo,
      );

      final newStartMin = _minutesOf(shiftStart);
      final newEndMin = _minutesOf(shiftEnd);
      final conflicts = <DateTime>[];
      for (final shift in existing) {
        final existingStartMin = _minutesOf(shift.startTime);
        final existingEndMin = _minutesOf(shift.endTime);
        final overlaps =
            newStartMin < existingEndMin && existingStartMin < newEndMin;
        if (!overlaps) continue;
        if (repeatOn) {
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
          return const AddShiftSubmitOutcome.cancelled();
        }
      }

      // Backend expects 0-indexed weekdays (Mon=0..Sun=6).
      final repeatDaysWire = repeatOn
          ? selectedDayIndices.map((d) => d - 1).toList(growable: false)
          : const <int>[];

      final trimmedNotes = notes.trim();
      final request = StaffShiftCreateRequest(
        staffCode: staffCode,
        classroomCode: classroomCode,
        schoolCode: schoolCode,
        organizationCode: orgCode,
        shiftDate: date,
        startTime: shiftStart,
        endTime: shiftEnd,
        breakStartTime: state.breakStart,
        breakEndTime: state.breakEnd,
        publish: state.publish,
        repeat: repeatOn,
        repeatDays: repeatDaysWire,
        repeatUntilDate: repeatOn ? untilDate : null,
        overrideConflicts: true,
        forceAdd: forceAdd,
        notes: trimmedNotes.isEmpty ? null : trimmedNotes,
      );

      final result = await _createStaffShiftUseCase(request);

      // For a recurring series, strip shifts that landed on absent dates.
      // Best-effort: the create already succeeded.
      if (repeatOn && seriesAbsentDates.isNotEmpty) {
        try {
          await _staffShiftRepository.markStaffShiftAbsentDays(
            staffCode: staffCode,
            schoolCode: schoolCode,
            absentDates: seriesAbsentDates,
          );
        } catch (e) {
          debugPrint('markStaffShiftAbsentDays failed: $e');
        }
      }

      if (!isClosed) emit(state.copyWith(saving: false));
      return AddShiftSubmitOutcome.success(created: result.createdCount > 0);
    } catch (e) {
      if (!isClosed) emit(state.copyWith(saving: false));
      return AddShiftSubmitOutcome.error(
        ApiErrorHandler.extractErrorMessage(e),
      );
    }
  }
}

/// Result of [AddShiftCubit.submit]. The view maps this onto a snackbar +
/// navigation; `cancelled` means the user backed out of a prompt (no toast).
class AddShiftSubmitOutcome {
  const AddShiftSubmitOutcome._({
    required this.success,
    required this.created,
    required this.cancelled,
    this.errorMessage,
  });

  const AddShiftSubmitOutcome.success({required bool created})
      : this._(success: true, created: created, cancelled: false);

  const AddShiftSubmitOutcome.cancelled()
      : this._(success: false, created: false, cancelled: true);

  const AddShiftSubmitOutcome.error(String message)
      : this._(
          success: false,
          created: false,
          cancelled: false,
          errorMessage: message,
        );

  final bool success;
  final bool created;
  final bool cancelled;
  final String? errorMessage;
}

// ─── Weekday lookup tables (shared by cubit + state) ─────────────────────────

/// Canonical Mon→Sun ordering. The day grid is filtered to the days the school
/// is open via [AddShiftState.availableWeekDays].
const List<String> _weekDaysOrder = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Map `day name → DateTime.weekday` (1..7). The wire format is 0-indexed
/// (Mon=0 .. Sun=6); conversion happens at the request boundary in [submit].
const Map<String, int> _weekDayIndex = <String, int>{
  'Monday': DateTime.monday,
  'Tuesday': DateTime.tuesday,
  'Wednesday': DateTime.wednesday,
  'Thursday': DateTime.thursday,
  'Friday': DateTime.friday,
  'Saturday': DateTime.saturday,
  'Sunday': DateTime.sunday,
};

/// Inverse of [_weekDayIndex] — `DateTime.weekday` (1..7) → display name.
const Map<int, String> _weekdayName = <int, String>{
  DateTime.monday: 'Monday',
  DateTime.tuesday: 'Tuesday',
  DateTime.wednesday: 'Wednesday',
  DateTime.thursday: 'Thursday',
  DateTime.friday: 'Friday',
  DateTime.saturday: 'Saturday',
  DateTime.sunday: 'Sunday',
};

/// Maps `DateTime.weekday` (1..7) to the uppercase key used in
/// `StaffMember.workScheduleByDay` / `breakScheduleByDay`.
const Map<int, String> _weekdayDayKey = <int, String>{
  DateTime.monday: 'MONDAY',
  DateTime.tuesday: 'TUESDAY',
  DateTime.wednesday: 'WEDNESDAY',
  DateTime.thursday: 'THURSDAY',
  DateTime.friday: 'FRIDAY',
  DateTime.saturday: 'SATURDAY',
  DateTime.sunday: 'SUNDAY',
};

/// Designation codes that should see ADMIN-type locations merged into the
/// Classroom dropdown.
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

/// Parses a raw 24h API time string (`HH:mm` or `HH:mm:ss`) into TimeOfDay.
TimeOfDay? _parse24hTime(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final parts = trimmed.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return TimeOfDay(hour: h, minute: m);
}

/// Parses `"8:00AM - 8:00PM"` (the format saved by `StaffRepositoryImpl`) into
/// a `(start, end)` tuple. Returns null on any parse failure.
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
