import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
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
    // Parse time string like "07:30 AM" to TimeOfDay
    final parts = timeString.split(' ');
    final timePart = parts[0].split(':');
    final period = parts[1];
    
    int hour = int.parse(timePart[0]);
    final minute = int.parse(timePart[1]);
    
    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }
    
    return TimeOfDay(hour: hour, minute: minute);
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

    // Build API payload for work and break schedules
    final List<Map<String, dynamic>> workSchedules = [];
    final List<Map<String, dynamic>> breakSchedules = [];

    for (final day in _allDays) {
      final schedule = _schedules[day]!;
      final dayOfWeek = day.toUpperCase(); // MONDAY, TUESDAY, ...

      if (schedule.workStartTime != null && schedule.workEndTime != null) {
        final startHour = schedule.workStartTime!.hour.toString().padLeft(2, '0');
        final startMinute = schedule.workStartTime!.minute.toString().padLeft(2, '0');
        final endHour = schedule.workEndTime!.hour.toString().padLeft(2, '0');
        final endMinute = schedule.workEndTime!.minute.toString().padLeft(2, '0');

        workSchedules.add({
          'dayOfWeek': dayOfWeek,
          // Backend expects java.time.LocalTime as a string (e.g. "09:00:00")
          'workStartTime': '$startHour:$startMinute:00',
          'workEndTime': '$endHour:$endMinute:00',
        });
      }

      if (schedule.breakStartTime != null && schedule.breakEndTime != null) {
        final startHour = schedule.breakStartTime!.hour.toString().padLeft(2, '0');
        final startMinute = schedule.breakStartTime!.minute.toString().padLeft(2, '0');
        final endHour = schedule.breakEndTime!.hour.toString().padLeft(2, '0');
        final endMinute = schedule.breakEndTime!.minute.toString().padLeft(2, '0');

        breakSchedules.add({
          'dayOfWeek': dayOfWeek,
          'breakType': 'LUNCH',
          // Backend expects java.time.LocalTime as a string (e.g. "12:00:00")
          'breakStartTime': '$startHour:$startMinute:00',
          'breakEndTime': '$endHour:$endMinute:00',
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
            padding: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Apply Previous Time',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff573353),
                    ),
                  ),
                ),
                CustomToggle(
                  label: '',
                  isToggled: _copyToAllDays,
                  onToggle: (v) {
                    setState(() {
                      _copyToAllDays = v;
                      if (_copyToAllDays && _selectedDay != null) {
                        _copyDayScheduleToAll(_selectedDay!);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          // Header row (only for tablet/large screens)
          if (responsive.isTablet) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  SizedBox(width: 120),
                  Expanded(
                    child: Text(
                      'Work Time',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff573353),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Break Time',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff573353),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          ..._allDays.map((day) => _buildDaySchedule(day, responsive)),
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

  Widget _buildDaySchedule(String day, ResponsiveHelper responsive) {
    final schedule = _schedules[day]!;
    final isEnabled = schedule.isEnabled;
    // Mobile: stacked sections; Tablet: horizontal three-column row
    if (!responsive.isTablet) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x0d573353),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1a573353)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() {
                final curr = _schedules[day]!;
                final newEnabled = !curr.isEnabled;
                _schedules[day] = curr.copyWith(
                  isEnabled: newEnabled,
                  // Clear times when disabling
                  workStartTime: newEnabled ? curr.workStartTime : null,
                  workEndTime: newEnabled ? curr.workEndTime : null,
                  breakStartTime: newEnabled ? curr.breakStartTime : null,
                  breakEndTime: newEnabled ? curr.breakEndTime : null,
                );
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isEnabled ? const Color.fromRGBO(177, 175, 233, 0.45) : const Color.fromRGBO(177, 175, 233, 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: isEnabled ? Border.all(color: const Color(0xff573353).withOpacity(0.5)) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      day,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff573353).withOpacity(isEnabled ? 1 : 0.5),
                        decoration: isEnabled ? TextDecoration.none : TextDecoration.lineThrough,
                      ),
                    ),
                    if (!isEnabled)
                      const Text(
                        'Holiday',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff573353),
                        ),
                      ),
                  ],
                ),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              final curr = _schedules[day]!;
              final newEnabled = !curr.isEnabled;
              _schedules[day] = curr.copyWith(
                isEnabled: newEnabled,
                workStartTime: newEnabled ? curr.workStartTime : null,
                workEndTime: newEnabled ? curr.workEndTime : null,
                breakStartTime: newEnabled ? curr.breakStartTime : null,
                breakEndTime: newEnabled ? curr.breakEndTime : null,
              );
            }),
            child: Container(
              width: 120,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isEnabled ? const Color.fromRGBO(177, 175, 233, 0.45) : const Color.fromRGBO(177, 175, 233, 0.2),
                borderRadius: BorderRadius.circular(16),
                border: isEnabled ? Border.all(color: const Color(0xff573353).withOpacity(0.5)) : null,
              ),
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff573353).withOpacity(isEnabled ? 1 : 0.5),
                  decoration: isEnabled ? TextDecoration.none : TextDecoration.lineThrough,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStartEndRow(
              startTime: isEnabled ? schedule.workStartTime : null,
              endTime: schedule.workEndTime,
              onStartPicked: (t) => _onTimePicked(day, TimeType.workStart, t),
              onEndPicked: (t) => _onTimePicked(day, TimeType.workEnd, t),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStartEndRow(
              startTime: isEnabled ? schedule.breakStartTime : null,
              endTime: schedule.breakEndTime,
              onStartPicked: (t) => _onTimePicked(day, TimeType.breakStart, t),
              onEndPicked: (t) => _onTimePicked(day, TimeType.breakEnd, t),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartEndRow({
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
    required ValueChanged<TimeOfDay> onStartPicked,
    required ValueChanged<TimeOfDay> onEndPicked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Expanded(
              child: Text(
                'Start',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff573353),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'End',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff573353),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: GradientTimePickerField(
                label: '',
                time: startTime,
                onTimeSelected: onStartPicked,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientTimePickerField(
                label: '',
                time: endTime,
                onTimeSelected: onEndPicked,
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildTimeField(
    String label,
    String time,
    VoidCallback onTap,
    ResponsiveHelper responsive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xff573353),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.isTablet ? 16.0 : 12.0,
            vertical: responsive.isTablet ? 16.0 : 12.0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: Row(
            children: [
              Expanded(
                  child: Text(
                    time,
                  style: const TextStyle(
                      color: Colors.black,
                    fontSize: 15,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  MediaRes.clock_icon,
                  height: responsive.isTablet ? 20.0 : 18.0,
                  colorFilter: const ColorFilter.mode(Color(0xff573353), BlendMode.srcIn),
                ),
              ],
              ),
          ),
        ),
      ],
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
