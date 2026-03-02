import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/src/attendance/presentation/views/screens/attendance_daily_view.dart';
import 'package:wowcare/src/attendance/presentation/views/screens/attendance_custom_tab_view.dart';
import 'package:wowcare/src/attendance/presentation/views/screens/attendance_absent_tab_view.dart';
import 'package:wowcare/src/attendance/presentation/widgets/staff_attendance_vertical_popup.dart';

/// High–level container for Attendance screens.
///
/// Mirrors the older SchoolERP `AttendanceTabbedView` layout but uses the
/// new WowCare shared widgets (`GlobalScaffold`) and keeps the logic simple
/// with demo data for now.
class AttendanceTabbedView extends StatelessWidget {
  const AttendanceTabbedView({
    super.key,
    this.initialTabIndex = 0,
  });

  static const String routeName = '/attendance-tabbed-view';

  /// 0: Daily, 1: Custom, 2: Absent
  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return _AttendanceTabbedShell(
      title: 'Attendance',
      initialTabIndex: initialTabIndex,
      isStaff: false,
    );
  }
}

/// Staff attendance tabbed screen that reuses the same
/// common tabbed UI shell as student attendance.
class StaffAttendanceTabbedView extends StatelessWidget {
  const StaffAttendanceTabbedView({
    super.key,
    this.initialTabIndex = 0,
  });

  static const String routeName = '/staff-attendance-tabbed-view';

  /// 0: Daily, 1: Custom, 2: Absent
  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return _AttendanceTabbedShell(
      title: 'Staff Attendance',
      initialTabIndex: initialTabIndex,
      isStaff: true,
    );
  }
}

/// Shared tabbed attendance shell used for both
/// student and staff attendance flows.
class _AttendanceTabbedShell extends StatefulWidget {
  const _AttendanceTabbedShell({
    required this.title,
    required this.initialTabIndex,
    required this.isStaff,
  });

  final String title;
  final int initialTabIndex;
  final bool isStaff;

  @override
  State<_AttendanceTabbedShell> createState() => _AttendanceTabbedShellState();
}

class _AttendanceTabbedShellState extends State<_AttendanceTabbedShell>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: GlobalScaffold(
        hasBackButton: true,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              widget.title,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: TabBar(
                      isScrollable: true,
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(color: AppColors.themeColor),
                      ),
                      indicatorPadding: const EdgeInsets.only(bottom: 8),
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      unselectedLabelStyle: TextStyle(
                        color: AppColors.primaryColor.withOpacity(0.5),
                        fontFamily: 'Manrope',
                        fontSize: 16,
                      ),
                      labelColor: Colors.black,
                      unselectedLabelColor:
                          AppColors.primaryColor.withOpacity(0.5),
                      tabAlignment: TabAlignment.center,
                      tabs: const [
                        Tab(text: 'Daily'),
                        Tab(text: 'Custom'),
                        Tab(text: 'Absent'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GradientAddButton(
                  wantedButtonSize: 40,
                  onTap: () {
                    final topOffset =
                        MediaQuery.of(context).padding.top + 96;
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) {
                        return Stack(
                          children: [
                            Positioned(
                              top: topOffset,
                              right: 16,
                              child: StaffAttendanceVerticalPopupOnly(
                                students: const [],
                                refreshCallback: () {},
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AttendanceDailyViewScreen(isStaff: widget.isStaff),
                  AttendanceCustomTabView(isStaff: widget.isStaff),
                  AttendanceAbsentTabView(isStaff: widget.isStaff),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

