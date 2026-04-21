import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/shared/common/views/coming_soon_screen.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_popup.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';
import 'package:wowcare/presentation/features/user-profile/view/notification_settings_screen.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';

/// Breakpoint helper — call once per build, pass [_NavSizes] around.
class _NavSizes {
  _NavSizes(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final bottomPadding = mq.padding.bottom; // safe-area inset (home bar etc.)

    // Three tiers: phone (<600), tablet (600-900), large tablet (>900)
    if (w >= 900) {
      iconSize = 30;
      fontSize = 13;
      itemPaddingH = 16;
      itemPaddingV = 12;
      barPadding = EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPadding);
      activeRadius = 16;
    } else if (w >= 600) {
      iconSize = 26;
      fontSize = 12;
      itemPaddingH = 10;
      itemPaddingV = 10;
      barPadding = EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomPadding);
      activeRadius = 14;
    } else {
      iconSize = 22;
      fontSize = 10;
      itemPaddingH = 4;
      itemPaddingV = 6;
      barPadding = EdgeInsets.fromLTRB(6, 6, 6, 6 + bottomPadding);
      activeRadius = 12;
    }
  }

  late final double iconSize;
  late final double fontSize;
  late final double itemPaddingH;
  late final double itemPaddingV;
  late final EdgeInsets barPadding;
  late final double activeRadius;
}

class CustomNavigationBar extends StatefulWidget {
  const CustomNavigationBar({super.key});

  static final GlobalKey<_CustomNavigationBarState> navBarKey =
      GlobalKey<_CustomNavigationBarState>();

  static double get navBarHeight =>
      navBarKey.currentState?._navBarHeight ?? 0.0;

  @override
  _CustomNavigationBarState createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  final GlobalKey _containerKey = GlobalKey();
  double _navBarHeight = 0.0;
  bool _hasMeasured = false;
  int _index = 0;
  String _currentRoute = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newRoute = ModalRoute.of(context)?.settings.name ?? '';
    if (newRoute != _currentRoute) {
      setState(() {
        _currentRoute = newRoute;
        _updateIndexFromRoute();
      });
    }
  }

  void _updateIndexFromRoute() {
    if (!mounted) return;
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    final isParent = roleProvider.isParent;

    if (isParent) {
      if (_currentRoute == DashboardScreen.routeName)
        _index = 0;
      else if (_currentRoute == ActivityFeedScreen.routeName)
        _index = 2;
      else if (_currentRoute == MessagingScreen.routeName)
        _index = 3;
      else if (_currentRoute == ParentBillingScreen.routeName)
        _index = 4;
    } else {
      if (_currentRoute == DashboardScreen.routeName)
        _index = 0;
      else if (_currentRoute == ActivityFeedScreen.routeName)
        _index = 3;
      else if (_currentRoute == MessagingScreen.routeName)
        _index = 4;
    }
  }

  void _measureHeight() {
    if (_hasMeasured) return;
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _navBarHeight = renderBox.size.height;
        _hasMeasured = true;
      });
    }
  }

  void _onItemTapped(int index, BuildContext context, bool isParent) {
    setState(() => _index = index);

    if (isParent) {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
          break;
        case 1:
          AttendancePopupManager.showAttendancePopup(context);
          break;
        case 2:
          Navigator.pushReplacementNamed(context, ActivityFeedScreen.routeName);
          break;
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: MessagingScreen.routeName),
              builder: (_) =>
                  const MessagingScreen(userPersona: UserPersona.parent),
            ),
          );
          break;
        case 4:
          Navigator.pushReplacementNamed(
            context,
            ParentBillingScreen.routeName,
          );
          break;
      }
    } else {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
          break;
        case 1:
          AttendancePopupManager.showAttendancePopup(context);
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
          );
          break;
        case 3:
          Navigator.pushReplacementNamed(context, ActivityFeedScreen.routeName);
          break;
        case 4:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: MessagingScreen.routeName),
              builder: (_) =>
                  const MessagingScreen(userPersona: UserPersona.admin),
            ),
          );
          break;
      }
    }
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required int index,
    required BuildContext context,
    required bool isParent,
    required _NavSizes sizes,
  }) {
    final bool isActive = _index == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index, context, isParent),
        borderRadius: BorderRadius.circular(sizes.activeRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: sizes.itemPaddingH,
            vertical: sizes.itemPaddingV,
          ),
          decoration: isActive
              ? BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(sizes.activeRadius),
                )
              : const BoxDecoration(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                icon,
                height: sizes.iconSize,
                colorFilter: isActive
                    ? const ColorFilter.mode(Colors.white, BlendMode.dstIn)
                    : null,
              ),
              const SizedBox(height: 3),
              // FittedBox prevents label overflow on very narrow items
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: Fonts.inter,
                    fontSize: sizes.fontSize,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Invisible placeholder that keeps the flex layout balanced
  /// when a permission-gated tab is hidden.
  Widget _hiddenNavSlot() => const Expanded(child: SizedBox.shrink());

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>();
    final isParent = roleProvider.isParent;

    // Permission flags — unchanged from original
    final showParentAttendance = roleProvider.canOpenModule(
      AppAccessModules.studentAttendance,
    );
    final showStaffAdminAttendance = roleProvider.canAccessAny([
      AppAccessModules.studentAttendance,
      AppAccessModules.staffAttendance,
    ]);
    final showClassrooms = roleProvider.canAccessAny([
      AppAccessModules.classroom,
    ]);
    final showActivities = roleProvider.canReadModule(
      AppAccessModules.dailyActivity,
    );
    final showCommunication = isParent
        ? roleProvider.canAccessAny([
            AppAccessModules.parentMessaging,
            AppAccessModules.newsletter,
          ])
        : roleProvider.canAccessAny([
            AppAccessModules.staffMessaging,
            AppAccessModules.parentMessaging,
            AppAccessModules.newsletter,
          ]);
    final showBilling = roleProvider.canAccessAny([
      AppAccessModules.transaction,
      AppAccessModules.invoices,
      AppAccessModules.recurringPlans,
      AppAccessModules.billingSettings,
    ]);

    // Compute responsive sizes once per build
    final sizes = _NavSizes(context);

    return SafeArea(
      top: false,
      // SafeArea already handles the system bottom inset on most devices,
      // but _NavSizes.barPadding adds it explicitly so we opt out here
      // to avoid double-padding.
      bottom: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          key: _containerKey,
          padding: sizes.barPadding,
          decoration: BoxDecoration(
            gradient: AppColors.buildPrimaryGradient(),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: isParent
                ? [
                    _buildNavItem(
                      icon: MediaRes.dashboardIcon,
                      label: 'Dashboard',
                      index: 0,
                      context: context,
                      isParent: isParent,
                      sizes: sizes,
                    ),
                    showParentAttendance
                        ? _buildNavItem(
                            icon: MediaRes.attendanceIcon,
                            label: 'Attendance',
                            index: 1,
                            context: context,
                            isParent: isParent,
                            sizes: sizes,
                          )
                        : _hiddenNavSlot(),
                    showActivities
                        ? _buildNavItem(
                            icon: MediaRes.activitesIcon,
                            label: 'Activities',
                            index: 2,
                            context: context,
                            isParent: isParent,
                            sizes: sizes,
                          )
                        : _hiddenNavSlot(),
                    showCommunication
                        ? _buildNavItem(
                            icon: MediaRes.communicationIcon,
                            label: 'Communication',
                            index: 3,
                            context: context,
                            isParent: isParent,
                            sizes: sizes,
                          )
                        : _hiddenNavSlot(),
                    showBilling
                        ? _buildNavItem(
                            icon: MediaRes.billing_drawer_icon,
                            label: 'Billing',
                            index: 4,
                            context: context,
                            isParent: isParent,
                            sizes: sizes,
                          )
                        : _hiddenNavSlot(),
                  ]
                : [
                    _buildNavItem(
                      icon: MediaRes.dashboardIcon,
                      label: 'Dashboard',
                      index: 0,
                      context: context,
                      isParent: isParent,
                      sizes: sizes,
                    ),
                    showStaffAdminAttendance
                        ? _buildNavItem(
                            icon: MediaRes.attendanceIcon,
                            label: 'Attendance',
                            index: 1,
                            context: context,
                            isParent: isParent,
                            sizes: sizes,
                          )
                        : _hiddenNavSlot(),
                    showClassrooms
                        ? _buildNavItem(
                            icon: MediaRes.classroomIcon,
                            label: 'Classrooms',
                            index: 2,
                            context: context,
                            isParent: isParent,
                            sizes: sizes,
                          )
                        : _hiddenNavSlot(),
                    showActivities
                        ? _buildNavItem(
                            icon: MediaRes.activitesIcon,
                            label: 'Activities',
                            index: 3,
                            context: context,
                            isParent: isParent,
                            sizes: sizes,
                          )
                        : _hiddenNavSlot(),
                    showCommunication
                        ? _buildNavItem(
                            icon: MediaRes.communicationIcon,
                            label: 'Messages',
                            index: 4,
                            context: context,
                            isParent: isParent,
                            sizes: sizes,
                          )
                        : _hiddenNavSlot(),
                  ],
          ),
        ),
      ),
    );
  }
}
