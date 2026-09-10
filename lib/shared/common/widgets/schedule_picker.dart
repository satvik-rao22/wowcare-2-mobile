
import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

class SchedulePicker extends StatefulWidget {
  const SchedulePicker({super.key});

  @override
  State<SchedulePicker> createState() => _SchedulePickerState();
}

class _SchedulePickerState extends State<SchedulePicker> {
  final Map<String, TimeSlot> availability = {};

  final List<String> fullWeekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday'
  ];

  String _formatTimeSlot(TimeSlot slot) {
    final start12 = _format12Hour(slot.start);
    final end12 = _format12Hour(slot.end);
    return '$start12 – $end12';
  }

  String _format12Hour(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaterialHues.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fullWeekdays.map((day) {
              final bool isAvailable = availability.containsKey(day);
              final TimeSlot? slot = availability[day];

              return GestureDetector(
                onTap: () => _showTimePickerDialog(context, day),
                child: Column(
                  children: [
                    _ScheduleChip(
                      width: 95,
                      label: day,
                      labelColor: isAvailable
                          ? AppColors.secondaryColor
                          : MaterialHues.grey700,
                      color: isAvailable
                          ? const Color(0x4DB1AFE9)
                          : const Color(0xFFF3F4FB),
                    ),

                    if (isAvailable) ...[
                      const SizedBox(height: 8),
                      _ScheduleChip(
                        width: 95,
                        label: _formatTimeSlot(slot!),
                        labelColor: AppColors.secondaryColor,
                        color: Colors.transparent,
                        isTimeChip: true,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),

        ],
      ),
    );
  }

  Future<void> _showTimePickerDialog(BuildContext context, String day) async {
    final existing = availability[day];

    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => TimeSlotDialog(
        initialSlot: existing,
        openTime: const TimeOfDay(hour: 8, minute: 30),
        closeTime: const TimeOfDay(hour: 15, minute: 30),
      )//TimeSlotDialog(initialSlot: existing),
    );

    if (result is TimeSlot) {
      setState(() => availability[day] = result);
    } else if (existing != null && result == "Remove") {
      setState(() => availability.remove(day));
    }
  }
}


class _ScheduleChip extends StatelessWidget {
  const _ScheduleChip({
    required this.label,
    required this.labelColor,
    required this.color,
    required this.width,
    this.isTimeChip = false,
  });

  final String label;
  final Color labelColor;
  final Color color;
  final double width;
  final bool isTimeChip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: isTimeChip
            ? Border.all(color: const Color(0x4DB1AFE9), width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.body,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: labelColor,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class TimeSlot {
  final TimeOfDay start;
  final TimeOfDay end;
  const TimeSlot({required this.start, required this.end});
}

class TimeSlotDialog extends StatefulWidget {
  final TimeSlot? initialSlot;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;

  const TimeSlotDialog({
    super.key,
    this.initialSlot,
    required this.openTime,
    required this.closeTime,
  });

  @override
  State<TimeSlotDialog> createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<TimeSlotDialog> {
  late TimeOfDay start;
  late TimeOfDay end;

  @override
  void initState() {
    super.initState();
    start = widget.initialSlot?.start ?? widget.openTime;
    end = widget.initialSlot?.end ?? widget.closeTime;

    // Clamp initial values safely
    start = _clampTime(start, widget.openTime, widget.closeTime);
    end = _clampTime(end, widget.openTime, widget.closeTime);

    // Ensure end is after start
    if (!_isAfter(end, start)) {
      end = _addMinutes(start, 60);
      if (!_isAfter(end, start)) end = widget.closeTime;
    }
  }

  // Helper: Convert TimeOfDay to minutes
  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  // Helper: Compare times
  bool _isAfter(TimeOfDay a, TimeOfDay b) => _toMinutes(a) > _toMinutes(b);
  bool _isBefore(TimeOfDay a, TimeOfDay b) => _toMinutes(a) < _toMinutes(b);

  // Helper: Clamp TimeOfDay between min and max
  TimeOfDay _clampTime(TimeOfDay time, TimeOfDay min, TimeOfDay max) {
    final mins = _toMinutes(time);
    final minMins = _toMinutes(min);
    final maxMins = _toMinutes(max);

    if (mins < minMins) return min;
    if (mins > maxMins) return max;
    return time;
  }

  // Helper: Add minutes to TimeOfDay
  TimeOfDay _addMinutes(TimeOfDay t, int minutes) {
    final total = _toMinutes(t) + minutes;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }

  // Format as 12-hour with AM/PM
  String _format12(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }
  // replaced with warning text under the listtiles
  void _showWarningMessage(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.warning, color: MaterialHues.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: MaterialHues.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: MaterialHues.orange50,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: MaterialHues.orange100),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialSlot != null;
    String? startError;
    String? endError;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Shift' : 'Add Shift'),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppColors.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'Allowed: ${_format12(widget.openTime)} – ${_format12(widget.closeTime)}',
                      style: TextStyle(fontSize: 13, color: AppColors.primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('Start Time'),
                    trailing: Text(_format12(start), style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () async {
                      final clampedInitial = _clampTime(start, widget.openTime, widget.closeTime);

                      final picked = await showTimePicker(
                        context: context,
                        initialTime: clampedInitial,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: const Color(0xFF7B7EFB)),
                            ),
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                alwaysUse24HourFormat: true,
                              ),
                              child: child!,
                            ),
                            //child: child!,
                          );
                        },
                      );
                      if (picked == null) return;
                      setDialogState(() {
                        if (_toMinutes(picked) < _toMinutes(widget.openTime)) {
                          startError = 'Cannot be earlier than ${_format12(widget.openTime)}';
                        } else if (!_isBefore(picked, widget.closeTime)) {
                          startError = 'Must be before closing time';
                        } else {
                          startError = null;
                          start = picked;

                          // Auto-adjust end time if it becomes invalid
                          if (!_isAfter(end, start)) {
                            end = _addMinutes(start, 60);
                            if (_toMinutes(end) > _toMinutes(widget.closeTime)) {
                              end = widget.closeTime;
                            }
                            endError = null;
                          }
                        }
                      });



                      // if (_toMinutes(picked) < _toMinutes(widget.openTime)) {
                      //   _showWarningMessage('Start time cannot be earlier than ${_format12(widget.openTime)}');
                      //   return;
                      // }
                      // if (!_isBefore(picked, widget.closeTime)) {
                      //   _showWarningMessage('Start time must be before closing time');
                      //   return;
                      // }

                      // if (!_isBefore(picked, widget.openTime) &&
                      //     _isBefore(picked, widget.closeTime)) {
                      //   setState(() {
                      //     start = picked;
                      //     if (!_isAfter(end, start)) {
                      //       end = _addMinutes(start, 60);
                      //       if (_toMinutes(end) > _toMinutes(widget.closeTime)) {
                      //         end = widget.closeTime;
                      //         _showWarningMessage('End time adjusted to closing time of school.');
                      //       }
                      //     }
                      //   });

                    },
                  ),
                  if (startError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text(
                        startError!,
                        style: const TextStyle(color: MaterialHues.red, fontSize: 12.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16,),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('End Time'),
                    trailing: Text(_format12(end), style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: end,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: const Color(0xFF7B7EFB)),
                            ),
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                alwaysUse24HourFormat: true,
                              ),
                              child: child!,
                            ),
                            //child: child!,
                          );
                        },
                      );

                      if (picked == null) return;
                      setDialogState(() {
                        if (!_isAfter(picked, start)) {
                          endError = 'Must be after start time';
                        } else if (_toMinutes(picked) > _toMinutes(widget.closeTime)) {
                          endError = 'Cannot be later than ${_format12(widget.closeTime)}';
                        } else {
                          endError = null;
                          end = picked;
                        }
                      });

                      // if (!_isAfter(picked, start)) {
                      //   _showWarningMessage('End time must be after start time');
                      //   return;
                      // }
                      // if (_toMinutes(picked) > _toMinutes(widget.closeTime)) {
                      //   _showWarningMessage('End time cannot be later than ${_format12(widget.closeTime)}');
                      //   return;
                      // }
                      //
                      // if (_isAfter(picked, start) &&
                      //     !_isAfter(picked, widget.closeTime)) {
                      //   setState(() => end = picked);
                      // }
                    },
                  ),
                  if (endError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text(
                        endError!,
                        style: const TextStyle(color: MaterialHues.red, fontSize: 12.5),
                      ),
                    ),
                ],
              ),
            ],
          );
        },

      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: () => Navigator.pop(context, 'Remove'),
            child: const Text('Remove'),
          ),
        TextButton(onPressed: () => Navigator.pop(context, 'Cancel'), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isAfter(end, start)
              ? () => Navigator.pop(context, TimeSlot(start: start, end: end))
              : null,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

