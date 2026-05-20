import 'package:flutter/material.dart';
import '../../../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../cubit/classroom-day-view/classroom_day_schedule_state.dart';
import 'legend_widget.dart';
import 'staff_schedule_row.dart';
import 'timeline_header.dart';

class AllClassroomsScheduleCard extends StatefulWidget {
  final List<ClassroomEntity> classrooms;
  final Map<String, List<StaffShiftEntity>> shiftsByClassroom;
  final String? highlightClassroomCode;

  const AllClassroomsScheduleCard({
    super.key,
    required this.classrooms,
    required this.shiftsByClassroom,
    this.highlightClassroomCode,
  });

  @override
  State<AllClassroomsScheduleCard> createState() =>
      _AllClassroomsScheduleCardState();
}

class _AllClassroomsScheduleCardState extends State<AllClassroomsScheduleCard> {
  late final ScrollController _timelineController;
  late final List<String> _timeLabels;

  @override
  void initState() {
    super.initState();
    _timelineController = ScrollController();
    _timeLabels = _buildHourlyLabels(startHour: 6, endHourInclusive: 18);
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  List<String> _buildHourlyLabels({
    required int startHour,
    required int endHourInclusive,
  }) {
    final result = <String>[];
    for (var hour = startHour; hour <= endHourInclusive; hour++) {
      final h12 = ((hour + 11) % 12) + 1;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      result.add('${h12.toString().padLeft(2, '0')}:00 $ampm');
    }
    return result;
  }

  List<Color> _topSummaryColorsForClassroom(List<StaffShiftEntity> shifts) {
    if (shifts.isEmpty) {
      return List<Color>.filled(
        _timeLabels.length,
        Colors.grey.withOpacity(0.18),
        growable: false,
      );
    }

    bool slotInAnyShift(String label) {
      final parts = label.split(' ');
      final time = parts.first;
      final ampm = parts.length > 1 ? parts[1] : 'AM';
      final hm = time.split(':');
      var hour = int.tryParse(hm[0]) ?? 0;
      final minute = int.tryParse(hm.length > 1 ? hm[1] : '0') ?? 0;
      if (ampm.toUpperCase() == 'PM' && hour != 12) hour += 12;
      if (ampm.toUpperCase() == 'AM' && hour == 12) hour = 0;
      final slotMinutes = hour * 60 + minute;

      for (final s in shifts) {
        final st = s.startTime.split(':');
        final et = s.endTime.split(':');
        final sMinutes =
            (int.tryParse(st[0]) ?? 0) * 60 + (int.tryParse(st[1]) ?? 0);
        final eMinutes =
            (int.tryParse(et[0]) ?? 0) * 60 + (int.tryParse(et[1]) ?? 0);
        if (slotMinutes >= sMinutes && slotMinutes <= eMinutes) return true;
      }
      return false;
    }

    return List<Color>.generate(_timeLabels.length, (i) {
      final inAny = slotInAnyShift(_timeLabels[i]);
      return inAny ? const Color(0xFF5B7CFA) : Colors.grey.withOpacity(0.18);
    }, growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final ordered = widget.classrooms.toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (widget.highlightClassroomCode != null &&
        widget.highlightClassroomCode!.trim().isNotEmpty) {
      ordered.sort((a, b) {
        final aIs = a.classroomCode == widget.highlightClassroomCode;
        final bIs = b.classroomCode == widget.highlightClassroomCode;
        if (aIs == bIs) return 0;
        return aIs ? -1 : 1;
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const LegendWidget(),
          const Divider(height: 1),
          ...ordered.map((c) {
            final shifts = widget.shiftsByClassroom[c.classroomCode] ?? const [];
            final colors = _topSummaryColorsForClassroom(shifts);
            return Column(
              children: [
                TimelineHeader(
                  controller: _timelineController,
                  timeLabels: _timeLabels,
                  topSummaryColors: colors,
                  title: c.name.isNotEmpty ? c.name : c.classroomCode,
                ),
                const Divider(height: 1),
                if (shifts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(18.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('No shifts scheduled for this day'),
                    ),
                  )
                else
                  ...shifts.map((shift) {
                    return StaffScheduleRow(
                      shift: shift,
                      controller: _timelineController,
                      timeLabels: _timeLabels,
                    );
                  }),
                const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}

