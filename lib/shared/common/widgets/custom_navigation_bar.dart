import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/dashboard/view/view/admin_dashboard_screen.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/shared/common/views/coming_soon_screen.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_popup.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';

import '../../../presentation/features/user-profile/view/notification_settings_screen.dart';

// ---------------------------------------------------------------------------
// Responsive sizing — fixed for Bug 3 (iPad split-screen)
// Uses shortestSide to detect a true tablet regardless of split-view width.
// ---------------------------------------------------------------------------
class _NavSizes {
  _NavSizes(BuildContext context) {
    final mq = MediaQuery.of(context);
    const slotCount = 5;
    // shortestSide is always the physical short dimension even in landscape.
    // ≥600 on shortestSide = a genuine tablet, not an iPhone in landscape.
    final shortest = mq.size.shortestSide;
    final isTablet = shortest >= 600;
    final isLargeTablet = shortest >= 900;

    double computedIconSize;
    double computedFontSize;
    double computedItemPaddingH;
    double computedItemPaddingV;
    double computedActiveRadius;

    final baseHorizontalInset = isLargeTablet ? 16.0 : (isTablet ? 12.0 : 6.0);
    final widthPerSlot =
        (mq.size.width - (baseHorizontalInset * 2)) / slotCount;

    if (isLargeTablet) {
      computedIconSize = 30;
      computedFontSize = 13;
      computedItemPaddingH = 16;
      computedItemPaddingV = 12;
      computedActiveRadius = 16;
    } else if (isTablet) {
      computedIconSize = 26;
      computedFontSize = 12;
      computedItemPaddingH = 10;
      computedItemPaddingV = 10;
      computedActiveRadius = 14;
    } else {
      computedIconSize = 22;
      computedFontSize = 10;
      computedItemPaddingH = 4;
      computedItemPaddingV = 6;
      computedActiveRadius = 12;
    }

    // Keep the same design/height intent while adapting for narrow widths.
    if (widthPerSlot < 80) {
      computedItemPaddingH = 2;
      if (!isTablet) {
        computedIconSize = 20;
        computedFontSize = 9;
      }
    } else if (widthPerSlot < 92) {
      computedItemPaddingH = math.min(computedItemPaddingH, 3);
    }

    iconSize = computedIconSize;
    fontSize = computedFontSize;
    itemPaddingH = computedItemPaddingH;
    itemPaddingV = computedItemPaddingV;
    activeRadius = computedActiveRadius;

    // Bug 2 fix — Samsung & all Android gesture-nav:
    // viewPadding is the raw inset before system consumption; it reports the
    // correct bottom inset in every Android navigation mode (gesture, 2-button,
    // 3-button) AND on iOS home-bar devices.
    // DO NOT use mq.padding.bottom — it can be 0 in gesture mode on Samsung.
    final bottomInset = math.max(
      mq.viewPadding.bottom,
      math.max(mq.padding.bottom, mq.systemGestureInsets.bottom),
    );
    barPadding = EdgeInsets.fromLTRB(
      isLargeTablet ? 16 : (isTablet ? 12 : 6),
      isLargeTablet ? 10 : (isTablet ? 8 : 6),
      isLargeTablet ? 16 : (isTablet ? 12 : 6),
      (isLargeTablet ? 10 : (isTablet ? 8 : 6)) + bottomInset,
    );
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

  static double _lastMeasuredHeight = 0.0;

  static double get navBarHeight => _lastMeasuredHeight;

  @override
  _CustomNavigationBarState createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  final GlobalKey _containerKey = GlobalKey();
  double _navBarHeight = 0.0;
  // Bug 4 fix: removed _hasMeasured flag so height re-measures on every
  // layout change (rotation, split-view resize, etc.).
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

  // Bug 4 fix: called from didUpdateWidget + postFrameCallback on every build
  // so height stays accurate after rotation.
  void _measureHeight() {
    if (!mounted) return;
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final newHeight = renderBox.size.height;
      if (newHeight != _navBarHeight) {
        setState(() => _navBarHeight = newHeight);
        CustomNavigationBar._lastMeasuredHeight = newHeight;
      }
    }
  }

  @override
  void didUpdateWidget(covariant CustomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-measure whenever the widget rebuilds (catches orientation changes).
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  int _index = 0;

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
                  color: Colors.black.withValues(alpha: 0.35),
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

  Widget _hiddenNavSlot() => const Expanded(child: SizedBox.shrink());

  @override
  Widget build(BuildContext context) {
    // Bug 4 fix: schedule a re-measure after every build pass.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());

    final roleProvider = context.watch<RoleProvider>();
    final isParent = roleProvider.isParent;

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

    final sizes = _NavSizes(context);

    // Bug 1 fix: SafeArea removed entirely. We handle bottom inset manually
    // via mq.viewPadding.bottom inside _NavSizes.barPadding, which works
    // correctly for BOTH iPhone notch/home-bar AND Android gesture nav.
    // Using SafeArea(bottom:false) + manual padding caused double-inset on
    // some iPhone models because ClipRRect sits inside the SafeArea widget.
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        key: _containerKey,
        padding: sizes.barPadding,
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
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
    );
  }
}
