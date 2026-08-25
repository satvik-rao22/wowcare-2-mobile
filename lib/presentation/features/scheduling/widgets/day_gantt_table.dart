import 'package:flutter/material.dart';

import '../model/scheduling_models.dart';
import 'day_classroom_section.dart';

/// Daily classroom schedule (PRD Use Case 6). Delegates to [DayClassroomSection].
@Deprecated('Use DayClassroomSection with SchedulingViewMode.day instead.')
class DayGanttTable extends StatelessWidget {
  const DayGanttTable({super.key, required this.classrooms, required this.day});

  final List<ClassroomDaySchedule> classrooms;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x33162831)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DailyClassroomScheduleHeader(
              expandAll: true,
              onToggleExpandAll: _noop,
            ),
            for (int i = 0; i < classrooms.length; i++)
              DayClassroomSection(
                classroom: classrooms[i],
                viewMode: SchedulingViewMode.day,
                day: day,
                initiallyExpanded: true,
                isLast: i == classrooms.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  static void _noop() {}
}
