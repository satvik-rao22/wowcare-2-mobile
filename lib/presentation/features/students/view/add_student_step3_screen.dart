import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/util/core_utils.dart';

class AddStudentStep3Screen extends StatefulWidget {
  const AddStudentStep3Screen({
    super.key,
    this.initialSchedule,
    this.title,
    this.primaryButtonLabel,
    this.showSkip = true,
  });

  static const String routeName = '/add-student-step3-screen';

  final Map<String, Map<String, TimeOfDay>>? initialSchedule;
  /// Optional heading; defaults to "Add Student - Step 3 of 3 (Optional)".
  final String? title;
  /// Optional primary CTA label; defaults to "Next".
  final String? primaryButtonLabel;
  /// Whether to show the "Skip" button in the bottom bar. Defaults to true.
  final bool showSkip;

  @override
  _AddStudentStep3ScreenState createState() => _AddStudentStep3ScreenState();
}

class _AddStudentStep3ScreenState extends State<AddStudentStep3Screen> {
  // Schedule data: day -> {start: TimeOfDay, end: TimeOfDay}
  Map<String, Map<String, TimeOfDay>> _schedule = {};
  bool _copyToAllDays = false;

  // School working days and hours (should come from settings/API)
  final List<String> _workingDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  final TimeOfDay _schoolStartTime = const TimeOfDay(hour: 7, minute: 0);
  final TimeOfDay _schoolEndTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    if (widget.initialSchedule != null) {
      _schedule = Map<String, Map<String, TimeOfDay>>.from(
        widget.initialSchedule!.map(
          (key, value) => MapEntry(
            key,
            Map<String, TimeOfDay>.from(
              value.map(
                (k, v) => MapEntry(k, TimeOfDay(hour: v.hour, minute: v.minute)),
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _selectTime(String day, String timeType) async {
    final currentSchedule = _schedule[day];
    final currentTime = timeType == 'start'
        ? (currentSchedule?['start'] ?? _schoolStartTime)
        : (currentSchedule?['end'] ?? _schoolEndTime);

    try {
      final picked = await showTimePicker(
        context: context,
        initialTime: currentTime,
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
        // Validate time is within school working hours
        if (!_isTimeInWorkingHours(picked)) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Time must be within school working hours (${_formatTime(_schoolStartTime)} - ${_formatTime(_schoolEndTime)})',
            isError: true,
          );
          return;
        }

        setState(() {
          if (_schedule[day] == null) {
            _schedule[day] = {};
          }
          _schedule[day]![timeType] = picked;

          // Validate end time is after start time
          if (_schedule[day]!['start'] != null && _schedule[day]!['end'] != null) {
            final start = _schedule[day]!['start']!;
            final end = _schedule[day]!['end']!;
            if (!_isAfter(end, start)) {
              CoreUtils.showTopSnackBar(
                context: context,
                message: 'End time must be after start time',
                isError: true,
              );
              // Auto-adjust end time to be 1 hour after start
              _schedule[day]!['end'] = _addMinutes(start, 60);
              if (!_isTimeInWorkingHours(_schedule[day]!['end']!)) {
                _schedule[day]!['end'] = _schoolEndTime;
              }
            }
          }

          if (_copyToAllDays) {
            _copyScheduleFromDay(day);
          }
        });
      }
    } catch (e) {
      print('Error opening time picker: $e');
    }
  }

  void _removeDay(String day) {
    setState(() {
      _schedule.remove(day);
    });
  }

  bool _isTimeInWorkingHours(TimeOfDay time) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = _schoolStartTime.hour * 60 + _schoolStartTime.minute;
    final endMinutes = _schoolEndTime.hour * 60 + _schoolEndTime.minute;
    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  bool _isAfter(TimeOfDay a, TimeOfDay b) {
    final aMinutes = a.hour * 60 + a.minute;
    final bMinutes = b.hour * 60 + b.minute;
    return aMinutes > bMinutes;
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: (totalMinutes ~/ 60) % 24, minute: totalMinutes % 60);
  }

  void _copyScheduleFromDay(String sourceDay) {
    final source = _schedule[sourceDay];
    if (source == null) return;
    final start = source['start'];
    final end = source['end'];
    if (start == null || end == null) return;

    for (final day in _workingDays) {
      if (day == sourceDay) continue;
      _schedule[day] = {
        'start': TimeOfDay(hour: start.hour, minute: start.minute),
        'end': TimeOfDay(hour: end.hour, minute: end.minute),
      };
    }
  }

  void _copyFromFirstAvailableDay() {
    for (final day in _workingDays) {
      final s = _schedule[day];
      if (s != null && s['start'] != null && s['end'] != null) {
        _copyScheduleFromDay(day);
        break;
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _onNext() {
    if (_schedule.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please add at least one day to the schedule',
        isError: true,
      );
      return;
    }

    // Validate each day has both start and end times, and end > start
    for (final entry in _schedule.entries) {
      final day = entry.key;
      final times = entry.value;

      if (times['start'] == null || times['end'] == null) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please set both start and end times for $day',
          isError: true,
        );
        return;
      }

      if (!_isAfter(times['end']!, times['start']!)) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'End time must be after start time for $day',
          isError: true,
        );
        return;
      }
    }

    Navigator.pop(context, _schedule);
  }

  void _onSkip() {
    Navigator.pop(context, null);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(hasBackButton: true),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buildScaffoldGradient(),
                ),
                child: Image.asset(
                  MediaRes.wowcareMobileBg,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.title ?? 'Add Student - Step 3 of 3 (Optional)',
                      style: TextStyle(
                        fontFamily: "Manrope",
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff573353),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
                Expanded(
                  child: Container(
                    width: responsive.containerWidth,
                    margin: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
                    padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              SizedBox(height: responsive.verticalSpacing),
                              Text(
                                'Schedule',
                                style: TextStyle(
                                  fontSize: responsive.labelFontSize,
                                  fontFamily: "Manrope",
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xff573353),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select days and times for this student. Times must be within school working hours (${_formatTime(_schoolStartTime)} - ${_formatTime(_schoolEndTime)}).',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Copy to all days',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff573353),
                                    ),
                                  ),
                                  Switch(
                                    value: _copyToAllDays,
                                    activeColor: AppColors.primaryColor,
                                    onChanged: (v) {
                                      setState(() {
                                        _copyToAllDays = v;
                                        if (_copyToAllDays) {
                                          _copyFromFirstAvailableDay();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: responsive.verticalSpacing),
                              // Day selection and time pickers
                              ..._workingDays.map((day) => _buildDayScheduleCard(day, responsive)),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
        bottomNavigationBar: Container(
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
          child: Row(
            children: [
              if (widget.showSkip) ...[
                Expanded(
                  child: Container(
                    height: responsive.buttonHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryColor),
                      borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
                    ),
                    child: TextButton(
                      onPressed: _onSkip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: responsive.buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Container(
                  height: responsive.buttonHeight,
                  decoration: BoxDecoration(
                    gradient: AppColors.buildPrimaryGradient(),
                    borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
                  ),
                  child: TextButton(
                    onPressed: _onNext,
                    child: Text(
                      widget.primaryButtonLabel ?? 'Next',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayScheduleCard(String day, ResponsiveHelper responsive) {
    final hasSchedule = _schedule.containsKey(day);
    final schedule = _schedule[day];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasSchedule ? AppColors.primaryColor.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSchedule ? AppColors.primaryColor.withOpacity(0.3) : Colors.grey.shade300,
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
                ),
              ),
              if (hasSchedule)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.red,
                  onPressed: () => _removeDay(day),
                ),
            ],
          ),
          if (hasSchedule) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    'Start Time',
                    schedule!['start'] ?? _schoolStartTime,
                    () => _selectTime(day, 'start'),
                    responsive,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeField(
                    'End Time',
                    schedule['end'] ?? _schoolEndTime,
                    () => _selectTime(day, 'end'),
                    responsive,
                  ),
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _schedule[day] = {
                        'start': _schoolStartTime,
                        'end': _addMinutes(_schoolStartTime, 60),
                      };
                      if (_copyToAllDays) {
                        _copyScheduleFromDay(day);
                      }
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  ),
                  child: Text(
                    'Add Schedule',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeField(
    String label,
    TimeOfDay time,
    VoidCallback onTap,
    ResponsiveHelper responsive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Manrope',
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x66573353)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(time),
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.inputFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff573353),
                  ),
                ),
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

