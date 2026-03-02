import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _showAbsentOnly = false;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveSizing.contentPadding(context),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AttendanceStatusBar(isStaff: widget.isStaff),
                const SizedBox(height: 16),
                // Filter card: search + filter icon + date + clear all + toggle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorderColor),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.cardColor,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomSearchBar(
                              controller: _searchController,
                              hintText: widget.isStaff
                                  ? 'Search Staff'
                                  : 'Search Students',
                              onChanged: (value) {
                                // TODO: wire to real search later
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // TODO: navigate to attendance filter screen
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.cardBorderColor,
                                    width: 1,
                                  ),
                                  color: Colors.white,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: SvgPicture.asset(
                                    MediaRes.filterIcon,
                                    height: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Date + Clear All row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: CustomDateTimeField(
                              label: null,
                              hasLabel: false,
                              isTime: false,
                              isRangePicker: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          CustomClearAllChip(
                            onTap: () {
                              // TODO: clear attendance filters
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Show Absent toggle row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomToggle(
                            label: 'Show Absent',
                            isToggled: _showAbsentOnly,
                            onToggle: (value) {
                              setState(() => _showAbsentOnly = value);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Demo data for now – replace with real AttendanceDailyModel later.
                final bool showAbsent = _showAbsentOnly;

                if (widget.isStaff) {
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

                  if (!showAbsent) {
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
                      onViewPressed: () {
                        // TODO: navigate to staff attendance profile
                      },
                    );
                  } else {
                    // Absent-mode demo data for staff
                    return StaffAttendanceCard(
                      name: name,
                      designation: designation,
                      classroom: classroom,
                      photoUuid: '',
                      expectedToday: false,
                      signInText: '',
                      signOutText: '',
                      attendedDuration: '',
                      isPresentDot: false,
                      isAbsentDot: true,
                      isAbsentMode: true,
                      roomLabel: classroom,
                      absentTime: '09:00 AM',
                      startDate: '2026-03-02',
                      endDate: '2026-03-02',
                      onViewPressed: () {
                        // TODO: navigate to staff attendance profile
                      },
                    );
                  }
                } else {
                  final name = index == 0
                      ? 'Ava Miller'
                      : index == 1
                          ? 'Noah Davis'
                          : 'Sophia Lopez';
                  final classroom =
                      index == 2 ? 'Room C' : (index == 1 ? 'Room B' : 'Room A');

                  if (!showAbsent) {
                    final isPresent = index != 2;
                    final isAbsent = index == 2;

                    return StaffAttendanceCard(
                      name: name,
                      designation: 'Student',
                      classroom: classroom,
                      photoUuid: '',
                      expectedToday: true,
                      signInText:
                          isPresent ? '08:15 AM by Staff' : 'Not signed in',
                      signOutText:
                          isPresent ? '04:45 PM by Staff' : 'Not signed out',
                      attendedDuration:
                          isPresent ? '8 hours 30 minutes' : '-',
                      isPresentDot: isPresent,
                      isAbsentDot: isAbsent,
                      onViewPressed: () {
                        // TODO: navigate to student attendance profile
                      },
                    );
                  } else {
                    // Absent-mode demo data for students
                    return StaffAttendanceCard(
                      name: name,
                      designation: 'Student',
                      classroom: classroom,
                      photoUuid: '',
                      expectedToday: false,
                      signInText: '',
                      signOutText: '',
                      attendedDuration: '',
                      isPresentDot: false,
                      isAbsentDot: true,
                      isAbsentMode: true,
                      roomLabel: classroom,
                      absentTime: '10:00 AM',
                      startDate: '2026-03-02',
                      endDate: '2026-03-02',
                      onViewPressed: () {
                        // TODO: navigate to student attendance profile
                      },
                    );
                  }
                }
              },
              childCount: 3,
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

