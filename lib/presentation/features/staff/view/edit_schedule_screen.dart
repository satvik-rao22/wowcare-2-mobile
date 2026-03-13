import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_profile_tab.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

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
  final List<String> _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  // Store schedule data for each day
  final Map<String, DaySchedule> _schedules = {};
  bool _copyToAllDays = false;
  String? _selectedDay;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeSchedules();
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

  String _capitalizeFirst(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Future<void> _selectTime(BuildContext context, String day, TimeType timeType) async {
    final currentSchedule = _schedules[day]!;
    TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0);
    
    switch (timeType) {
      case TimeType.workStart:
        initialTime = currentSchedule.workStartTime ?? initialTime;
        break;
      case TimeType.workEnd:
        initialTime = currentSchedule.workEndTime ?? initialTime;
        break;
      case TimeType.breakStart:
        initialTime = currentSchedule.breakStartTime ?? initialTime;
        break;
      case TimeType.breakEnd:
        initialTime = currentSchedule.breakEndTime ?? initialTime;
        break;
    }

    try {
      final picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              timePickerTheme: const TimePickerThemeData(
                dialHandColor: Colors.white,
              ),
              colorScheme: theme.colorScheme.copyWith(
                primary: AppColors.primaryColor,
                secondary: AppColors.primaryColor,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        _onTimePicked(day, timeType, picked);
      }
    } catch (e) {
      print('Error opening time picker: $e');
    }
  }

  void _onTimePicked(String day, TimeType timeType, TimeOfDay selectedTime) {
    final currentSchedule = _schedules[day]!;
    setState(() {
      if (!currentSchedule.isEnabled) {
        // auto-enable if user picks a time on a disabled day
        _schedules[day] = currentSchedule.copyWith(isEnabled: true);
      }
      switch (timeType) {
        case TimeType.workStart:
          _schedules[day] = currentSchedule.copyWith(workStartTime: selectedTime);
          break;
        case TimeType.workEnd:
          _schedules[day] = currentSchedule.copyWith(workEndTime: selectedTime);
          break;
        case TimeType.breakStart:
          _schedules[day] = currentSchedule.copyWith(breakStartTime: selectedTime);
          break;
        case TimeType.breakEnd:
          _schedules[day] = currentSchedule.copyWith(breakEndTime: selectedTime);
          break;
      }
      _selectedDay = day;
      if (_copyToAllDays) {
        _copyDayScheduleToAll(day);
      }
    });
  }

  void _copyDayScheduleToAll(String sourceDay) {
    final source = _schedules[sourceDay];
    if (source == null) return;
    for (final d in _allDays) {
      if (d == sourceDay) continue;
      _schedules[d] = _schedules[d]!.copyWith(
        workStartTime: source.workStartTime,
        workEndTime: source.workEndTime,
        breakStartTime: source.breakStartTime,
        breakEndTime: source.breakEndTime,
      );
    }
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = serviceLocator<StaffRepository>();
      final message = await repository.updateStaffSchedules(
        staffCode: widget.staffCode,
        workSchedules: workSchedules,
        breakSchedules: breakSchedules,
      );

      if (!mounted) return;

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
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomToggle(
                  label: 'Copy to all days',
                  isToggled: _copyToAllDays,
                  labelOnLeftSide: true,
                  onToggle: (v) {
                    setState(() {
                      _copyToAllDays = v;
                      if (_copyToAllDays) {
                        if (_selectedDay != null) {
                          _copyDayScheduleToAll(_selectedDay!);
                        }
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
          bottom: safeAreaBottom, left: 16, right: 16, top: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
            borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
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
            ? AppColors.primaryColor.withOpacity(0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? AppColors.primaryColor.withOpacity(0.3)
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
                  decoration:
                      isEnabled ? TextDecoration.none : TextDecoration.lineThrough,
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
          const SizedBox(height: 12),
          _buildTimeSection(
            'Work Time',
            schedule.workStartTime,
            schedule.workEndTime,
            (timeType) => _selectTime(context, day, timeType),
            responsive,
            day,
            enabled: isEnabled,
          ),
          const SizedBox(height: 12),
          _buildTimeSection(
            'Break Time',
            schedule.breakStartTime,
            schedule.breakEndTime,
            (timeType) => _selectTime(context, day, timeType),
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
    Function(TimeType) onTimeSelected,
    ResponsiveHelper responsive,
    String day,
    {bool enabled = true}
  ) {
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
                time: startTime,
                onTimeSelected: (t) => _onTimePicked(day, title == 'Work Time' ? TimeType.workStart : TimeType.breakStart, t),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientTimePickerField(
                label: 'End',
                time: endTime,
                onTimeSelected: (t) => _onTimePicked(day, title == 'Work Time' ? TimeType.workEnd : TimeType.breakEnd, t),
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

enum TimeType {
  workStart,
  workEnd,
  breakStart,
  breakEnd,
}
