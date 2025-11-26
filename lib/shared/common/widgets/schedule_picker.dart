
import 'package:flutter/material.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
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
                          ? const Color.fromRGBO(27, 35, 126, 1)
                          : Colors.grey.shade700,
                      color: isAvailable
                          ? const Color(0x4DB1AFE9)
                          : const Color(0xFFF3F4FB),
                    ),

                    if (isAvailable) ...[
                      const SizedBox(height: 8),
                      _ScheduleChip(
                        width: 95,
                        label: _formatTimeSlot(slot!),
                        labelColor: const Color.fromRGBO(27, 35, 126, 1),
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
          fontFamily: 'Manrope',
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialSlot != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Shift' : 'Add Shift'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
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

              if (picked != null &&
                  !_isBefore(picked, widget.openTime) &&
                  _isBefore(picked, widget.closeTime)) {
                setState(() {
                  start = picked;
                  if (!_isAfter(end, start)) {
                    end = _addMinutes(start, 60);
                    if (_toMinutes(end) > _toMinutes(widget.closeTime)) {
                      end = widget.closeTime;
                    }
                  }
                });
              }
            },
          ),

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

              if (picked != null &&
                  _isAfter(picked, start) &&
                  !_isAfter(picked, widget.closeTime)) {
                setState(() => end = picked);
              }
            },
          ),
        ],
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

