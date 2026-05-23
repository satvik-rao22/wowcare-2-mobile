import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/scheduling/entities/staff_shift.dart';
import 'package:wowcare/domain/features/scheduling/repositories/staff_shift_repository.dart';
import 'package:wowcare/domain/features/scheduling/usecases/create_staff_shift_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_staff_shifts_usecase.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/utils/school_hours_resolver.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/no_schedule_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/shift_override_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_absent_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_no_availability_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/cubit/scheduling_staff_list_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class AddShiftScreen extends StatefulWidget {
  const AddShiftScreen({
    super.key,
    this.initialDate,
    this.initialClassroomCode,
    this.initialStaffCode,
    this.initialPublish = false,
    this.prefillStaff = true,
  });

  static const String routeName = '/add-shift-screen';

  final DateTime? initialDate;
  final String? initialClassroomCode;
  final String? initialStaffCode;

  /// When true, the "Publish shift" checkbox starts checked.
  final bool initialPublish;

  /// When false, staff is not pre-selected and work/break times are not
  /// auto-filled until the user picks a staff member (staff scheduling flow).
  final bool prefillStaff;

  @override
  State<AddShiftScreen> createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen> {
  /// Canonical Mon→Sun ordering. The actual day grid is filtered down to the
  /// days the school is open (sourced from regular-schedule API) via
  /// [_availableWeekDays].
  static const List<String> _weekDaysOrder = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Map `day name → DateTime.weekday` (1..7). The wire format expected by the
  /// backend is 0-indexed (Mon=0 .. Sun=6); conversion happens at the request
  /// boundary in [_onConfirm].
  static const Map<String, int> _weekDayIndex = <String, int>{
    'Monday': DateTime.monday,
    'Tuesday': DateTime.tuesday,
    'Wednesday': DateTime.wednesday,
    'Thursday': DateTime.thursday,
    'Friday': DateTime.friday,
    'Saturday': DateTime.saturday,
    'Sunday': DateTime.sunday,
  };

  /// Inverse of [_weekDayIndex] — `DateTime.weekday` (1..7) → display name.
  static const Map<int, String> _weekdayName = <int, String>{
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
  static const Map<int, String> _weekdayDayKey = <int, String>{
    DateTime.monday: 'MONDAY',
    DateTime.tuesday: 'TUESDAY',
    DateTime.wednesday: 'WEDNESDAY',
    DateTime.thursday: 'THURSDAY',
    DateTime.friday: 'FRIDAY',
    DateTime.saturday: 'SATURDAY',
    DateTime.sunday: 'SUNDAY',
  };

  /// School's open days for the repeat-days grid — strictly the days the
  /// regular-schedule API returned. Empty while the API is still in flight
  /// (the grid fills in once the resolver loads).
  List<String> get _availableWeekDays {
    final resolver = _schoolHoursResolver;
    if (resolver == null) return const <String>[];
    final result = <String>[];
    for (final name in _weekDaysOrder) {
      final weekday = _weekDayIndex[name];
      if (weekday == null) continue;
      if (_schoolHoursForWeekday(weekday) != null) {
        result.add(name);
      }
    }
    return result;
  }

  DateTime? _date;
  DateTime? _untilDate;
  String? _selectedClassroomCode;
  String? _selectedStaffCode;

  TimeOfDay? _shiftStart;
  TimeOfDay? _shiftEnd;
  TimeOfDay? _breakStart;
  TimeOfDay? _breakEnd;

  bool _repeatOn = false;
  final Set<String> _selectedDays = <String>{};

  final TextEditingController _noteController = TextEditingController();

  String? _untilDateError;
  String? _shiftStartError;
  String? _shiftEndError;
  String? _breakStartError;
  String? _breakEndError;
  String? _daysError;

  /// True when the currently selected staff has no work schedule entry for
  /// the currently selected date's weekday. Drives the inline red message
  /// below the break row.
  bool _noScheduleForSelectedDate = false;

  /// School open/close hours per weekday. Drives the hard-rule check that
  /// shift / break times must fall inside school hours.
  SchoolHoursResolver? _schoolHoursResolver;
  String? _schoolHoursError;

  /// Whether to publish the new shift (or series). Off by default so shifts
  /// land as DRAFT unless the user opts in.
  bool _publish = false;

  bool _saving = false;

  /// Tracks the (staffCode|yyyy-MM-dd) combo we've already prefilled times for,
  /// so the build-time fallback prefill (used when initialStaffCode was passed
  /// via the constructor and the cubit hadn't loaded yet) only fires once per
  /// new combo.
  String? _lastPrefilledKey;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _selectedClassroomCode = widget.initialClassroomCode;
    _selectedStaffCode =
        widget.prefillStaff ? widget.initialStaffCode : null;
    _publish = widget.initialPublish;
    // Shift/break times are intentionally not seeded with hardcoded defaults
    // anymore — they get prefilled from the selected staff's work/break
    // schedule for the selected weekday (PRD: staff default work hours).
    _loadSchoolHours();
  }

  Future<void> _loadSchoolHours() async {
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode =
          (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
      if (schoolCode.isEmpty) return;
      final repo = serviceLocator<StaffRepository>();
      final days =
          await repo.getSchoolRegularSchedules(schoolCode: schoolCode);
      if (!mounted) return;
      setState(() {
        _schoolHoursResolver = SchoolHoursResolver.fromDays(days);
      });
    } catch (_) {
      // Best-effort: without school hours the hard-rule check no-ops.
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Parses a raw 24h API time string (`HH:mm` or `HH:mm:ss`) into TimeOfDay.
  /// Returns null on any parse failure.
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

  /// Returns the school open/close window for the given date, or null if the
  /// school is closed that day or no resolver has loaded yet.
  (TimeOfDay, TimeOfDay)? _schoolHoursForDate(DateTime date) {
    final day = _schoolHoursResolver?.dayFor(date);
    if (day == null) return null;
    final start = _parse24hTime(day.startTime);
    final end = _parse24hTime(day.endTime);
    if (start == null || end == null) return null;
    return (start, end);
  }

  /// Returns the school window for [weekday] (1..7, Monday-first). Iterates
  /// forward up to 7 days starting from [_date] (or today) to find a real
  /// matching weekday — purely a lookup helper for recurring validation.
  (TimeOfDay, TimeOfDay)? _schoolHoursForWeekday(int weekday) {
    final anchor = _date ?? DateTime.now();
    for (var i = 0; i < 7; i++) {
      final probe = anchor.add(Duration(days: i));
      if (probe.weekday == weekday) {
        return _schoolHoursForDate(probe);
      }
    }
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _isFormValid {
    if (_date == null) return false;
    if (_selectedStaffCode == null || _selectedStaffCode!.isEmpty) return false;
    if (_selectedClassroomCode == null || _selectedClassroomCode!.isEmpty) {
      return false;
    }
    if (_shiftStart == null || _shiftEnd == null) return false;
    if (_repeatOn) {
      if (_selectedDays.isEmpty) return false;
      if (_untilDate == null) return false;
    }
    return true;
  }

  void _toggleRepeat(bool value) {
    setState(() {
      _repeatOn = value;
      if (_repeatOn) {
        // Pre-select the weekday of the currently chosen date so the user
        // doesn't have to tap it again — matches the natural "repeat from
        // today's day onwards" expectation. Only auto-select when the day is
        // actually in the school's open-days set.
        if (_date != null) {
          final dayName = _weekdayName[_date!.weekday];
          if (dayName != null && _availableWeekDays.contains(dayName)) {
            _selectedDays.add(dayName);
          }
        }
      } else {
        _selectedDays.clear();
        _untilDate = null;
        _daysError = null;
        _untilDateError = null;
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      final available = _availableWeekDays;
      if (_selectedDays.length == available.length) {
        _selectedDays.clear();
      } else {
        _selectedDays
          ..clear()
          ..addAll(available);
      }
      _daysError = null;
    });
  }

  bool _validate() {
    setState(() {
      _shiftStartError = null;
      _shiftEndError = null;
      _breakStartError = null;
      _breakEndError = null;
      _untilDateError = null;
      _schoolHoursError = null;
    });

    final shiftStartMin = _minutesOf(_shiftStart!);
    final shiftEndMin = _minutesOf(_shiftEnd!);

    if (shiftEndMin <= shiftStartMin) {
      setState(() => _shiftEndError = 'Shift end must be after shift start');
      return false;
    }

    final hasBreakStart = _breakStart != null;
    final hasBreakEnd = _breakEnd != null;
    if (hasBreakStart != hasBreakEnd) {
      setState(() {
        if (!hasBreakStart) _breakStartError = 'Break start is required';
        if (!hasBreakEnd) _breakEndError = 'Break end is required';
      });
      return false;
    }

    if (hasBreakStart && hasBreakEnd) {
      final breakStartMin = _minutesOf(_breakStart!);
      final breakEndMin = _minutesOf(_breakEnd!);
      if (breakEndMin <= breakStartMin) {
        setState(
          () => _breakEndError = 'Break end must be after break start',
        );
        return false;
      }
      if (breakStartMin < shiftStartMin || breakEndMin > shiftEndMin) {
        setState(() {
          _breakStartError = 'Break must be within shift';
          _breakEndError = 'Break must be within shift';
        });
        return false;
      }
    }

    if (_repeatOn && _untilDate != null && _date != null) {
      if (_untilDate!.isBefore(_date!) && !_isSameDay(_untilDate!, _date!)) {
        setState(() => _untilDateError = 'Must be on or after the shift date');
        return false;
      }
    }

    // Hard rule: shift + break times must fall within the school's open/close
    // hours for the targeted day(s). Skip when school hours haven't loaded yet
    // or the school is closed that day (the existing "no schedule" UX already
    // covers staff-side gaps).
    final windows = <(TimeOfDay, TimeOfDay)>[];
    if (_repeatOn && _selectedDays.isNotEmpty) {
      for (final day in _selectedDays) {
        final weekday = _weekDayIndex[day];
        if (weekday == null) continue;
        final w = _schoolHoursForWeekday(weekday);
        if (w != null) windows.add(w);
      }
    } else if (_date != null) {
      final w = _schoolHoursForDate(_date!);
      if (w != null) windows.add(w);
    }
    for (final window in windows) {
      final schoolStartMin = _minutesOf(window.$1);
      final schoolEndMin = _minutesOf(window.$2);
      final windowLabel =
          '${window.$1.format(context)} – ${window.$2.format(context)}';
      if (shiftStartMin < schoolStartMin || shiftEndMin > schoolEndMin) {
        final msg = 'Shift must be within school hours ($windowLabel).';
        setState(() => _schoolHoursError = msg);
        CoreUtils.showTopSnackBar(
          context: context,
          message: msg,
          isError: true,
        );
        return false;
      }
      if (hasBreakStart && hasBreakEnd) {
        final breakStartMin = _minutesOf(_breakStart!);
        final breakEndMin = _minutesOf(_breakEnd!);
        if (breakStartMin < schoolStartMin || breakEndMin > schoolEndMin) {
          final msg = 'Break must be within school hours ($windowLabel).';
          setState(() => _schoolHoursError = msg);
          CoreUtils.showTopSnackBar(
            context: context,
            message: msg,
            isError: true,
          );
          return false;
        }
      }
    }

    // Single-day staff-availability check is informational only: the red
    // hint rendered from [_staffAvailabilityErrorMessage] is just a warning
    // to the user — the submit is still allowed through (the backend handles
    // the create). Recurring shifts handle the same check as a hard-block
    // bottom sheet in [_onConfirm].

    return true;
  }

  /// Live (build-time) view of whether the currently picked shift time falls
  /// outside the selected staff's work-schedule window for the selected date.
  /// Returns null when the rule doesn't apply (recurring, missing fields, no
  /// staff selected, staff has no schedule entry for the day, or time fits).
  String? get _staffAvailabilityErrorMessage {
    if (_repeatOn) return null;
    if (_date == null) return null;
    if (_shiftStart == null || _shiftEnd == null) return null;
    final code = _selectedStaffCode;
    if (code == null || code.isEmpty) return null;
    final staffList = context.read<SchedulingStaffListCubit>().state.staff;
    final selectedStaff = _findStaff(code, staffList);
    if (selectedStaff == null) return null;
    if (_shiftFitsStaffSchedule(selectedStaff, _date!.weekday)) return null;
    return 'Selected shift time is outside this staff availability.';
  }

  /// Returns true iff the current shift + break (if any) sit entirely within
  /// the staff's work-schedule window for [weekday]. Returns true when the
  /// staff has no entry for that day — the upstream "no schedule" gate in
  /// [_onConfirm] handles the missing-entry case explicitly.
  bool _shiftFitsStaffSchedule(StaffMember staff, int weekday) {
    if (_shiftStart == null || _shiftEnd == null) return true;
    final dayKey = _weekdayDayKey[weekday] ?? '';
    if (dayKey.isEmpty) return true;
    final window = _parseTimeRange(staff.workScheduleByDay[dayKey]);
    if (window == null) return true;
    final shiftStartMin = _minutesOf(_shiftStart!);
    final shiftEndMin = _minutesOf(_shiftEnd!);
    final winStartMin = _minutesOf(window.$1);
    final winEndMin = _minutesOf(window.$2);
    if (shiftStartMin < winStartMin || shiftEndMin > winEndMin) return false;
    if (_breakStart != null && _breakEnd != null) {
      final bStart = _minutesOf(_breakStart!);
      final bEnd = _minutesOf(_breakEnd!);
      if (bStart < winStartMin || bEnd > winEndMin) return false;
    }
    return true;
  }

  // ─── Staff / classroom helpers ───────────────────────────────────────────

  /// When the user picks a staff member, default the classroom to their
  /// primary one (if any), and prefill shift / break times from the staff's
  /// work + break schedule for the currently selected date's weekday.
  void _onStaffSelected(String? code, List<StaffMember> staff) {
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
    setState(() {
      _selectedStaffCode = code;
      final primary = member.primaryClassroomCode.trim();
      final allowed = member.allowedClassroomCodes.toSet();
      if (primary.isNotEmpty) {
        _selectedClassroomCode = primary;
      } else if (allowed.isNotEmpty) {
        _selectedClassroomCode = allowed.first;
      } else if (_selectedClassroomCode != null &&
          allowed.isNotEmpty &&
          !allowed.contains(_selectedClassroomCode)) {
        _selectedClassroomCode = null;
      }
    });
    _prefillTimesFromSchedule(code == null || code.isEmpty ? null : member);
  }

  /// Prefills shift start/end and break start/end from the staff's per-day
  /// work + break schedules for `_date`'s weekday. If the staff has no entry
  /// for that weekday, both shift and break are cleared (the user can then
  /// type the times manually).
  void _prefillTimesFromSchedule(StaffMember? staff) {
    if (_date == null) return;
    final key =
        '${staff?.code ?? ''}|${_date!.toIso8601String().substring(0, 10)}';
    _lastPrefilledKey = key;

    if (staff == null) {
      if (_noScheduleForSelectedDate) {
        setState(() => _noScheduleForSelectedDate = false);
      }
      return;
    }

    final dayKey = _weekdayDayKey[_date!.weekday] ?? '';
    if (dayKey.isEmpty) return;

    final work = _parseTimeRange(staff.workScheduleByDay[dayKey]);
    final brk = _parseTimeRange(staff.breakScheduleByDay[dayKey]);

    setState(() {
      _shiftStartError = null;
      _shiftEndError = null;
      _breakStartError = null;
      _breakEndError = null;
      _noScheduleForSelectedDate = work == null;
      if (work != null) {
        _shiftStart = work.$1;
        _shiftEnd = work.$2;
      } else {
        _shiftStart = null;
        _shiftEnd = null;
      }
      if (brk != null) {
        _breakStart = brk.$1;
        _breakEnd = brk.$2;
      } else {
        _breakStart = null;
        _breakEnd = null;
      }
    });
  }

  /// Parses `"8:00AM - 8:00PM"` (the format saved by `StaffRepositoryImpl`)
  /// into a `(start, end)` tuple. Returns null on any parse failure.
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

  /// Returns true when the selected staff has no work schedule entry for
  /// the day(s) the user is targeting. For a single (non-recurring) shift
  /// this checks the selected date's weekday; for a recurring shift it
  /// returns true if any selected weekday is missing a schedule.
  bool _staffHasNoScheduleForSelection(StaffMember staff) {
    if (_repeatOn && _selectedDays.isNotEmpty) {
      for (final day in _selectedDays) {
        final raw = staff.workScheduleByDay[day.toUpperCase()]?.trim() ?? '';
        if (raw.isEmpty) return true;
      }
      return false;
    }
    if (_date == null) return false;
    final dayKey = _weekdayDayKey[_date!.weekday] ?? '';
    if (dayKey.isEmpty) return false;
    final raw = staff.workScheduleByDay[dayKey]?.trim() ?? '';
    return raw.isEmpty;
  }

  StaffMember? _findStaff(String? code, List<StaffMember> staff) {
    if (code == null || code.isEmpty) return null;
    for (final s in staff) {
      if (s.code == code) return s;
    }
    return null;
  }

  /// Returns `code → name` for the classroom dropdown.
  /// If a staff is selected, restrict to their allowed classrooms (per PRD).
  /// Otherwise fall back to the full classroom cubit list.
  Map<String, String> _classroomOptions({
    required ClassroomState classroomState,
    required StaffMember? selectedStaff,
  }) {
    final fullList = <String, String>{
      for (final c in classroomState.classrooms) c.code: c.name,
    };
    if (selectedStaff == null) return fullList;

    final allowed = selectedStaff.allowedClassroomCodes;
    if (allowed.isEmpty) return fullList;

    final result = <String, String>{};
    for (final code in allowed) {
      final trimmed = code.trim();
      if (trimmed.isEmpty) continue;
      // Prefer the human-readable name from the classroom cubit, then fall back
      // to the name embedded in the staff list response.
      final name = (fullList[trimmed] ??
              selectedStaff.allowedClassroomNameByCode[trimmed] ??
              '')
          .trim();
      result[trimmed] = name.isNotEmpty ? name : trimmed;
    }
    // Make sure the primary classroom is represented even if the allowed list
    // came back empty for it.
    final primary = selectedStaff.primaryClassroomCode.trim();
    if (primary.isNotEmpty && !result.containsKey(primary)) {
      final primaryName = (fullList[primary] ??
              selectedStaff.primaryClassroomName.trim());
      result[primary] = primaryName.isNotEmpty ? primaryName : primary;
    }
    return result;
  }

  // ─── Submit ──────────────────────────────────────────────────────────────

  Future<void> _onConfirm() async {
    if (!_validate()) return;
    if (_saving) return;

    // Absence pre-check: GET the staff's absent days across the targeted
    // window. Single-day → hard-block with a warning sheet. Recurring → carry
    // the series-relevant absent dates forward and strip them from the just-
    // created series via the absent-days endpoint after POST succeeds.
    setState(() => _saving = true);
    final shiftRepo = serviceLocator<StaffShiftRepository>();
    final absentRangeTo =
        _repeatOn && _untilDate != null ? _untilDate! : _date!;
    List<DateTime> absentDates;
    try {
      absentDates = await shiftRepo.getStaffAbsentDatesInRange(
        staffCode: _selectedStaffCode!,
        from: _date!,
        to: absentRangeTo,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        CoreUtils.showTopSnackBar(
          context: context,
          message: ApiErrorHandler.extractErrorMessage(e),
          isError: true,
        );
      }
      return;
    }

    if (!_repeatOn) {
      final blocking = absentDates.where((d) => _isSameDay(d, _date!));
      if (blocking.isNotEmpty) {
        if (mounted) setState(() => _saving = false);
        if (!mounted) return;
        await StaffAbsentBottomSheet.show(context, blocking.first);
        return;
      }
    }

    // For recurring shifts, only absent dates on a selected weekday will have
    // produced a shift in the series; everything else is irrelevant.
    var seriesAbsentDates = const <DateTime>[];
    if (_repeatOn) {
      final selectedDayIndices =
          _selectedDays.map((d) => _weekDayIndex[d]).whereType<int>().toSet();
      seriesAbsentDates = absentDates.where((d) {
        if (selectedDayIndices.isEmpty) return true;
        return selectedDayIndices.contains(d.weekday);
      }).toList(growable: false);
    }

    if (mounted) setState(() => _saving = false);
    if (!mounted) return;

    // If the selected staff has no work schedule defined for the targeted
    // day(s), the flow forks:
    //   - Recurring shift → hard block. There's no override; the user must
    //     edit the staff's profile to add availability before a recurring
    //     series can be created.
    //   - Single-day shift → soft prompt that, on confirm, sends `forceAdd:
    //     true` so the backend skips its schedule-required check.
    var forceAdd = false;
    final staffList =
        context.read<SchedulingStaffListCubit>().state.staff;
    final selectedStaff = _findStaff(_selectedStaffCode, staffList);
    if (selectedStaff != null &&
        _staffHasNoScheduleForSelection(selectedStaff)) {
      if (_repeatOn) {
        if (!mounted) return;
        await StaffNoAvailabilityBottomSheet.show(context);
        return;
      }
      final confirmed = await NoScheduleBottomSheet.show(context);
      if (!confirmed) return;
      if (!mounted) return;
      forceAdd = true;
    }

    // Recurring shift: time-vs-staff-window check. Each selected weekday must
    // fit inside the staff's work-schedule window for that day. (Single-day
    // variant is surfaced inline in [_validate] as `_staffAvailabilityError`.)
    if (_repeatOn && selectedStaff != null) {
      final selectedDayIndices =
          _selectedDays.map((d) => _weekDayIndex[d]).whereType<int>().toSet();
      final anyOutside = selectedDayIndices
          .any((wd) => !_shiftFitsStaffSchedule(selectedStaff, wd));
      if (anyOutside) {
        if (!mounted) return;
        await StaffNoAvailabilityBottomSheet.show(context);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode =
          (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final orgCode =
          (await storage.getString(StorageKeys.organizationCode) ?? '').trim();

      if (schoolCode.isEmpty || orgCode.isEmpty) {
        throw Exception('Missing school/organization context');
      }

      // PRD: GET existing shifts in the chosen date range and prompt the user
      // to confirm if any conflict — the bottom sheet is a UX courtesy. The
      // POST itself always sends `overrideConflicts: true`, so the backend
      // overwrites whichever side wins; the prompt is only a "are you sure?"
      // gate the user can still cancel from.
      final dateTo = _repeatOn && _untilDate != null ? _untilDate! : _date!;
      final getShiftsUseCase = serviceLocator<GetStaffShiftsUseCase>();
      final existing = await getShiftsUseCase(
        staffCode: _selectedStaffCode!,
        schoolCode: schoolCode,
        organizationCode: orgCode,
        dateFrom: _date!,
        dateTo: dateTo,
      );

      // For non-recurring: any shift on the chosen day whose time window
      // overlaps the new shift is a conflict.
      // For recurring: any shift in the [_date, _untilDate] range whose
      // weekday is selected AND whose time window overlaps the new shift is
      // a conflict.
      // Two same-day shifts whose times don't overlap (e.g. 9–3 vs 4–6) are
      // not in conflict — they coexist on the same day.
      final selectedDayIndices =
          _selectedDays.map((d) => _weekDayIndex[d]).whereType<int>().toSet();
      final newStartMin = _minutesOf(_shiftStart!);
      final newEndMin = _minutesOf(_shiftEnd!);
      final conflicts = <DateTime>[];
      for (final shift in existing) {
        final existingStartMin = _minutesOf(shift.startTime);
        final existingEndMin = _minutesOf(shift.endTime);
        final overlaps =
            newStartMin < existingEndMin && existingStartMin < newEndMin;
        if (!overlaps) continue;
        if (_repeatOn) {
          if (selectedDayIndices.isEmpty ||
              selectedDayIndices.contains(shift.shiftDate.weekday)) {
            conflicts.add(shift.shiftDate);
          }
        } else {
          if (_isSameDay(shift.shiftDate, _date!)) {
            conflicts.add(shift.shiftDate);
          }
        }
      }

      if (conflicts.isNotEmpty) {
        if (!mounted) return;
        final confirmed = await ShiftOverrideBottomSheet.show(
          context,
          conflictDates: conflicts,
        );
        if (!confirmed) {
          setState(() => _saving = false);
          return;
        }
      }

      // Backend expects 0-indexed weekdays (Mon=0..Sun=6), while internally we
      // track DateTime.weekday (1..7) for comparison with `shift.shiftDate.
      // weekday`. Convert at the wire boundary.
      final repeatDaysWire = _repeatOn
          ? selectedDayIndices.map((d) => d - 1).toList(growable: false)
          : const <int>[];

      final request = StaffShiftCreateRequest(
        staffCode: _selectedStaffCode!,
        classroomCode: _selectedClassroomCode!,
        schoolCode: schoolCode,
        organizationCode: orgCode,
        shiftDate: _date!,
        startTime: _shiftStart!,
        endTime: _shiftEnd!,
        breakStartTime: _breakStart,
        breakEndTime: _breakEnd,
        publish: _publish,
        repeat: _repeatOn,
        repeatDays: repeatDaysWire,
        repeatUntilDate: _repeatOn ? _untilDate : null,
        overrideConflicts: true,
        forceAdd: forceAdd,
        notes: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      final createUseCase = serviceLocator<CreateStaffShiftUseCase>();
      final result = await createUseCase(request);

      // For a recurring series, strip the shifts that landed on dates the
      // staff is marked absent. Best-effort: the primary create has already
      // succeeded, so a failure here just leaves the absent-day shifts in
      // place — surface it but don't fail the whole flow.
      if (_repeatOn && seriesAbsentDates.isNotEmpty) {
        try {
          await shiftRepo.markStaffShiftAbsentDays(
            staffCode: _selectedStaffCode!,
            schoolCode: schoolCode,
            absentDates: seriesAbsentDates,
          );
        } catch (e) {
          debugPrint('markStaffShiftAbsentDays failed: $e');
        }
      }

      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: result.createdCount > 0
            ? 'Shift saved successfully'
            : 'No new shifts were created',
        isSuccess: true,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomPadding = safeBottom > 0 ? safeBottom : 16.0;

    return BlocBuilder<SchedulingStaffListCubit, SchedulingStaffListState>(
      builder: (context, staffState) {
        return BlocBuilder<ClassroomCubit, ClassroomState>(
          builder: (context, classroomState) {
            final staff = staffState.staff;
            final selectedStaff = _findStaff(_selectedStaffCode, staff);

            // Initial prefill for the case where `initialStaffCode` was
            // supplied via the constructor but the staff cubit hadn't loaded
            // its data yet at initState time. Once staff data shows up we
            // prefill once per (staffCode + date) combo so the times reflect
            // the staff's work / break schedule for the selected day.
            if (widget.prefillStaff &&
                selectedStaff != null &&
                _date != null) {
              final key =
                  '${selectedStaff.code}|${_date!.toIso8601String().substring(0, 10)}';
              if (_lastPrefilledKey != key) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _prefillTimesFromSchedule(selectedStaff);
                });
              }
            }

            final staffCodeToName = <String, String>{
              for (final s in staff) s.code: s.name,
            };
            final staffNames = staffCodeToName.values.toList(growable: false);
            final selectedStaffName = staffCodeToName[_selectedStaffCode];

            final classroomCodeToName = _classroomOptions(
              classroomState: classroomState,
              selectedStaff: selectedStaff,
            );
            final classroomNames =
                classroomCodeToName.values.toList(growable: false);
            final selectedClassroomName =
                classroomCodeToName[_selectedClassroomCode];

            return StaffFormLayout(
              title: 'Add Shift',
              bottomBar: Container(
                padding: EdgeInsets.only(
                  bottom: bottomPadding,
                  left: 16,
                  right: 16,
                  top: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 16,
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft:
                        Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                    topRight:
                        Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                  ),
                ),
                child: CustomButtonLayout(
                  confirmButtonLabel: _saving ? 'Saving…' : 'Confirm',
                  onPressedConfirm:
                      (_isFormValid && !_saving) ? _onConfirm : null,
                  showCancelButton: false,
                  isForm: false,
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // PRD: Date on the left, Staff on the right; classroom below.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildDateField(
                          responsive,
                          label: 'Date',
                          date: _date,
                          onDateSelected: (d) {
                            setState(() {
                              _date = d;
                              _schoolHoursError = null;
                            });
                            // Re-prefill so the times reflect the new
                            // weekday's schedule for the currently selected
                            // staff member, if any.
                            _prefillTimesFromSchedule(selectedStaff);
                          },
                        ),
                      ),
                      SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                      Expanded(
                        child: CustomDropdown(
                          label: 'Staff',
                          hintText: 'Select',
                          items: staffNames,
                          selectedItem: selectedStaffName,
                          labelStyle: TextStyle(
                            fontSize: responsive.labelFontSize,
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w400,
                            color: const Color(0xff573353),
                          ),
                          showAsterisk: true,
                          labelBottomSpacing:
                              responsive.isTablet ? 8.0 : 6.0,
                          onSelect: (name) {
                            final code = staffCodeToName.entries
                                .firstWhere(
                                  (e) => e.value == name,
                                  orElse: () =>
                                      const MapEntry<String, String>('', ''),
                                )
                                .key;
                            _onStaffSelected(
                              code.isEmpty ? null : code,
                              staff,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.verticalSpacing),
                  CustomDropdown(
                    label: 'Classroom',
                    hintText: 'Select',
                    items: classroomNames,
                    selectedItem: selectedClassroomName,
                    labelStyle: TextStyle(
                      fontSize: responsive.labelFontSize,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w400,
                      color: const Color(0xff573353),
                    ),
                    showAsterisk: true,
                    labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                    onSelect: (name) {
                      final code = classroomCodeToName.entries
                          .firstWhere(
                            (e) => e.value == name,
                            orElse: () =>
                                const MapEntry<String, String>('', ''),
                          )
                          .key;
                      setState(() => _selectedClassroomCode =
                          code.isEmpty ? null : code);
                    },
                  ),
                  SizedBox(height: responsive.verticalSpacing),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GradientTimePickerField(
                          label: 'Shift Start',
                          isRequired: true,
                          time: _shiftStart,
                          errorText: _shiftStartError,
                          onTimeSelected: (t) => setState(() {
                            _shiftStart = t;
                            _shiftStartError = null;
                            _schoolHoursError = null;
                          }),
                        ),
                      ),
                      SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                      Expanded(
                        child: GradientTimePickerField(
                          label: 'Shift End',
                          isRequired: true,
                          time: _shiftEnd,
                          errorText: _shiftEndError,
                          onTimeSelected: (t) => setState(() {
                            _shiftEnd = t;
                            _shiftEndError = null;
                            _schoolHoursError = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.verticalSpacing),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GradientTimePickerField(
                          label: 'Break Start',
                          time: _breakStart,
                          errorText: _breakStartError,
                          onTimeSelected: (t) => setState(() {
                            _breakStart = t;
                            _breakStartError = null;
                            _schoolHoursError = null;
                          }),
                        ),
                      ),
                      SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                      Expanded(
                        child: GradientTimePickerField(
                          label: 'Break End',
                          time: _breakEnd,
                          errorText: _breakEndError,
                          onTimeSelected: (t) => setState(() {
                            _breakEnd = t;
                            _breakEndError = null;
                            _schoolHoursError = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                  if (_noScheduleForSelectedDate)
                    CoreUtils.buildInlineFieldError(
                      'No schedule available for the selected date.',
                    ),
                  if (_schoolHoursError != null)
                    CoreUtils.buildInlineFieldError(_schoolHoursError),
                  if (_staffAvailabilityErrorMessage != null)
                    CoreUtils.buildInlineFieldError(
                      _staffAvailabilityErrorMessage,
                    ),
                  SizedBox(height: responsive.verticalSpacing),
                  _buildRepeatHeader(responsive),
                  SizedBox(height: responsive.isTablet ? 16.0 : 12.0),
                  if (_repeatOn) ...[
                    _buildDaysGrid(responsive),
                    if (_daysError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _daysError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                    SizedBox(height: responsive.verticalSpacing),
                    _buildDateField(
                      responsive,
                      label: 'Until Date',
                      date: _untilDate,
                      errorText: _untilDateError,
                      firstDate: _date,
                      onDateSelected: (d) => setState(() {
                        _untilDate = d;
                        _untilDateError = null;
                      }),
                    ),
                    SizedBox(height: responsive.verticalSpacing),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildPublishCheckbox(responsive),
                  ),
                  SizedBox(height: responsive.verticalSpacing),
                  _buildNoteField(responsive),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateField(
    ResponsiveHelper responsive, {
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onDateSelected,
    String? errorText,
    DateTime? firstDate,
  }) {
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        CustomDateTimeField(
          key: ValueKey('$label-${date?.toIso8601String() ?? 'empty'}'),
          hasLabel: false,
          fetchInitialTime: false,
          initialDate: date,
          firstDate: firstDate,
          onDateSelected: onDateSelected,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRepeatHeader(ResponsiveHelper responsive) {
    return Row(
      children: [
        CustomToggle(
          label: 'Repeat On',
          isToggled: _repeatOn,
          onToggle: _toggleRepeat,
          labelOnLeftSide: true,
          labelStyle: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
            color: const Color(0xff573353),
          ),
        ),
        const Spacer(),
        if (_repeatOn)
          GestureDetector(
            onTap: _toggleSelectAll,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: AppColors.primaryGradientColors,
              ).createShader(bounds),
              child: Text(
                _selectedDays.length == _availableWeekDays.length
                    ? 'Clear All'
                    : 'Select All',
                style: TextStyle(
                  fontSize: responsive.labelFontSize,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDaysGrid(ResponsiveHelper responsive) {
    final days = _availableWeekDays;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: responsive.isTablet ? 16.0 : 8.0,
        mainAxisSpacing: responsive.isTablet ? 16.0 : 10.0,
        childAspectRatio: responsive.isTablet ? 4.0 : 3.2,
      ),
      itemBuilder: (context, index) {
        final day = days[index];
        final isSelected = _selectedDays.contains(day);
        return Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.themeColor.withValues(alpha: 0.12)
                : AppColors.fieldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CustomCheckbox(
            value: isSelected,
            label: day,
            scale: 1.0,
            labelStyle: TextStyle(
              fontSize: responsive.isTablet ? 14.0 : 12.5,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
            onChanged: (val) {
              setState(() {
                if (val ?? false) {
                  _selectedDays.add(day);
                } else {
                  _selectedDays.remove(day);
                }
                _daysError = null;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildPublishCheckbox(ResponsiveHelper responsive) {
    return CustomCheckbox(
      value: _publish,
      label: 'Publish shift',
      scale: 1.0,
      labelStyle: TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w500,
        color: const Color(0xff573353),
      ),
      onChanged: (val) => setState(() => _publish = val ?? false),
    );
  }

  Widget _buildNoteField(ResponsiveHelper responsive) {
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Note', style: labelStyle),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(
            minHeight: responsive.inputFieldHeight,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            minLines: 1,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xff573353),
              height: 19 / 14,
            ),
            decoration: InputDecoration(
              hintText: 'Write a note',
              hintStyle: labelStyle.copyWith(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
