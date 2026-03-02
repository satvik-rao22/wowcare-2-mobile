import 'package:flutter/material.dart';
import 'package:wowcare/src/attendance/presentation/widgets/attendance_filter_panel.dart';
import 'package:wowcare/src/attendance/presentation/widgets/attendance_custom_card.dart';

/// Attendance Custom tab content (date-range based filters).
/// Used for both student and staff attendance.
class AttendanceCustomTabView extends StatelessWidget {
  const AttendanceCustomTabView({super.key, required this.isStaff});

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
                    ? 'Demo Test'
                    : index == 1
                        ? 'Demo Staff'
                        : 'Demo User';
                final classroom =
                    index == 2 ? 'class 8-B' : (index == 1 ? 'class 7-A' : 'class 6-A');

                return AttendanceCustomCard(
                  name: name,
                  classroom: classroom,
                  attendedDays: 1,
                  attendedTime: '0 Hrs 0 Mins',
                  onView: () {
                    // TODO: navigate to custom attendance profile
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

