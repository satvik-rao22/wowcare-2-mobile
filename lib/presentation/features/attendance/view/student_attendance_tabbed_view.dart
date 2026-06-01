import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_drawer.dart';
import 'package:wowcare/shared/common/widgets/custom_navigation_bar.dart';
import 'package:wowcare/shared/common/widgets/gradient_background.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/attendance/widgets/student_attendance_vertical_pop_up.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/student_attendance_daily_view.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/student_attendance_custom_view.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/student_attendance_absent_view.dart';
import 'package:wowcare/presentation/features/attendance/view/daily_attendance_parent_refresh.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';

class StudentAttendanceTabbedView extends StatefulWidget {
  const StudentAttendanceTabbedView({
    super.key, 
    this.initialTabIndex = 0,
    this.dailyIncomingFilter,
    this.classroomFilter,
    this.staffAllowedClassrooms,
    this.staffAllowedClassroomIds,
    this.highlightCode,
  });

  static const String routeName = '/dashboard/student-attendance-tabbed-view';

  final int initialTabIndex; // 0: Daily, 1: Custom, 2: Absent
  final String? dailyIncomingFilter; // forwarded to Daily screen
  final String? highlightCode; // notification deep-link target studentCode
  final FilterData? classroomFilter; // classroom filter data
  final List<String>? staffAllowedClassrooms; // staff's allowed classroom names
  final List<int>? staffAllowedClassroomIds; // staff's allowed classroom IDs

  @override
  State<StudentAttendanceTabbedView> createState() => _StudentAttendanceTabbedViewState();
}

class _StudentAttendanceTabbedViewState extends State<StudentAttendanceTabbedView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;

  // Hide the floating add button while the drawer is open so it isn't painted
  // on top of (and brighter than) the drawer's dim scrim.
  bool _isDrawerOpen = false;

  // Keys to reach each tab's state so an attendance action can reload all
  // three tabs (Daily, Custom, Absent) — see _refreshAllAfterAttendanceFlow.
  final GlobalKey _dailyViewKey = GlobalKey();
  final GlobalKey _customViewKey = GlobalKey();
  final GlobalKey _absentViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 2));
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        // This will rebuild the floating button with the new tab's students
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final responsive = ResponsiveHelper(context);
    final mediaQuery = MediaQuery.of(context);
    final contentPadding = ResponsiveSizing.contentPadding(context);
    final safeAreaTop = mediaQuery.padding.top;
    final appBarHeight = AppBar().preferredSize.height; // kToolbarHeight

    // Match GradientAddButton responsive sizes (as used in StaffScreen)
    final double screenWidth = mediaQuery.size.width;
    final bool isTablet = screenWidth >= 600;
    final bool isLargeTablet = screenWidth >= 900;
    final double floatingButtonSize = isLargeTablet ? 72.0 : (isTablet ? 56.0 : 40.0);

    // Align the button with the TabBar headings row (Daily/Custom/Absent)
    // by vertically centering it within the TabBar height.
    final floatingButtonTop =
        safeAreaTop + appBarHeight + (kTextTabBarHeight - floatingButtonSize) / 2;
    // Align the floating button horizontally with the main content padding,
    // similar to how GradientAddButton is aligned in StaffScreen.
    final floatingButtonRight = contentPadding.right;
    
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(MediaRes.wowcareMobileBg),
              fit: BoxFit.cover,
            ),
          ),
          child: Scaffold(
            appBar: CustomAppBar(
              hasBackButton: false,
              tabController: _tabController,
              tabBarStyle: TabBarStyle(
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: AppColors.themeColor,
                  ),
                ),
                dividerColor: Colors.transparent,
                indicatorPadding: EdgeInsets.only(
                  bottom: responsive.isTablet ? 10 : 8,
                ),
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                labelStyle: TextStyle(
                  fontFamily: Fonts.manrope,
                  color: Colors.black,
                  fontSize: responsive.isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontFamily: Fonts.manrope,
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  fontSize: responsive.isTablet ? 18 : 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              tabs: const [
                Tab(text: 'Daily'),
                Tab(text: 'Custom'),
                Tab(text: 'Absent'),
              ],
            ),
            drawer: const CustomDrawer(),
            drawerEnableOpenDragGesture: false,
            onDrawerChanged: (isOpen) {
              if (mounted) setState(() => _isDrawerOpen = isOpen);
            },
            body: SafeArea(
              bottom: false,
              child: GradientBackground(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    contentPadding.left,
                    contentPadding.top,
                    contentPadding.right,
                    // Add extra bottom padding so tab content can scroll
                    // fully above the bottom navigation bar.
                    mediaQuery.padding.bottom + 80,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          'Student Attendance',
                          style: TextStyle(
                            fontFamily: Fonts.manrope,
                            fontSize: responsive.isTablet ? 22 : 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            StudentAttendanceDailyViewScreen(
                        key: _dailyViewKey,
                        incomingFilter: widget.dailyIncomingFilter,
                        contentOnly: true,
                        classroomFilter: widget.classroomFilter,
                        staffAllowedClassrooms: widget.staffAllowedClassrooms,
                        staffAllowedClassroomIds: widget.staffAllowedClassroomIds,
                        highlightCode: widget.highlightCode,
                        onAttendanceMutated: _refreshSecondaryTabs,
                      ),
                      StudentAttendanceCustomView(
                        key: _customViewKey,
                        contentOnly: true,
                        staffAllowedClassrooms: widget.staffAllowedClassrooms,
                        staffAllowedClassroomIds: widget.staffAllowedClassroomIds,
                      ),
                      StudentAttendanceAbsentView(
                        key: _absentViewKey,
                        contentOnly: true,
                        staffAllowedClassrooms: widget.staffAllowedClassrooms,
                        staffAllowedClassroomIds: widget.staffAllowedClassroomIds,
                      ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            extendBody: true,
            // Attendance is the bottom-nav slot at index 1 (a popup slot with
            // no branch), so highlight it explicitly while on this view.
            bottomNavigationBar:
                const CustomNavigationBar(activeTabIndexOverride: 1),
          ),
        ),
        // Floating button positioned over the tab bar. Hidden while the drawer
        // is open so it doesn't sit above the drawer's dim scrim.
        if (!_isDrawerOpen)
          Positioned(
            top: floatingButtonTop,
            right: floatingButtonRight,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: StudentAttendanceVerticalPopUp(
                students: const [],
                refreshCallback: _refreshAllAfterAttendanceFlow,
                topPosition: floatingButtonTop,
                rightPosition: floatingButtonRight,
              ),
            ),
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;

  /// Reloads every tab (Daily, Custom, Absent) after any attendance action —
  /// sign-in/out, transfer, mark-absent, edit or delete — so the whole page
  /// (lists + counts) reflects the change, not just the Daily tab.
  ///
  /// The Daily tab reloads itself and cascades to the secondary tabs via its
  /// onAttendanceMutated callback, so refreshing Daily refreshes everything.
  /// If Daily isn't currently mounted (the user is on a far tab), it will
  /// reload on its own when revisited, so we just refresh the secondary tabs.
  void _refreshAllAfterAttendanceFlow() {
    final daily = _dailyViewKey.currentState;
    if (daily is AttendanceTabRefresh) {
      (daily as AttendanceTabRefresh).refreshAfterReturningFromAttendanceFlow();
    } else {
      _refreshSecondaryTabs();
    }
  }

  /// Reloads just the Custom and Absent tabs (skipping any not currently
  /// mounted — they reload themselves when revisited).
  void _refreshSecondaryTabs() {
    _refreshTab(_customViewKey);
    _refreshTab(_absentViewKey);
  }

  void _refreshTab(GlobalKey key) {
    final state = key.currentState;
    if (state is AttendanceTabRefresh) {
      (state as AttendanceTabRefresh).refreshAfterReturningFromAttendanceFlow();
    }
  }
}
