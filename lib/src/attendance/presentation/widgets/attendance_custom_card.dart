import 'package:flutter/material.dart';
import 'package:wowcare/src/attendance/presentation/widgets/staff_attendance_card.dart';

/// Wrapper around [StaffAttendanceCard] for the Custom tab,
/// so the UI (layout + expand/collapse) is identical.
class AttendanceCustomCard extends StatelessWidget {
  const AttendanceCustomCard({
    super.key,
    required this.name,
    required this.classroom,
    required this.attendedDays,
    required this.attendedTime,
    this.onView,
  });

  final String name;
  final String classroom;
  final int attendedDays;
  final String attendedTime;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    return StaffAttendanceCard(
      name: name,
      designation: 'Staff',
      classroom: classroom,
      photoUuid: '',
      expectedToday: true,
      signInText: '',
      signOutText: '',
      attendedDuration: attendedTime,
      isPresentDot: false,
      isAbsentDot: false,
      isAbsentMode: false,
      isCustomMode: true,
      headerSubtitle: 'Attended Days: $attendedDays',
      onViewPressed: onView,
      onEdit: () {},
      onDelete: () {},
    );
  }
}

