import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_profile_tab.dart';
import 'package:intl/intl.dart';

class EditScheduleScreen extends StatefulWidget {
  const EditScheduleScreen({
    super.key,
    this.initialSchedules = const [],
  });

  static const String routeName = '/edit-schedule-screen';

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

  @override
  void initState() {
    super.initState();
    _initializeSchedules();
  }

  void _initializeSchedules() {
    // Initialize with default values or from initialSchedules
    for (final day in _allDays) {
      _schedules[day] = DaySchedule(
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
            workStartTime: workStart,
            workEndTime: workEnd,
          );
        } else {
          _schedules[day] = _schedules[day]!.copyWith(
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
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CalendarDialog(
          isRangePicker: false,
          isTimePicker: true,
          initialTime: initialTime,
        ),
      );
      
      if (result != null && result['time'] != null) {
        final selectedTime = result['time'] as TimeOfDay;
        setState(() {
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
    } catch (e) {
      print('Error opening time picker: $e');
    }
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

  void _saveSchedule() {
    // Convert schedules to the expected format
    final List<ScheduleEntry> schedules = [];
    
    for (final day in _allDays) {
      final schedule = _schedules[day]!;
      final dayLower = day.toLowerCase();
      
      // Add work time
      if (schedule.workStartTime != null && schedule.workEndTime != null) {
      schedules.add(ScheduleEntry(
        day: dayLower,
          startTime: _formatTimeOfDay(schedule.workStartTime)!,
          endTime: _formatTimeOfDay(schedule.workEndTime)!,
        isBreakTime: false,
      ));
      }
      
      // Add break time
      if (schedule.breakStartTime != null && schedule.breakEndTime != null) {
      schedules.add(ScheduleEntry(
        day: dayLower,
          startTime: _formatTimeOfDay(schedule.breakStartTime)!,
          endTime: _formatTimeOfDay(schedule.breakEndTime)!,
        isBreakTime: true,
      ));
      }
    }
    
    // Navigate back with the updated schedules
    Navigator.pop(context, schedules);
  }

  String? _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
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
                    'Copy to all days',
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
            onPressed: _saveSchedule,
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
    final isSelected = _selectedDay == day;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color.fromRGBO(177, 175, 233, 0.45) : const Color.fromRGBO(177, 175, 233, 0.3),
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? Border.all(color: const Color(0xff573353).withOpacity(0.5)) : null,
              ),
            child: Text(
              day,
              style: const TextStyle(
                fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                color: Color(0xff573353),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Work Time section
          _buildTimeSection(
            'Work Time',
            schedule.workStartTime,
            schedule.workEndTime,
            (timeType) => _selectTime(context, day, timeType),
            responsive,
            day,
          ),
          const SizedBox(height: 12),
          
          // Break Time section
          _buildTimeSection(
            'Break Time',
            schedule.breakStartTime,
            schedule.breakEndTime,
            (timeType) => _selectTime(context, day, timeType),
            responsive,
            day,
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
  ) {
    return Column(
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
                onTimeSelected: (_) => onTimeSelected(title == 'Work Time' ? TimeType.workStart : TimeType.breakStart),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientTimePickerField(
                label: 'End',
                time: endTime,
                onTimeSelected: (_) => onTimeSelected(title == 'Work Time' ? TimeType.workEnd : TimeType.breakEnd),
              ),
            ),
          ],
        ),
      ],
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
  final TimeOfDay? workStartTime;
  final TimeOfDay? workEndTime;
  final TimeOfDay? breakStartTime;
  final TimeOfDay? breakEndTime;

  DaySchedule({
    required this.workStartTime,
    required this.workEndTime,
    required this.breakStartTime,
    required this.breakEndTime,
  });

  DaySchedule copyWith({
    TimeOfDay? workStartTime,
    TimeOfDay? workEndTime,
    TimeOfDay? breakStartTime,
    TimeOfDay? breakEndTime,
  }) {
    return DaySchedule(
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
