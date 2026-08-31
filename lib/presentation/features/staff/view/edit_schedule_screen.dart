import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_profile_tab.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_schedule_cubit.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/presentation/features/scheduling/utils/scheduling_cache_gate.dart';

class EditScheduleScreen extends StatefulWidget {
  const EditScheduleScreen({
    super.key,
    required this.staffCode,
    this.initialSchedules = const [],
  });

  static const String routeName = '/edit-schedule-screen';

  final String staffCode;
  final List<ScheduleEntry> initialSchedules;

  @override
  _EditScheduleScreenState createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  static const Map<String, String> _dayNameByApiKey = <String, String>{
    'MONDAY': 'Monday',
    'TUESDAY': 'Tuesday',
    'WEDNESDAY': 'Wednesday',
    'THURSDAY': 'Thursday',
    'FRIDAY': 'Friday',
    'SATURDAY': 'Saturday',
    'SUNDAY': 'Sunday',
  };

  /// Days the school is open, derived strictly from the regular-schedule API
  /// response (`_schoolMinutesByDay`). Empty until the API loads — the UI
  /// fills in once the resolver is populated.
  List<String> get _allDays {
    const order = <String>[
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    return order
        .where(_schoolMinutesByDay.containsKey)
        .map((k) => _dayNameByApiKey[k]!)
        .toList(growable: false);
  }

  // Store schedule data for each day
  final Map<String, DaySchedule> _schedules = {};
  bool _copyToAllDays = false;
  String? _selectedDay;
  bool _isSubmitting = false;

  /// Weekday key `MONDAY` → school open/close in minutes from midnight.
  Map<String, (int startMin, int endMin)> _schoolMinutesByDay = {};

  String? _schoolHoursLoadError;

  late final StaffScheduleCubit _scheduleCubit;

  @override
  void initState() {
    super.initState();
    _scheduleCubit = serviceLocator<StaffScheduleCubit>();
    // School schedule must load before we can derive _allDays — _initializeSchedules
    // is invoked from the resolver completion handler.
    _loadSchoolRegularSchedules();
  }

  @override
  void dispose() {
    _scheduleCubit.close();
    super.dispose();
  }

  Future<void> _loadSchoolRegularSchedules() async {
    final storage = serviceLocator<StorageService>();
    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    if (schoolCode.isEmpty) {
      if (mounted) {
        setState(() {
          _schoolHoursLoadError =
              'No school selected; school-hour limits are disabled.';
        });
      }
      return;
    }

    try {
      final days = await _scheduleCubit.fetchSchoolRegularSchedules(schoolCode);
      final map = <String, (int, int)>{};
      for (final d in days) {
        // Skip days the school is closed on (INACTIVE) or that aren't a
        // regular weekly schedule (e.g. HOLIDAY) — mirrors
        // SchoolHoursResolver.hoursFor so off days can't be scheduled.
        if (d.status != null && !d.isActive) continue;
        if (!d.isRegular) continue;
        map[d.dayOfWeek] = (
          _localTimeStringToMinutes(d.startTime),
          _localTimeStringToMinutes(d.endTime),
        );
      }
      if (!mounted) return;
      setState(() {
        _schoolMinutesByDay = map;
        _schoolHoursLoadError = null;
        _initializeSchedules();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _schoolHoursLoadError = ApiErrorHandler.extractErrorMessage(e);
      });
    }
  }

  static int _localTimeStringToMinutes(String s) {
    final p = s.trim().split(':');
    if (p.length < 2) return 0;
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    return (h * 60 + m).clamp(0, 24 * 60);
  }

  static int _timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  static String _format12hFromMinutes(int totalMinutes) {
    final clamped = totalMinutes.clamp(0, 24 * 60);
    final h24 = clamped ~/ 60;
    final m = clamped % 60;
    final period = h24 >= 12 ? 'PM' : 'AM';
    var h12 = h24 % 12;
    if (h12 == 0) h12 = 12;
    final mm = m.toString().padLeft(2, '0');
    return '$h12:$mm $period';
  }

  (int, int)? _schoolBoundsForUiDay(String day) =>
      _schoolMinutesByDay[day.toUpperCase()];

  String? _schoolHoursHint(String day) {
    final b = _schoolBoundsForUiDay(day);
    if (b == null) return null;
    return 'School hours: ${_format12hFromMinutes(b.$1)} – ${_format12hFromMinutes(b.$2)}';
  }

  /// Returns an error message if [schedule] violates rules for [day].
  /// Does not require both start/end to be set — you can set start first, then end.
  String? _validateDaySchedule(String day, DaySchedule schedule) {
    if (!schedule.isEnabled) return null;

    final ws = schedule.workStartTime;
    final we = schedule.workEndTime;
    final bs = schedule.breakStartTime;
    final be = schedule.breakEndTime;

    final hasWork = ws != null && we != null;
    final hasBreak = bs != null && be != null;

    if (hasWork) {
      final wsm = _timeOfDayToMinutes(ws!);
      final wem = _timeOfDayToMinutes(we!);
      if (wsm >= wem) {
        return 'On $day, work start must be before work end.';
      }
      final bounds = _schoolBoundsForUiDay(day);
      if (bounds != null) {
        if (wsm < bounds.$1 || wem > bounds.$2) {
          return 'On $day, work hours must fall within school hours '
              '(${_format12hFromMinutes(bounds.$1)} – ${_format12hFromMinutes(bounds.$2)}).';
        }
      }
    }

    if (hasBreak) {
      if (!hasWork) {
        return 'On $day, set work hours before adding a break.';
      }
      final wsm = _timeOfDayToMinutes(ws!);
      final wem = _timeOfDayToMinutes(we!);
      final bsm = _timeOfDayToMinutes(bs!);
      final bem = _timeOfDayToMinutes(be!);
      if (bsm >= bem) {
        return 'On $day, break start must be before break end.';
      }
      if (bsm < wsm || bem > wem) {
        return 'On $day, break time must fall within work hours '
            '(${_format12hFromMinutes(wsm)} – ${_format12hFromMinutes(wem)}).';
      }
    }
    // Partial break: validate break start/end individually when work hours are set
    if (hasWork && (bs != null || be != null)) {
      final wsm = _timeOfDayToMinutes(ws!);
      final wem = _timeOfDayToMinutes(we!);
      if (bs != null) {
        final bsm = _timeOfDayToMinutes(bs!);
        if (bsm < wsm || bsm > wem) {
          return 'On $day, break start must fall within work hours '
              '(${_format12hFromMinutes(wsm)} – ${_format12hFromMinutes(wem)}).';
        }
      }
      if (be != null) {
        final bem = _timeOfDayToMinutes(be!);
        if (bem < wsm || bem > wem) {
          return 'On $day, break end must fall within work hours '
              '(${_format12hFromMinutes(wsm)} – ${_format12hFromMinutes(wem)}).';
        }
      }
    }

    return null;
  }

  void _initializeSchedules() {
    // Initialize with default values or from initialSchedules
    for (final day in _allDays) {
      _schedules[day] = DaySchedule(
        isEnabled: true,
        workStartTime: null,
        workEndTime: null,
        breakStartTime: null,
        breakEndTime: null,
      );
    }
    _selectedDay = _allDays.isNotEmpty ? _allDays.first : null;

    // Load from initial schedules if provided
    for (final schedule in widget.initialSchedules) {
      final day = _capitalizeFirst(schedule.day);
      if (_schedules.containsKey(day)) {
        final workStart = _parseTime(schedule.startTime);
        final workEnd = _parseTime(schedule.endTime);

        if (!schedule.isBreakTime) {
          _schedules[day] = _schedules[day]!.copyWith(
            isEnabled: true,
            workStartTime: workStart,
            workEndTime: workEnd,
          );
        } else {
          _schedules[day] = _schedules[day]!.copyWith(
            isEnabled: true,
            breakStartTime: workStart,
            breakEndTime: workEnd,
          );
        }
      }
    }
  }

  TimeOfDay _parseTime(String timeString) {
    // Accept common formats:
    // - "07:30 AM", "7:30 PM"
    // - "07:30AM", "7:30PM"
    // - "19:30" (24h)
    // - "07:30" (assume 24h)
    final raw = timeString.trim();
    if (raw.isEmpty) {
      return const TimeOfDay(hour: 0, minute: 0);
    }

    // Normalize spaces (also handles "07:30AM" -> "07:30 AM")
    final normalized = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(
          RegExp(r'^(\d{1,2}:\d{2})(AM|PM)$', caseSensitive: false),
          (m) => '${m[1]} ${m[2]!.toUpperCase()}',
        );

    final parts = normalized.split(' ');
    final timePart = parts.first;
    final period = parts.length > 1 ? parts[1].toUpperCase() : null;

    final hm = timePart.split(':');
    if (hm.length < 2) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
    int hour = int.tryParse(hm[0]) ?? 0;
    final minute = int.tryParse(hm[1]) ?? 0;

    // Clamp minute/hour to sensible ranges
    hour = hour.clamp(0, 23);
    final clampedMinute = minute.clamp(0, 59);

    if (period == 'AM' || period == 'PM') {
      // Convert 12h to 24h
      if (period == 'PM' && hour != 12) {
        hour = (hour + 12).clamp(0, 23);
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }
    }

    return TimeOfDay(hour: hour, minute: clampedMinute);
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  void _onTimePicked(String day, TimeType timeType, TimeOfDay selectedTime) {
    final currentSchedule = _schedules[day]!;
    DaySchedule next = currentSchedule;
    if (!currentSchedule.isEnabled) {
      next = next.copyWith(isEnabled: true);
    }
    switch (timeType) {
      case TimeType.workStart:
        next = next.copyWith(workStartTime: selectedTime);
        break;
      case TimeType.workEnd:
        next = next.copyWith(workEndTime: selectedTime);
        break;
      case TimeType.breakStart:
        next = next.copyWith(breakStartTime: selectedTime);
        break;
      case TimeType.breakEnd:
        next = next.copyWith(breakEndTime: selectedTime);
        break;
    }

    if (_copyToAllDays) {
      final merged = <String, DaySchedule>{};
      for (final d in _allDays) {
        if (d == day) {
          merged[d] = next;
        } else {
          merged[d] = _schedules[d]!.copyWith(
            workStartTime: next.workStartTime,
            workEndTime: next.workEndTime,
            breakStartTime: next.breakStartTime,
            breakEndTime: next.breakEndTime,
          );
        }
      }
      for (final d in _allDays) {
        final err = _validateDaySchedule(d, merged[d]!);
        if (err != null) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: err,
            isError: true,
          );
          return;
        }
      }
      setState(() {
        for (final d in _allDays) {
          _schedules[d] = merged[d]!;
        }
        _selectedDay = day;
      });
      return;
    }

    final err = _validateDaySchedule(day, next);
    if (err != null) {
      CoreUtils.showTopSnackBar(context: context, message: err, isError: true);
      return;
    }

    setState(() {
      _schedules[day] = next;
      _selectedDay = day;
    });
  }

  Future<void> _saveSchedule() async {
    if (_isSubmitting) return;

    String _formatLocalTime(TimeOfDay time) {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      return '$h:$m:00';
    }

    // Build API payload for work and break schedules
    final List<Map<String, dynamic>> workSchedules = [];
    final List<Map<String, dynamic>> breakSchedules = [];

    for (final day in _allDays) {
      final schedule = _schedules[day]!;
      if (!schedule.isEnabled)
        continue; // Crossed days: omit from payload so they are removed on backend

      final dayOfWeek = day.toUpperCase(); // MONDAY, TUESDAY, ...

      if (schedule.workStartTime != null && schedule.workEndTime != null) {
        workSchedules.add({
          'dayOfWeek': dayOfWeek,
          // Backend expects java.time.LocalTime which deserializes from string (e.g. "12:05:00")
          'workStartTime': _formatLocalTime(schedule.workStartTime!),
          'workEndTime': _formatLocalTime(schedule.workEndTime!),
        });
      }

      if (schedule.breakStartTime != null && schedule.breakEndTime != null) {
        breakSchedules.add({
          'dayOfWeek': dayOfWeek,
          'breakType': 'LUNCH',
          'breakStartTime': _formatLocalTime(schedule.breakStartTime!),
          'breakEndTime': _formatLocalTime(schedule.breakEndTime!),
        });
      }
    }

    if (workSchedules.isEmpty && breakSchedules.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please set at least one work or break time before saving.',
        isError: true,
      );
      return;
    }

    for (final day in _allDays) {
      final err = _validateDaySchedule(day, _schedules[day]!);
      if (err != null) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: err,
          isError: true,
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final message = await _scheduleCubit.updateSchedules(
        staffCode: widget.staffCode,
        workSchedules: workSchedules,
        breakSchedules: breakSchedules,
      );

      if (!mounted) return;

      // Schedule mutation — poke the scheduling screens so they silently
      // re-pull the staff list on the next visit.
      SchedulingCacheGate.invalidate();

      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: true,
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final message = ApiErrorHandler.extractErrorMessage(e);
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return StaffFormLayout(
      title: "Edit Schedule",
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (_schoolHoursLoadError != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalSpacing,
                vertical: 8,
              ),
              child: Text(
                _schoolHoursLoadError!,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalSpacing,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomToggle(
                  label: 'Copy to all days',
                  isToggled: _copyToAllDays,
                  labelOnLeftSide: true,
                  onToggle: (v) {
                    if (!v) {
                      setState(() => _copyToAllDays = false);
                      return;
                    }
                    final sourceDay = _selectedDay;
                    if (sourceDay == null) {
                      setState(() => _copyToAllDays = true);
                      return;
                    }
                    final source = _schedules[sourceDay]!;
                    final merged = <String, DaySchedule>{};
                    for (final d in _allDays) {
                      merged[d] = d == sourceDay
                          ? source
                          : _schedules[d]!.copyWith(
                              workStartTime: source.workStartTime,
                              workEndTime: source.workEndTime,
                              breakStartTime: source.breakStartTime,
                              breakEndTime: source.breakEndTime,
                            );
                    }
                    for (final d in _allDays) {
                      final err = _validateDaySchedule(d, merged[d]!);
                      if (err != null) {
                        CoreUtils.showTopSnackBar(
                          context: context,
                          message: err,
                          isError: true,
                        );
                        return;
                      }
                    }
                    setState(() {
                      _copyToAllDays = true;
                      for (final d in _allDays) {
                        _schedules[d] = merged[d]!;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.verticalSpacing),
          ..._allDays.map((day) => _buildDayScheduleCard(day, responsive)),
          const SizedBox(height: 12),
        ],
      ),
      bottomBar: Container(
        padding: EdgeInsets.only(
          bottom: safeAreaBottom,
          left: 16,
          right: 16,
          top: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
            topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          ),
        ),
        child: Container(
          height: responsive.buttonHeight,
          decoration: BoxDecoration(
            gradient: AppColors.buildPrimaryGradient(),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 16.0 : 8.0,
            ),
          ),
          child: TextButton(
            onPressed: _isSubmitting ? null : _saveSchedule,
            child: Text(
              'Save',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: responsive.buttonFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayScheduleCard(String day, ResponsiveHelper responsive) {
    final schedule = _schedules[day]!;
    final isEnabled = schedule.isEnabled;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: responsive.horizontalSpacing,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnabled
            ? AppColors.primaryColor.withValues(alpha:0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? AppColors.primaryColor.withValues(alpha:0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: responsive.labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff573353),
                  decoration: isEnabled
                      ? TextDecoration.none
                      : TextDecoration.lineThrough,
                ),
              ),
              isEnabled
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: Colors.redAccent,
                      onPressed: () {
                        setState(() {
                          final curr = _schedules[day]!;
                          _schedules[day] = curr.copyWith(
                            isEnabled: false,
                            workStartTime: null,
                            workEndTime: null,
                            breakStartTime: null,
                            breakEndTime: null,
                          );
                        });
                      },
                    )
                  : TextButton(
                      onPressed: () {
                        setState(() {
                          final curr = _schedules[day]!;
                          _schedules[day] = curr.copyWith(isEnabled: true);
                        });
                      },
                      child: const Text(
                        'Enable',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
            ],
          ),
          if (!isEnabled)
            Text(
              'Holiday',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          if (isEnabled) ...[
            if (_schoolHoursHint(day) != null) ...[
              const SizedBox(height: 6),
              Text(
                _schoolHoursHint(day)!,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey.shade700,
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          _buildTimeSection(
            'Work Time',
            schedule.workStartTime,
            schedule.workEndTime,
            responsive,
            day,
            enabled: isEnabled,
          ),
          const SizedBox(height: 12),
          _buildTimeSection(
            'Break Time',
            schedule.breakStartTime,
            schedule.breakEndTime,
            responsive,
            day,
            enabled: isEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(
    String title,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    ResponsiveHelper responsive,
    String day, {
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: AbsorbPointer(
        absorbing: !enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff573353),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GradientTimePickerField(
                    label: 'Start',
                    minuteInterval: 15,
                    time: startTime,
                    onTimeSelected: (t) => _onTimePicked(
                      day,
                      title == 'Work Time'
                          ? TimeType.workStart
                          : TimeType.breakStart,
                      t,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientTimePickerField(
                    label: 'End',
                    minuteInterval: 15,
                    time: endTime,
                    onTimeSelected: (t) => _onTimePicked(
                      day,
                      title == 'Work Time'
                          ? TimeType.workEnd
                          : TimeType.breakEnd,
                      t,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DaySchedule {
  final bool isEnabled;
  final TimeOfDay? workStartTime;
  final TimeOfDay? workEndTime;
  final TimeOfDay? breakStartTime;
  final TimeOfDay? breakEndTime;

  DaySchedule({
    required this.isEnabled,
    required this.workStartTime,
    required this.workEndTime,
    required this.breakStartTime,
    required this.breakEndTime,
  });

  DaySchedule copyWith({
    bool? isEnabled,
    TimeOfDay? workStartTime,
    TimeOfDay? workEndTime,
    TimeOfDay? breakStartTime,
    TimeOfDay? breakEndTime,
  }) {
    return DaySchedule(
      isEnabled: isEnabled ?? this.isEnabled,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
    );
  }
}

enum TimeType { workStart, workEnd, breakStart, breakEnd }
