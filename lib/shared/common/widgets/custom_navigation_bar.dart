import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_popup.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/shared/common/views/coming_soon_screen.dart';

import '../../../presentation/features/user-profile/view/notification_settings_screen.dart';

// ---------------------------------------------------------------------------
// Device Tier Enum
// ---------------------------------------------------------------------------
enum _DeviceTier {
  /// Compact outer fold screen / very narrow phones (< 360 logical px wide)
  foldOuter,

  /// Standard compact phones: Realme C-series, budget Androids (360–399px)
  compact,

  /// Mid-range phones: Realme GT, Nothing Phone 1/2, most flagships (400–479px)
  standard,

  /// Large phones / inner fold unfolded / phablets (480–599px)
  large,

  /// Small tablets / fold fully open ≥600 shortest side
  tablet,

  /// Large tablets / iPads ≥900 shortest side
  largeTablet,
}

// ---------------------------------------------------------------------------
// _NavSizes — full device-aware sizing
// ---------------------------------------------------------------------------
class _NavSizes {
  _NavSizes(BuildContext context) {
    final mq = MediaQuery.of(context);
    final shortest = mq.size.shortestSide;
    final logicalWidth = mq.size.width;
    final dpr = mq.devicePixelRatio;

    // ---- Detect foldable hinge / display features ----
    final hasFoldHinge = mq.displayFeatures.any(
      (f) =>
          f.type == DisplayFeatureType.fold ||
          f.type == DisplayFeatureType.hinge,
    );

    // ---- Determine tier ----
    if (shortest >= 900) {
      _tier = _DeviceTier.largeTablet;
    } else if (shortest >= 600) {
      _tier = _DeviceTier.tablet;
    } else if (logicalWidth >= 480 || (hasFoldHinge && logicalWidth >= 700)) {
      // Inner fold screen opened wide OR physical phablet
      _tier = _DeviceTier.large;
    } else if (logicalWidth >= 400) {
      _tier = _DeviceTier.standard;
    } else if (logicalWidth >= 360) {
      _tier = _DeviceTier.compact;
    } else {
      // Outer fold screen (Z Fold cover screen ~344–360px)
      _tier = _DeviceTier.foldOuter;
    }

    // ---- Assign sizes by tier ----
    switch (_tier) {
      case _DeviceTier.foldOuter:
        iconSize = 30;
        fontSize = 13;
        itemPaddingH = 16;
        itemPaddingV = 12;
        activeRadius = 16;
        labelMaxWidth = 110.0;
        break;
      case _DeviceTier.compact:
        iconSize = 30;
        fontSize = 13;
        itemPaddingH = 16;
        itemPaddingV = 12;
        activeRadius = 16;
        labelMaxWidth = 110.0;
        break;
      case _DeviceTier.standard:
        iconSize = 30;
        fontSize = 13;
        itemPaddingH = 16;
        itemPaddingV = 12;
        activeRadius = 16;
        labelMaxWidth = 110.0;
        break;
      case _DeviceTier.large:
        iconSize = 30;
        fontSize = 13;
        itemPaddingH = 16;
        itemPaddingV = 12;
        activeRadius = 16;
        labelMaxWidth = 110.0;
        break;
      case _DeviceTier.tablet:
        iconSize = 30;
        fontSize = 13;
        itemPaddingH = 16;
        itemPaddingV = 12;
        activeRadius = 16;
        labelMaxWidth = 110.0;
        break;
      case _DeviceTier.largeTablet:
        iconSize = 30;
        fontSize = 13;
        itemPaddingH = 16;
        itemPaddingV = 12;
        activeRadius = 16;
        labelMaxWidth = 110.0;
        break;
    }

    // ---- Scale icon slightly for very high DPI screens ----
    // Devices like Nothing Phone 2 (dpr ≥ 3.0) on compact bodies
    // can make 22px icons feel tiny at actual physical mm size.
    if (dpr >= 3.5 && _tier == _DeviceTier.compact) {
      iconSize += 2;
    }

    // ---- Bottom inset — robust across all Android nav modes ----
    //
    // viewPadding.bottom = raw OS-reported inset BEFORE Flutter consumes it.
    // This is correct for:
    //   - Samsung gesture nav (viewPadding > 0, padding = 0)
    //   - iOS home indicator
    //   - Android 3-button / 2-button nav
    //   - Nothing OS transparent nav bar
    //   - Realme UI with full-screen gesture
    //
    // We clamp to a max of 60 to guard against erroneous values on some
    // OEM ROMs that report the full screen height as the bottom inset
    // when the activity is in an unusual window mode.
    final rawBottom = mq.viewPadding.bottom.clamp(0.0, 60.0);

    // ---- Side insets — handle curved display / fold asymmetric cutouts ----
    // Nothing Phone curved corners and some Realme side notches add
    // viewPadding on left/right. We respect those too.
    final sideInsetL = mq.viewPadding.left.clamp(0.0, 24.0);
    final sideInsetR = mq.viewPadding.right.clamp(0.0, 24.0);

    final double hPadBase = switch (_tier) {
      _DeviceTier.foldOuter => 4,
      _DeviceTier.compact => 6,
      _DeviceTier.standard => 6,
      _DeviceTier.large => 10,
      _DeviceTier.tablet => 12,
      _DeviceTier.largeTablet => 16,
    };
    final double vPadBase = switch (_tier) {
      _DeviceTier.foldOuter => 8,
      _DeviceTier.compact => 10,
      _DeviceTier.standard => 12,
      _DeviceTier.large => 14,
      _DeviceTier.tablet => 16,
      _DeviceTier.largeTablet => 18,
    };

    barPadding = EdgeInsets.fromLTRB(
      hPadBase + sideInsetL,
      vPadBase,
      hPadBase + sideInsetR,
      vPadBase + rawBottom,
    );

    // ---- Hinge-aware horizontal item padding ----
    // On fold inner screen, reduce item H-padding so 5 items fit without
    // crowding near the hinge.
    if (hasFoldHinge && _tier == _DeviceTier.large) {
      itemPaddingH = (itemPaddingH * 0.6).clamp(2.0, 12.0);
    }
  }

  late _DeviceTier _tier;
  late double iconSize;
  late double fontSize;
  late double itemPaddingH;
  late double itemPaddingV;
  late EdgeInsets barPadding;
  late double activeRadius;
  late double labelMaxWidth;

  bool get isFoldOuter => _tier == _DeviceTier.foldOuter;
  bool get isCompactOrFold =>
      _tier == _DeviceTier.foldOuter || _tier == _DeviceTier.compact;
}

// ---------------------------------------------------------------------------
// CustomNavigationBar
// ---------------------------------------------------------------------------
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
  String _currentRoute = '';
  int _index = 0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

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

  @override
  void didUpdateWidget(covariant CustomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  // ── Height measurement ────────────────────────────────────────────────────

  void _measureHeight() {
    if (!mounted) return;
    final box = _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final h = box.size.height;
      if (h != _navBarHeight) setState(() => _navBarHeight = h);
    }
  }

  // ── Route → index sync ────────────────────────────────────────────────────

  void _updateIndexFromRoute() {
    if (!mounted) return;
    final isParent = Provider.of<RoleProvider>(context, listen: false).isParent;

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

  // ── Tap handler ───────────────────────────────────────────────────────────

  void _onItemTapped(int index, BuildContext context, bool isParent) {
    setState(() => _index = index);

    if (isParent) {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
        case 1:
          AttendancePopupManager.showAttendancePopup(context);
        case 2:
          Navigator.pushReplacementNamed(context, ActivityFeedScreen.routeName);
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: MessagingScreen.routeName),
              builder: (_) =>
                  const MessagingScreen(userPersona: UserPersona.parent),
            ),
          );
        case 4:
          Navigator.pushReplacementNamed(
            context,
            ParentBillingScreen.routeName,
          );
      }
    } else {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
        case 1:
          AttendancePopupManager.showAttendancePopup(context);
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
          );
        case 3:
          Navigator.pushReplacementNamed(context, ActivityFeedScreen.routeName);
        case 4:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: MessagingScreen.routeName),
              builder: (_) =>
                  const MessagingScreen(userPersona: UserPersona.admin),
            ),
          );
      }
    }
  }

  // ── Item builder ──────────────────────────────────────────────────────────

  Widget _buildNavItem({
    required String icon,
    required String label,
    required int index,
    required BuildContext context,
    required bool isParent,
    required _NavSizes sizes,
  }) {
    final bool isActive = _index == index;

    // On fold outer screen the label can be very long ("Communication").
    // We abbreviate if needed so the item never overflows.
    final displayLabel = sizes.isFoldOuter
        ? _abbreviateLabel(label)
        : sizes.isCompactOrFold && label.length > 10
        ? _abbreviateLabel(label)
        : label;

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
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: sizes.labelMaxWidth),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    displayLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: Fonts.inter,
                      fontSize: sizes.fontSize,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abbreviates long labels for tiny screens.
  String _abbreviateLabel(String label) {
    return switch (label) {
      'Dashboard' => 'Home',
      'Attendance' => 'Attend.',
      'Activities' => 'Activity',
      'Communication' => 'Messages',
      'Classrooms' => 'Classes',
      'Billing' => 'Billing',
      'Messages' => 'Chat',
      _ => label.length > 7 ? '${label.substring(0, 6)}.' : label,
    };
  }

  Widget _hiddenNavSlot() => const Expanded(child: SizedBox.shrink());

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Re-measure after every build (rotation, fold/unfold, split resize).
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

    return ClipRRect(
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
    );
  }
}
