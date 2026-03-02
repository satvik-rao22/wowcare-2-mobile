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
  });

  static const String routeName = '/student-attendance-tabbed-view';

  final int initialTabIndex; // 0: Daily, 1: Custom, 2: Absent
  final String? dailyIncomingFilter; // forwarded to Daily screen
  final FilterData? classroomFilter; // classroom filter data
  final List<String>? staffAllowedClassrooms; // staff's allowed classroom names
  final List<int>? staffAllowedClassroomIds; // staff's allowed classroom IDs

  @override
  State<StudentAttendanceTabbedView> createState() => _StudentAttendanceTabbedViewState();
}

class _StudentAttendanceTabbedViewState extends State<StudentAttendanceTabbedView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  
  // Keys to access the state of each tab
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
    // Base position: vertically centered on the TabBar row,
    // then nudged slightly down and left for better visual balance.
    final double floatingButtonTop =
        safeAreaTop +
        appBarHeight +
        (kTextTabBarHeight - floatingButtonSize) / 2 +
        (isTablet ? 4.0 : 8.0);

    // Start from the main content padding, then push a bit further left
    // so the button does not hug the screen edge.
    final double floatingButtonRight =
        contentPadding.right + (isTablet ? 4.0 : 8.0);
    
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
              hasBackButton: true,
              tabController: _tabController,
              tabBarStyle: TabBarStyle(
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: AppColors.themeColor,
                  ),
                ),
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
              ),
            ),
            extendBody: true,
            bottomNavigationBar: const CustomNavigationBar(),
          ),
        ),
        // Floating button above everything - responsive positioning
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
              refreshCallback: _refreshCurrentTab,
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

  // Refresh the current active tab
  void _refreshCurrentTab() {
    final currentIndex = _tabController.index;
    switch (currentIndex) {
      case 0: // Daily tab
        final dailyState = _dailyViewKey.currentState;
        if (dailyState != null) {
          (dailyState as dynamic)._loadAttendanceData(context, reset: true);
        }
        break;
      case 1: // Custom tab
        final customState = _customViewKey.currentState;
        if (customState != null) {
          (customState as dynamic)._loadAttendanceData(reset: true);
        }
        break;
      case 2: // Absent tab
        final absentState = _absentViewKey.currentState;
        if (absentState != null) {
          (absentState as dynamic)._loadInitialData(reset: true);
        }
        break;
    }
  }
}
