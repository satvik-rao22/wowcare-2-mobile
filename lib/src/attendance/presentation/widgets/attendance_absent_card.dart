import 'package:flutter/material.dart';
import 'package:wowcare/src/attendance/presentation/widgets/staff_attendance_card.dart';

/// Wrapper around [StaffAttendanceCard] for the Absent tab,
/// so the UI (layout + expand/collapse) is identical.
class AttendanceAbsentCard extends StatelessWidget {
  const AttendanceAbsentCard({
    super.key,
    required this.name,
    required this.classroom,
    required this.absentDays,
    required this.absentDate,
    required this.absentTime,
    required this.markedBy,
    this.onView,
  });

  final String name;
  final String classroom;
  final int absentDays;
  final String absentDate;
  final String absentTime;
  final String markedBy;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    return StaffAttendanceCard(
      name: name,
      designation: 'Staff',
      classroom: classroom,
      photoUuid: '',
      expectedToday: false,
      signInText: '',
      signOutText: '',
      attendedDuration: '',
      isPresentDot: false,
      isAbsentDot: true,
      isAbsentMode: true,
      isCustomMode: false,
      headerSubtitle: 'Absent: $absentDays days',
      roomLabel: classroom,
      absentTime: absentTime,
      startDate: absentDate,
      endDate: absentDate,
      markedBy: markedBy,
      onViewPressed: onView,
      onEdit: () {},
      onDelete: () {},
    );
  }
}

