import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';
import 'package:wowcare/src/attendance/presentation/widgets/staff_attendance_card.dart';

class AttendanceDailyViewScreen extends StatefulWidget {
  const AttendanceDailyViewScreen({super.key, required this.isStaff});

  /// When true, renders the staff-style status bars
  /// (Total Staff / Expected Staff). When false,
  /// renders the student-style bars (Enrolled / Expected Students).
  final bool isStaff;

  @override
  State<AttendanceDailyViewScreen> createState() =>
      _AttendanceDailyViewScreenState();
}

class _AttendanceDailyViewScreenState
    extends State<AttendanceDailyViewScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AttendanceStatusBar(isStaff: widget.isStaff),
          const SizedBox(height: 16),
          Expanded(
            child: widget.isStaff
                ? ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      // Demo data for now – replace with real AttendanceDailyModel later.
                      final name = index == 0
                          ? 'Emma Wilson'
                          : index == 1
                              ? 'Liam Johnson'
                              : 'Olivia Brown';
                      final designation = index == 0
                          ? 'Lead Teacher'
                          : index == 1
                              ? 'Assistant Teacher'
                              : 'Support Staff';
                      final classroom =
                          index == 2 ? 'Room C' : (index == 1 ? 'Room B' : 'Room A');

                      final isPresent = index == 0;
                      final isAbsent = index == 2;

                      return StaffAttendanceCard(
                        name: name,
                        designation: designation,
                        classroom: classroom,
                        photoUuid: '',
                        expectedToday: true,
                        signInText:
                            isPresent ? '08:00 AM by Admin' : 'Not signed in',
                        signOutText:
                            isPresent ? '04:30 PM by Admin' : 'Not signed out',
                        attendedDuration:
                            isPresent ? '8 hours 30 minutes' : '-',
                        isPresentDot: isPresent,
                        isAbsentDot: isAbsent,
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      'Daily attendance view will be designed here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Shared status bar widget for attendance daily tabs
class _AttendanceStatusBar extends StatelessWidget {
  const _AttendanceStatusBar({required this.isStaff});

  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    if (isStaff) {
      // Staff-style bars: Total Staff / Expected Staff
      return const Column(
        children: [
          CustomStatBarCard(
            title: 'Total\nStaff',
            number: '24',
            items: [
              ProgressItemHelper(
                label: 'Active (18)',
                value: 18.0,
                color: Color(0xFF9BE8FF),
                filterValue: 'Active',
              ),
              ProgressItemHelper(
                label: 'Upcoming (6)',
                value: 6.0,
                color: Color(0xFFFDCD16),
                filterValue: 'Upcoming',
              ),
            ],
          ),
          SizedBox(height: 16),
          CustomStatBarCard(
            title: 'Expected\nStaff',
            number: '22',
            items: [
              ProgressItemHelper(
                label: 'Present (18)',
                value: 18.0,
                color: Color(0xFFACF3AA),
                filterValue: 'Present',
              ),
              ProgressItemHelper(
                label: 'Absent (4)',
                value: 4.0,
                color: Color(0xFFF38D8D),
                filterValue: 'Absent',
              ),
            ],
          ),
        ],
      );
    }

    // Student-style bars: Enrolled / Expected Students
    return const Column(
      children: [
        CustomStatBarCard(
          title: 'Enrolled\nStudents',
          number: '24',
          items: [
            ProgressItemHelper(
              label: 'Active (18)',
              value: 18.0,
              color: Color(0xFF9BE8FF),
              filterValue: 'Active',
            ),
            ProgressItemHelper(
              label: 'Upcoming (6)',
              value: 6.0,
              color: Color(0xFFFDCD16),
              filterValue: 'Upcoming',
            ),
          ],
        ),
        SizedBox(height: 16),
        CustomStatBarCard(
          title: 'Expected\nStudents',
          number: '22',
          items: [
            ProgressItemHelper(
              label: 'Present (18)',
              value: 18.0,
              color: Color(0xFFACF3AA),
              filterValue: 'Present',
            ),
            ProgressItemHelper(
              label: 'Absent (4)',
              value: 4.0,
              color: Color(0xFFF38D8D),
              filterValue: 'Absent',
            ),
          ],
        ),
      ],
    );
  }
}

