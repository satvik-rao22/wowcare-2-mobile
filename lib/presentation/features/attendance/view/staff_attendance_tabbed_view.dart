import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_permission_service.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_drawer.dart';
import 'package:wowcare/shared/common/widgets/custom_navigation_bar.dart';
import 'package:wowcare/shared/common/widgets/gradient_background.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/staff_attendance_daily_view.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/staff_attendance_custom_view.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/staff_attendance_absent_view.dart';
import 'package:wowcare/presentation/features/attendance/view/daily_attendance_parent_refresh.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_entity.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/shared/common/app/cubit/bottom_navigation_item.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/core_utils.dart';

class StaffAttendanceTabbedView extends StatefulWidget {
  const StaffAttendanceTabbedView({
    super.key,
    this.initialTabIndex = 0,
    this.dailyIncomingFilter,
    this.classroomFilter,
    this.hasBackButton = false,
  });

  static const String routeName = '/dashboard/staff-attendance-tabbed-view';

  final int initialTabIndex; // 0: Daily, 1: Custom, 2: Absent
  final String? dailyIncomingFilter; // forwarded to Daily screen
  final FilterData? classroomFilter; // classroom filter data
  final bool hasBackButton;

  @override
  State<StaffAttendanceTabbedView> createState() =>
      _StaffAttendanceTabbedViewState();
}

class _StaffAttendanceTabbedViewState extends State<StaffAttendanceTabbedView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final UnreadBadgeCubit _unreadBadgeCubit;
  late final TabController _tabController;
  bool _isParentRole = false;
  bool? _isTeacherStaffPersona;
  String _loggedInStaffCode = '';
  // Hide the floating add button while the drawer is open so it isn't painted
  // on top of (and brighter than) the drawer's dim scrim.
  bool _isDrawerOpen = false;

  // Show/hide the bottom nav bar on scroll, mirroring GlobalScaffold (this view
  // uses its own Scaffold for the tabbed app bar, so it replicates that here).
  bool _showBars = true;

  /// Hide the bottom nav while scrolling down (reverse), reveal it scrolling up.
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.metrics.axis == Axis.vertical) {
      final direction = notification.direction;
      if (direction == ScrollDirection.reverse && _showBars) {
        setState(() => _showBars = false);
      } else if (direction == ScrollDirection.forward && !_showBars) {
        setState(() => _showBars = true);
      }
    }
    return false;
  }

  // Keys to reach each tab's state so an attendance action can reload all
  // three tabs (Daily, Custom, Absent) — see _refreshAllAfterAttendanceFlow.
  final GlobalKey _dailyViewKey = GlobalKey();
  final GlobalKey _customViewKey = GlobalKey();
  final GlobalKey _absentViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Shared app-session singleton (registered in di.dart) — `startWatching`
    // is idempotent, so re-calling it here on mount keeps badges fresh
    // without opening a second, duplicate set of Firestore listeners.
    _unreadBadgeCubit = serviceLocator<UnreadBadgeCubit>()..startWatching();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _tabController.addListener(_onTabChanged);
    _initPersonaFlags();
  }

  Future<void> _initPersonaFlags() async {
    _isParentRole = await AttendancePermissionService.resolveIsParentSession(
      context,
    );
    if (!_isParentRole) {
      await _loadStaffPersonaFlags();
    } else {
      _isTeacherStaffPersona = false;
      _loggedInStaffCode = '';
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadStaffPersonaFlags() async {
    try {
      // Roles are per-school (a user can be SCHOOL_ADMIN in one school and STAFF
      // in another), so scanning the global login roles/staffType mis-detects
      // the persona. RoleCubit resolves the ACTIVE school's role, so key off it:
      // only the staff (teacher) persona gets the self-scoped view; the admin
      // persona manages all staff. staffCode is still loaded for self-scoping.
      final isStaffPersona = context.read<RoleCubit>().isStaff;

      final storage = serviceLocator<StorageService>();
      var staffCode = (await storage.getString(StorageKeys.staffCode) ?? '')
          .trim();
      if (staffCode.isEmpty) {
        staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
      }

      if (!mounted) return;
      setState(() {
        _loggedInStaffCode = staffCode;
        _isTeacherStaffPersona = isStaffPersona && staffCode.isNotEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loggedInStaffCode = '';
        _isTeacherStaffPersona = false;
      });
    }
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
    // Do NOT close _unreadBadgeCubit: it is a shared app-session singleton
    // (registered in di.dart), not owned by this widget.
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
    final bool isTablet = ResponsiveHelper(context).isTabletCompact;
    final bool isLargeTablet = ResponsiveHelper(context).isWide;
    final double floatingButtonSize = isLargeTablet
        ? 72.0
        : (isTablet ? 56.0 : 40.0);

    // Align the button with the TabBar headings row (Daily/Custom/Absent)
    // by vertically centering it within the TabBar height.
    final floatingButtonTop =
        safeAreaTop +
        appBarHeight +
        (kTextTabBarHeight - floatingButtonSize) / 2;
    // Align the floating button horizontally with the main content padding,
    // similar to how GradientAddButton is aligned in StaffScreen.
    final floatingButtonRight = contentPadding.right;

    return BlocProvider<UnreadBadgeCubit>.value(
      value: _unreadBadgeCubit,
      child: Stack(
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
                hasBackButton: widget.hasBackButton,
                tabController: _tabController,
                tabBarStyle: TabBarStyle(
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(color: AppColors.themeColor),
                  ),
                  dividerColor: Colors.transparent,
                  indicatorPadding: EdgeInsets.only(
                    bottom: responsive.isTablet ? 10 : 8,
                  ),
                  tabAlignment: TabAlignment.start,
                  isScrollable: true,
                  labelStyle: TextStyle(
                    fontFamily: Fonts.manrope,
                    color: AppColors.attendanceIconColor,
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
              body: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: SafeArea(
                  // Allow the tab contents to respect the device's bottom inset
                  // so that the scrollable lists aren't clipped underneath
                  // the bottom navigation bar and can scroll naturally.
                  bottom: true,
                  child: GradientBackground(
                    child: Padding(
                      padding: ResponsiveSizing.contentPadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.xxs,
                              bottom: AppSpacing.xs,
                            ),
                            child: Text(
                              'Staff Attendance',
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
                                StaffAttendanceDailyViewScreen(
                                  key: _dailyViewKey,
                                  incomingFilter: widget.dailyIncomingFilter,
                                  contentOnly: true,
                                  classroomFilter: widget.classroomFilter,
                                  onAttendanceMutated: _refreshSecondaryTabs,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              extendBody: true,
              // Attendance is the bottom-nav slot at index 1 (a popup slot with
              // no branch), so highlight it explicitly while on this view.
              // Animate the bar away while scrolling down, like GlobalScaffold.
              bottomNavigationBar: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _showBars
                    ? const CustomNavigationBar(
                        activeItemOverride: BottomNavigationItem.attendance,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          // Floating button positioned over the tab bar. Hidden while the drawer
          // is open so it doesn't sit above the drawer's dim scrim.
          if (!_isDrawerOpen)
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
      ),
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

  void _showActionMenu(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final contentPadding = ResponsiveSizing.contentPadding(context);
    final safeAreaTop = mediaQuery.padding.top;
    final appBarHeight = AppBar().preferredSize.height;
    final bool isTablet = ResponsiveHelper(context).isTabletCompact;
    final bool isLargeTablet = ResponsiveHelper(context).isWide;
    final double floatingButtonSize = isLargeTablet
        ? 72.0
        : (isTablet ? 56.0 : 40.0);
    final floatingButtonTop =
        safeAreaTop +
        appBarHeight +
        (kTextTabBarHeight - floatingButtonSize) / 2;
    final floatingButtonRight = contentPadding.right;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Pin to the top-right so the menu sits flush below the + button
          // instead of being vertically centered in the inset band.
          alignment: Alignment.topRight,
          insetPadding: EdgeInsets.only(
            top: floatingButtonTop + floatingButtonSize,
            left: ResponsiveHelper(context).screenWidth * 0.75,
            right: floatingButtonRight,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s2),
            decoration: BoxDecoration(
              borderRadius: AppRadius.allMd,
              gradient: AppColors.buildPrimaryGradient(),
              boxShadow: [
                BoxShadow(
                  color: AppColors.attendanceCardShadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              width: 50,
              constraints: const BoxConstraints(maxHeight: 400),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.r10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMenuItem(context, MediaRes.Sign_in, 'Sign-in'),
                  const SizedBox(height: AppSpacing.s5),
                  _buildMenuItem(context, MediaRes.Sign_out, 'Sign-Out'),
                  const SizedBox(height: AppSpacing.s5),
                  if (!(_isTeacherStaffPersona ?? false))
                    _buildMenuItem(context, MediaRes.transfer, 'Transfer'),
                  if (!(_isTeacherStaffPersona ?? false))
                    const SizedBox(height: AppSpacing.s5),
                  _buildMenuItem(context, MediaRes.Mark_absent, 'Absent'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, String svgPath, String label) {
    return InkWell(
      onTap: () => _onStaffActionTap(context, label),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
            decoration: BoxDecoration(
              color: AppColors.attendanceInfoHighlightColor,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(svgPath, height: 24, width: 24),
          ),
          const SizedBox(height: AppSpacing.s5),
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

  Future<void> _onStaffActionTap(BuildContext context, String label) async {
    Navigator.pop(context);

    if (_isParentRole) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text(
            'Staff attendance actions are unavailable for parent accounts.',
          ),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    if (_isTeacherStaffPersona == true && _loggedInStaffCode.isNotEmpty) {
      final display = await resolveLoggedInStaffDisplay();
      final staff = StaffEntity(
        id: 0,
        name: display.fullName.isNotEmpty ? display.fullName : 'My Attendance',
        primaryRoomId: 0,
        photoUuid: display.profilePhotoUrl.isNotEmpty
            ? display.profilePhotoUrl
            : null,
        staffCode: display.staffCode.isNotEmpty
            ? display.staffCode
            : _loggedInStaffCode,
      );
      if (!mounted) return;
      switch (label) {
        case 'Sign-in':
          context
              .push('/attendance/staff-sign-in', extra: {'staff': staff})
              .then((_) {
                if (mounted) _refreshAllAfterAttendanceFlow();
              });
          break;
        case 'Sign-Out':
          context
              .push('/attendance/staff-sign-out', extra: {'staff': staff})
              .then((_) {
                if (mounted) _refreshAllAfterAttendanceFlow();
              });
          break;
        case 'Transfer':
          context
              .push('/attendance/staff-transfer', extra: {'staff': staff})
              .then((_) {
                if (mounted) _refreshAllAfterAttendanceFlow();
              });
          break;
        case 'Absent':
          context
              .push('/attendance/staff-mark-absent', extra: {'staff': staff})
              .then((_) {
                if (mounted) _refreshAllAfterAttendanceFlow();
              });
          break;
      }
      return;
    }

    switch (label) {
      case 'Sign-in':
        context.push('/attendance/staff-selection-sign-in').then((_) {
          if (mounted) _refreshAllAfterAttendanceFlow();
        });
        break;
      case 'Sign-Out':
        context.push('/attendance/staff-selection-sign-out').then((_) {
          if (mounted) _refreshAllAfterAttendanceFlow();
        });
        break;
      case 'Transfer':
        context.push('/attendance/staff-selection-transfer').then((_) {
          if (mounted) _refreshAllAfterAttendanceFlow();
        });
        break;
      case 'Absent':
        context.push('/attendance/staff-selection-mark-absent').then((_) {
          if (mounted) _refreshAllAfterAttendanceFlow();
        });
        break;
    }
  }
}
