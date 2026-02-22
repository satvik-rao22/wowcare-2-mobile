import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_drawer.dart';
import 'package:wowcare/shared/common/widgets/custom_navigation_bar.dart';
import 'package:wowcare/shared/common/widgets/gradient_background.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/staff_attendance_daily_view.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/staff_attendance_custom_view.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/staff_attendance_absent_view.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';

class StaffAttendanceTabbedView extends StatefulWidget {
  const StaffAttendanceTabbedView({
    super.key, 
    this.initialTabIndex = 0, 
    this.dailyIncomingFilter,
    this.classroomFilter,
  });

  static const String routeName = '/staff-attendance-tabbed-view';

  final int initialTabIndex; // 0: Daily, 1: Custom, 2: Absent
  final String? dailyIncomingFilter; // forwarded to Daily screen
  final FilterData? classroomFilter; // classroom filter data

  @override
  State<StaffAttendanceTabbedView> createState() => _StaffAttendanceTabbedViewState();
}

class _StaffAttendanceTabbedViewState extends State<StaffAttendanceTabbedView>
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
        // This will rebuild the floating button with the new tab's staff
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
                  padding: ResponsiveSizing.contentPadding(context),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      StaffAttendanceDailyViewScreen(
                        key: _dailyViewKey,
                        incomingFilter: widget.dailyIncomingFilter, 
                        contentOnly: true,
                        classroomFilter: widget.classroomFilter,
                      ),
                      StaffAttendanceCustomView(
                        key: _customViewKey,
                        contentOnly: true,
                      ),
                      StaffAttendanceAbsentView(
                        key: _absentViewKey,
                        contentOnly: true,
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
          child: GradientAddButton(
            onTap: () => _showActionMenu(context),
            isTablet: isTablet,
            isLargeTablet: isLargeTablet,
            wantedButtonSize: floatingButtonSize,
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

  void _showActionMenu(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final contentPadding = ResponsiveSizing.contentPadding(context);
    final safeAreaTop = mediaQuery.padding.top;
    final appBarHeight = AppBar().preferredSize.height;
    final double screenWidth = mediaQuery.size.width;
    final bool isTablet = screenWidth >= 600;
    final bool isLargeTablet = screenWidth >= 900;
    final double floatingButtonSize = isLargeTablet ? 72.0 : (isTablet ? 56.0 : 40.0);
    final floatingButtonTop =
        safeAreaTop + appBarHeight + (kTextTabBarHeight - floatingButtonSize) / 2;
    final floatingButtonRight = contentPadding.right;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.only(
            top: floatingButtonTop + floatingButtonSize + 8,
            bottom: mediaQuery.size.height * 0.45,
            left: mediaQuery.size.width * 0.75,
            right: floatingButtonRight,
          ),
          child: Container(
            width: 50,
            constraints: const BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.classroomStudentTabColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuItem(context, MediaRes.Sign_in, 'Sign-in'),
                const SizedBox(height: 5),
                _buildMenuItem(context, MediaRes.Sign_out, 'Sign-Out'),
                const SizedBox(height: 5),
                _buildMenuItem(context, MediaRes.transfer, 'Transfer'),
                const SizedBox(height: 5),
                _buildMenuItem(context, MediaRes.Mark_absent, 'Absent'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, String svgPath, String label) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(svgPath, height: 24, width: 24),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Manrope',
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
