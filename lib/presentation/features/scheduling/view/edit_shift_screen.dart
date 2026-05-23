import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/scheduling/entities/staff_shift.dart';
import 'package:wowcare/domain/features/scheduling/repositories/staff_shift_repository.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_staff_shifts_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/update_staff_shift_series_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/update_staff_shift_usecase.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/cubit/scheduling_staff_list_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/utils/school_hours_resolver.dart';
import 'package:wowcare/presentation/features/scheduling/view/view_shift_screen.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/no_schedule_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/shift_override_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_absent_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_no_availability_bottom_sheet.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// Whether the Edit screen affects a single occurrence or every occurrence in
/// a recurring series. Drives the screen title and which PUT API is hit on
/// Save (`/api/v1/staff-shifts/{shiftCode}` vs
/// `/api/v1/staff-shifts/series/{seriesCode}`).
enum EditShiftMode { thisShift, entireSeries }

/// Edit form for an existing shift. Mirrors [AddShiftScreen]'s validation
/// rules end-to-end:
///   * shift end > shift start, break end > break start, break ⊂ shift
///   * shift + break within school hours
///   * staff-absence pre-check (single-day → hard block, recurring → strip
///     absent dates after save via the absent-days POST)
///   * staff has a work schedule for every targeted weekday (recurring →
///     hard-block sheet, single → soft prompt with `forceAdd`)
///   * shift time fits inside the staff's work-schedule window for the day
///     (recurring → hard-block sheet, single → inline red hint)
///   * time-aware conflict detection vs existing shifts on the same day
///     (always sends `overrideConflicts: true` so the prompt is just UX)
class EditShiftScreen extends StatefulWidget {
  const EditShiftScreen({
    super.key,
    required this.mode,
    required this.shiftCode,
    required this.staffCode,
    required this.classroomCode,
    required this.initialDate,
    required this.staff,
    required this.classroom,
    required this.shiftStart,
    required this.shiftEnd,
    this.seriesCode,
    this.breakStart,
    this.breakEnd,
    this.note,
    this.status = ShiftStatus.published,
    this.isPublished = true,
    this.selectedDays = const <String>{},
    this.untilDate,
    this.classrooms = const <String>[],
    this.staffOptions = const <String>[],
    this.onSave,
  });

  static const String routeName = '/edit-shift-screen';

  final EditShiftMode mode;
  final String shiftCode;
  final String? seriesCode;
  final String staffCode;
  final String classroomCode;
  final DateTime initialDate;
  final String staff;
  final String classroom;
  final TimeOfDay shiftStart;
  final TimeOfDay shiftEnd;
  final TimeOfDay? breakStart;
  final TimeOfDay? breakEnd;
  final String? note;
  final ShiftStatus status;
  final bool isPublished;
  final Set<String> selectedDays;
  final DateTime? untilDate;
  final List<String> classrooms;
  final List<String> staffOptions;
  final VoidCallback? onSave;

  @override
  State<EditShiftScreen> createState() => _EditShiftScreenState();
}

class _EditShiftScreenState extends State<EditShiftScreen> {
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

  /// Map `day name → DateTime.weekday` (1..7). Wire format expected by the
  /// backend is 0-indexed; conversion happens at the request boundary.
  static const Map<String, int> _weekDayIndex = <String, int>{
    'Monday': DateTime.monday,
    'Tuesday': DateTime.tuesday,
    'Wednesday': DateTime.wednesday,
    'Thursday': DateTime.thursday,
    'Friday': DateTime.friday,
    'Saturday': DateTime.saturday,
    'Sunday': DateTime.sunday,
  };

  static const Map<int, String> _weekdayDayKey = <int, String>{
    DateTime.monday: 'MONDAY',
    DateTime.tuesday: 'TUESDAY',
    DateTime.wednesday: 'WEDNESDAY',
    DateTime.thursday: 'THURSDAY',
    DateTime.friday: 'FRIDAY',
    DateTime.saturday: 'SATURDAY',
    DateTime.sunday: 'SUNDAY',
  };

  late DateTime? _date = widget.initialDate;
  late DateTime? _untilDate = widget.untilDate;
  late String? _selectedClassroomCode = widget.classroomCode.isEmpty
      ? null
      : widget.classroomCode;

  late TimeOfDay? _shiftStart = widget.shiftStart;
  late TimeOfDay? _shiftEnd = widget.shiftEnd;
  late TimeOfDay? _breakStart = widget.breakStart;
  late TimeOfDay? _breakEnd = widget.breakEnd;

  late final Set<String> _selectedDays = Set<String>.of(widget.selectedDays);
  late bool _publish = widget.isPublished;

  late final TextEditingController _noteController =
      TextEditingController(text: widget.note ?? '');

  String? _shiftStartError;
  String? _shiftEndError;
  String? _breakStartError;
  String? _breakEndError;
  String? _untilDateError;
  String? _daysError;
  String? _schoolHoursError;

  /// School open/close hours per weekday. Drives the hard-rule check that
  /// shift / break times must fall inside school hours.
  SchoolHoursResolver? _schoolHoursResolver;

  bool _saving = false;

  bool get _isSeriesMode => widget.mode == EditShiftMode.entireSeries;

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

  @override
  void initState() {
    super.initState();
    _loadSchoolHours();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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

  int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

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

  (TimeOfDay, TimeOfDay)? _schoolHoursForDate(DateTime date) {
    final day = _schoolHoursResolver?.dayFor(date);
    if (day == null) return null;
    final start = _parse24hTime(day.startTime);
    final end = _parse24hTime(day.endTime);
    if (start == null || end == null) return null;
    return (start, end);
  }

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

  /// Parses `"8:00AM - 8:00PM"` (the format used by
  /// `StaffRepositoryImpl._mapStaffListItemToEntity`) into a `(start, end)`
  /// tuple. Returns null on any parse failure.
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

  StaffMember? _findStaff(String code, List<StaffMember> list) {
    if (code.isEmpty) return null;
    for (final s in list) {
      if (s.code == code) return s;
    }
    return null;
  }

  /// Returns true iff the current shift + break (if any) sit entirely within
  /// the staff's work-schedule window for [weekday]. Returns true when the
  /// staff has no entry for that day — the no-schedule gate handles that.
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

  bool _staffHasNoScheduleForSelection(StaffMember staff) {
    if (_isSeriesMode && _selectedDays.isNotEmpty) {
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

  /// Live, build-time view of whether the currently picked shift time falls
  /// outside the staff's work-schedule window for the selected date. Only
  /// applies in single-shift edit mode (recurring uses a bottom sheet).
  String? get _staffAvailabilityErrorMessage {
    if (_isSeriesMode) return null;
    if (_date == null) return null;
    if (_shiftStart == null || _shiftEnd == null) return null;
    if (widget.staffCode.isEmpty) return null;
    final staffList = context.read<SchedulingStaffListCubit>().state.staff;
    final selectedStaff = _findStaff(widget.staffCode, staffList);
    if (selectedStaff == null) return null;
    if (_shiftFitsStaffSchedule(selectedStaff, _date!.weekday)) return null;
    return 'Selected shift time is outside this staff availability.';
  }

  bool get _isFormValid {
    if (_date == null) return false;
    if (_selectedClassroomCode == null || _selectedClassroomCode!.isEmpty) {
      return false;
    }
    if (_shiftStart == null || _shiftEnd == null) return false;
    if (_isSeriesMode) {
      if (_selectedDays.isEmpty) return false;
      if (_untilDate == null) return false;
    }
    return true;
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
      _daysError = null;
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
        setState(() => _breakEndError = 'Break end must be after break start');
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

    if (_isSeriesMode && _untilDate != null && _date != null) {
      if (_untilDate!.isBefore(_date!) && !_isSameDay(_untilDate!, _date!)) {
        setState(() => _untilDateError = 'Must be on or after the shift date');
        return false;
      }
    }

    final windows = <(TimeOfDay, TimeOfDay)>[];
    if (_isSeriesMode && _selectedDays.isNotEmpty) {
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

    // Single-shift staff-availability check is informational only — the red
    // hint rendered from [_staffAvailabilityErrorMessage] is just a warning;
    // the PUT itself is still allowed. Recurring handles this as a hard-block
    // bottom sheet in [_onSave].

    return true;
  }

  Future<void> _onSave() async {
    if (!_validate()) return;
    if (_saving) return;

    // Absence pre-check.
    setState(() => _saving = true);
    final shiftRepo = serviceLocator<StaffShiftRepository>();
    final absentRangeTo =
        _isSeriesMode && _untilDate != null ? _untilDate! : _date!;
    List<DateTime> absentDates;
    try {
      absentDates = await shiftRepo.getStaffAbsentDatesInRange(
        staffCode: widget.staffCode,
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

    if (!_isSeriesMode) {
      final blocking = absentDates.where((d) => _isSameDay(d, _date!));
      if (blocking.isNotEmpty) {
        if (mounted) setState(() => _saving = false);
        if (!mounted) return;
        await StaffAbsentBottomSheet.show(context, blocking.first);
        return;
      }
    }

    var seriesAbsentDates = const <DateTime>[];
    if (_isSeriesMode) {
      final selectedDayIndices =
          _selectedDays.map((d) => _weekDayIndex[d]).whereType<int>().toSet();
      seriesAbsentDates = absentDates.where((d) {
        if (selectedDayIndices.isEmpty) return true;
        return selectedDayIndices.contains(d.weekday);
      }).toList(growable: false);
    }

    if (mounted) setState(() => _saving = false);
    if (!mounted) return;

    // No-schedule check.
    var forceAdd = false;
    final staffList = context.read<SchedulingStaffListCubit>().state.staff;
    final selectedStaff = _findStaff(widget.staffCode, staffList);
    if (selectedStaff != null &&
        _staffHasNoScheduleForSelection(selectedStaff)) {
      if (_isSeriesMode) {
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
    // fit inside the staff's work-schedule window for that day. Single-day
    // variant is surfaced inline in [_validate] as `_staffAvailabilityError`.
    if (_isSeriesMode && selectedStaff != null) {
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

      // Time-aware conflict detection — the same logic the Add screen uses.
      // Exclude the shift being edited (single mode) or every shift already in
      // this series (series mode) so we don't falsely flag a shift as
      // conflicting with itself.
      final dateTo =
          _isSeriesMode && _untilDate != null ? _untilDate! : _date!;
      final getShiftsUseCase = serviceLocator<GetStaffShiftsUseCase>();
      final existing = await getShiftsUseCase(
        staffCode: widget.staffCode,
        schoolCode: schoolCode,
        organizationCode: orgCode,
        dateFrom: _date!,
        dateTo: dateTo,
      );

      final selectedDayIndices =
          _selectedDays.map((d) => _weekDayIndex[d]).whereType<int>().toSet();
      final newStartMin = _minutesOf(_shiftStart!);
      final newEndMin = _minutesOf(_shiftEnd!);
      final conflicts = <DateTime>[];
      for (final shift in existing) {
        if (shift.shiftCode == widget.shiftCode) continue;
        if (_isSeriesMode &&
            widget.seriesCode != null &&
            widget.seriesCode!.isNotEmpty &&
            shift.seriesCode == widget.seriesCode) {
          continue;
        }
        final existingStartMin = _minutesOf(shift.startTime);
        final existingEndMin = _minutesOf(shift.endTime);
        final overlaps =
            newStartMin < existingEndMin && existingStartMin < newEndMin;
        if (!overlaps) continue;
        if (_isSeriesMode) {
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

      if (_isSeriesMode) {
        final seriesCode = (widget.seriesCode ?? '').trim();
        if (seriesCode.isEmpty) {
          throw Exception('Missing series code for series update');
        }
        // Wire format: 0=Mon … 6=Sun.
        final repeatDaysWire = selectedDayIndices
            .map((d) => d - 1)
            .toList(growable: false);
        final request = StaffShiftSeriesUpdateRequest(
          seriesCode: seriesCode,
          shiftCode: widget.shiftCode,
          staffCode: widget.staffCode,
          schoolCode: schoolCode,
          organizationCode: orgCode,
          shiftDate: _date!,
          classroomCode: _selectedClassroomCode!,
          startTime: _shiftStart!,
          endTime: _shiftEnd!,
          breakStartTime: _breakStart,
          breakEndTime: _breakEnd,
          notes: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          overrideConflicts: true,
          repeat: true,
          repeatDays: repeatDaysWire,
          repeatUntilDate: _untilDate,
          publish: _publish,
        );
        await serviceLocator<UpdateStaffShiftSeriesUseCase>()(request);

        // Strip shifts that landed on absent days, same as Add screen.
        if (seriesAbsentDates.isNotEmpty) {
          try {
            await shiftRepo.markStaffShiftAbsentDays(
              staffCode: widget.staffCode,
              schoolCode: schoolCode,
              absentDates: seriesAbsentDates,
            );
          } catch (e) {
            debugPrint('markStaffShiftAbsentDays failed: $e');
          }
        }
      } else {
        final request = StaffShiftUpdateRequest(
          shiftCode: widget.shiftCode,
          staffCode: widget.staffCode,
          schoolCode: schoolCode,
          organizationCode: orgCode,
          classroomCode: _selectedClassroomCode!,
          shiftDate: _date!,
          startTime: _shiftStart!,
          endTime: _shiftEnd!,
          breakStartTime: _breakStart,
          breakEndTime: _breakEnd,
          notes: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          overrideConflicts: true,
          forceAdd: forceAdd,
          publish: _publish,
        );
        await serviceLocator<UpdateStaffShiftUseCase>()(request);
      }

      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Shift updated successfully',
        isSuccess: true,
      );
      widget.onSave?.call();
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
    final title = _isSeriesMode ? 'Edit entire series' : 'Edit this shift';

    return BlocBuilder<ClassroomCubit, ClassroomState>(
      builder: (context, classroomState) {
        final classroomCodeToName = <String, String>{
          for (final c in classroomState.classrooms) c.code: c.name,
        };
        final classroomNames =
            classroomCodeToName.values.toList(growable: false);
        final selectedClassroomName =
            classroomCodeToName[_selectedClassroomCode] ?? widget.classroom;

        return StaffFormLayout(
          title: title,
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
                topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
              ),
            ),
            child: CustomButtonLayout(
              confirmButtonLabel: _saving ? 'Saving…' : 'Save',
              onPressedConfirm:
                  (_isFormValid && !_saving) ? _onSave : null,
              showCancelButton: false,
              isForm: false,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildStatusHeader(responsive),
              SizedBox(height: responsive.verticalSpacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDateField(
                      responsive,
                      label: 'Date',
                      date: _date,
                      onDateSelected: (d) => setState(() {
                        _date = d;
                        _schoolHoursError = null;
                      }),
                    ),
                  ),
                  SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                  Expanded(
                    child: CustomDropdown(
                      label: 'Staff',
                      hintText: 'Select',
                      items: <String>[widget.staff],
                      selectedItem: widget.staff,
                      labelStyle: TextStyle(
                        fontSize: responsive.labelFontSize,
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w400,
                        color: const Color(0xff573353),
                      ),
                      showAsterisk: true,
                      labelBottomSpacing:
                          responsive.isTablet ? 8.0 : 6.0,
                      onSelect: (_) {},
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
              if (_schoolHoursError != null)
                CoreUtils.buildInlineFieldError(_schoolHoursError),
              if (_staffAvailabilityErrorMessage != null)
                CoreUtils.buildInlineFieldError(
                  _staffAvailabilityErrorMessage,
                ),
              SizedBox(height: responsive.verticalSpacing),
              if (_isSeriesMode) ...[
                _buildRepeatHeader(responsive),
                SizedBox(height: responsive.isTablet ? 16.0 : 12.0),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildPublishCheckbox(responsive),
                ),
                SizedBox(height: responsive.verticalSpacing),
                _buildDateField(
                  responsive,
                  label: 'Until Date',
                  date: _untilDate,
                  firstDate: _date,
                  errorText: _untilDateError,
                  onDateSelected: (d) => setState(() {
                    _untilDate = d;
                    _untilDateError = null;
                  }),
                ),
                SizedBox(height: responsive.verticalSpacing),
                _buildNoteField(responsive),
              ] else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildPublishCheckbox(responsive),
                ),
                SizedBox(height: responsive.verticalSpacing),
                _buildNoteField(responsive),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader(ResponsiveHelper responsive) {
    final formatted = DateFormat('MMM d, yyyy').format(widget.initialDate);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.isTablet ? 8.0 : 4.0,
      ),
      child: Text(
        'Shift on $formatted (${widget.status.label})',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: responsive.titleFontSize * 0.85,
          fontWeight: FontWeight.w600,
          color: const Color(0xff573353),
        ),
      ),
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
        Text(
          'Repeat On',
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
            color: const Color(0xff573353),
          ),
        ),
        const Spacer(),
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
              hintText: 'Eg. Please note the change in classroom location',
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
