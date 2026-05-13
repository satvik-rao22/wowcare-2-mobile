import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/di/di.dart';
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
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'dart:convert';

class StaffAttendanceTabbedView extends StatefulWidget {
  const StaffAttendanceTabbedView({
    super.key, 
    this.initialTabIndex = 0, 
    this.dailyIncomingFilter,
    this.classroomFilter,
  });

  static const String routeName = '/dashboard/staff-attendance-tabbed-view';

  final int initialTabIndex; // 0: Daily, 1: Custom, 2: Absent
  final String? dailyIncomingFilter; // forwarded to Daily screen
  final FilterData? classroomFilter; // classroom filter data

  @override
  State<StaffAttendanceTabbedView> createState() => _StaffAttendanceTabbedViewState();
}

class _StaffAttendanceTabbedViewState extends State<StaffAttendanceTabbedView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  bool _isParentRole = false;
  bool? _isTeacherStaffPersona;
  String _loggedInStaffCode = '';
  
  // Keys to access the state of each tab
  final GlobalKey _dailyViewKey = GlobalKey();
  final GlobalKey _customViewKey = GlobalKey();
  final GlobalKey _absentViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 2));
    _tabController.addListener(_onTabChanged);
    _initPersonaFlags();
  }

  Future<void> _initPersonaFlags() async {
    _isParentRole = await _resolveIsParentSession();
    if (!_isParentRole) {
      await _loadStaffPersonaFlags();
    } else {
      _isTeacherStaffPersona = false;
      _loggedInStaffCode = '';
    }
    if (mounted) setState(() {});
  }

  Future<bool> _resolveIsParentSession() async {
    if (context.read<RoleProvider>().isParent) return true;
    try {
      final storage = serviceLocator<StorageService>();
      final rolesJson = (await storage.getString(StorageKeys.roles) ?? '').trim();
      if (rolesJson.isNotEmpty) {
        final decoded = jsonDecode(rolesJson);
        if (decoded is List) {
          for (final role in decoded) {
            if (role is! Map) continue;
            final roleName = (role['role'] ?? '').toString().toUpperCase().trim();
            if (roleName.contains('PARENT') || roleName.contains('GUARDIAN')) {
              return true;
            }
          }
        }
      }
      final loginContext = await storage.getJson(StorageKeys.loginContext);
      final raw = jsonEncode(loginContext ?? const <String, dynamic>{}).toUpperCase();
      if (raw.contains('PARENT') || raw.contains('GUARDIAN')) {
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<void> _loadStaffPersonaFlags() async {
    try {
      final storage = serviceLocator<StorageService>();
      var staffCode = (await storage.getString(StorageKeys.staffCode) ?? '').trim();
      if (staffCode.isEmpty) {
        staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
      }
      final staffType =
          (await storage.getString(StorageKeys.staffType) ?? '').trim().toUpperCase();

      bool isStaffAdmin =
          staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN';

      if (!isStaffAdmin) {
        final rolesJson = await storage.getString(StorageKeys.roles);
        if (rolesJson != null && rolesJson.trim().isNotEmpty) {
          final List<dynamic> roles = jsonDecode(rolesJson) as List<dynamic>;
          isStaffAdmin = roles.any((r) {
            if (r is! Map<String, dynamic>) return false;
            final roleCode = (r['role'] ?? '').toString().toUpperCase();
            return roleCode == 'SCHOOL_ADMIN' || roleCode == 'ORGANIZATION_ADMIN';
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _loggedInStaffCode = staffCode;
        _isTeacherStaffPersona = staffCode.isNotEmpty && !isStaffAdmin;
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
            body: SafeArea(
              // Allow the tab contents to respect the device's bottom inset
              // so that the scrollable lists aren't clipped underneath
              // the bottom navigation bar and can scroll naturally.
              bottom: true,
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

  void _refreshDailyAfterAttendanceFlow() {
    final dailyState = _dailyViewKey.currentState;
    if (dailyState == null) return;
    if (dailyState is! DailyAttendanceParentRefresh) return;
    (dailyState as DailyAttendanceParentRefresh)
        .refreshAfterReturningFromAttendanceFlow();
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
      onTap: () => _onStaffActionTap(context, label),
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

  Future<void> _onStaffActionTap(BuildContext context, String label) async {
    Navigator.pop(context);

    if (_isParentRole) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Staff attendance actions are unavailable for parent accounts.'),
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
        photoUuid: display.profilePhotoUrl.isNotEmpty ? display.profilePhotoUrl : null,
        staffCode: display.staffCode.isNotEmpty ? display.staffCode : _loggedInStaffCode,
      );
      if (!mounted) return;
      switch (label) {
        case 'Sign-in':
          Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => StaffSignInForm(staff: staff)),
          ).then((_) {
            if (mounted) _refreshDailyAfterAttendanceFlow();
          });
          break;
        case 'Sign-Out':
          Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => StaffSignOutForm(staff: staff)),
          ).then((_) {
            if (mounted) _refreshDailyAfterAttendanceFlow();
          });
          break;
        case 'Transfer':
          Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => StaffTransferForm(staff: staff)),
          ).then((_) {
            if (mounted) _refreshDailyAfterAttendanceFlow();
          });
          break;
        case 'Absent':
          Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => StaffMarkAbsentForm(staff: staff)),
          ).then((_) {
            if (mounted) _refreshDailyAfterAttendanceFlow();
          });
          break;
      }
      return;
    }

    switch (label) {
      case 'Sign-in':
        Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const StaffSelectionSignInForm()),
        ).then((_) {
          if (mounted) _refreshDailyAfterAttendanceFlow();
        });
        break;
      case 'Sign-Out':
        Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const StaffSelectionSignOutForm()),
        ).then((_) {
          if (mounted) _refreshDailyAfterAttendanceFlow();
        });
        break;
      case 'Transfer':
        Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const StaffSelectionTransferForm()),
        ).then((_) {
          if (mounted) _refreshDailyAfterAttendanceFlow();
        });
        break;
      case 'Absent':
        Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const StaffSelectionMarkAbsentForm()),
        ).then((_) {
          if (mounted) _refreshDailyAfterAttendanceFlow();
        });
        break;
    }
  }
}
