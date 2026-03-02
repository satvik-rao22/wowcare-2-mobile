import 'package:flutter/material.dart';
import 'package:wowcare/src/attendance/presentation/widgets/attendance_filter_panel.dart';
import 'package:wowcare/src/attendance/presentation/widgets/attendance_absent_card.dart';

/// Attendance Absent tab content.
/// Uses the same filter panel as the Custom tab.
class AttendanceAbsentTabView extends StatelessWidget {
  const AttendanceAbsentTabView({super.key, required this.isStaff});

  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AttendanceFilterPanel(isStaff: isStaff),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                final name = index == 0
                    ? 'DemoParent Staff'
                    : index == 1
                        ? 'Demo Staff'
                        : 'Demo User';
                final classroom =
                    index == 2 ? 'Classroom 3' : (index == 1 ? 'Classroom 2' : 'Classroom 1');

                return AttendanceAbsentCard(
                  name: name,
                  classroom: classroom,
                  absentDays: 1,
                  absentDate: 'Mar 02, 2026',
                  absentTime: '09:00 AM',
                  markedBy: 'Admin',
                  onView: () {
                    // TODO: navigate to absent attendance profile
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

