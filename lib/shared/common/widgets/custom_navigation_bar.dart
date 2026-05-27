import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_popup.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/src/app_router.dart';

// ---------------------------------------------------------------------------
// Responsive sizing — compact-first, breakpoint-based.
//
// shortestSide is used intentionally: it reflects the physical short edge of
// the device regardless of orientation or split-view width, so a tablet in
// landscape or split-screen is still detected as a tablet, not a phone.
//
// Breakpoints (shortestSide):
//   < 360  → small phone  (e.g. Galaxy A01, iPhone SE 1st-gen)
//   360–599→ normal phone (most Android flagships, iPhone 14 Pro etc.)
//   600–899→ tablet       (iPad Mini, small Android tablets)
//   ≥ 900  → large tablet (iPad Pro 11", iPad Air 13", large Android tablets)
//
// Sizing philosophy: the phone tier is the visual baseline. Tablets scale up
// SLIGHTLY — never dramatically — so the navbar stays compact on every device.
// ---------------------------------------------------------------------------
class _NavSizes {
  _NavSizes(BuildContext context) {
    final mq = MediaQuery.of(context);
    final shortest = mq.size.shortestSide;

    // Tier flags — mutually exclusive, evaluated top-down.
    final isSmallPhone = shortest < 360;
    final isTablet = shortest >= 600 && shortest < 900;
    final isLargeTablet = shortest >= 900;
    // isNormalPhone = everything else (360 ≤ shortest < 600)

    if (isLargeTablet) {
      iconSize = 28;
      fontSize = 12.5;
      itemPaddingH = 12;
      itemPaddingV = 12;
      activeRadius = 16;
      iconTextGap = 4;
    } else if (isTablet) {
      iconSize = 26;
      fontSize = 11.5;
      itemPaddingH = 10;
      itemPaddingV = 11;
      activeRadius = 14;
      iconTextGap = 4;
    } else if (isSmallPhone) {
      iconSize = 22;
      fontSize = 10;
      itemPaddingH = 4;
      itemPaddingV = 9;
      activeRadius = 11;
      iconTextGap = 3;
    } else {
      // Normal phone baseline.
      iconSize = 24;
      fontSize = 11;
      itemPaddingH = 6;
      itemPaddingV = 10;
      activeRadius = 13;
      iconTextGap = 4;
    }

    final rawBottom = mq.viewPadding.bottom;
    final safeBottom = rawBottom.clamp(0.0, 36.0);

    final double vPad = isLargeTablet
        ? 12
        : (isTablet ? 10 : (isSmallPhone ? 8 : 9));
    final double hPad = isLargeTablet
        ? 12
        : (isTablet ? 10 : (isSmallPhone ? 4 : 6));

    barPadding = EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad + safeBottom);
  }

  late final double iconSize;
  late final double fontSize;
  late final double itemPaddingH;
  late final double itemPaddingV;
  late final EdgeInsets barPadding;
  late final double activeRadius;

  /// Vertical gap between icon and label — scales with tier.
  late final double iconTextGap;
}

class CustomNavigationBar extends StatefulWidget {
  const CustomNavigationBar({super.key, this.activeTabIndexOverride});

  /// Forces a specific bottom-nav slot to render highlighted, regardless of
  /// the shell's current branch. Used by screens that live under another
  /// branch's route but conceptually belong to a non-branch slot — e.g. the
  /// attendance tabbed views (Attendance is a popup slot, index 1, and the
  /// views are registered under the dashboard branch).
  final int? activeTabIndexOverride;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  // Bug 4 fix: re-measure after every build pass so the height stays accurate
  // through rotations and split-view resizes.
  void _measureHeight() {
    if (!mounted) return;
    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final newHeight = renderBox.size.height;
      if (newHeight != _navBarHeight) {
        setState(() => _navBarHeight = newHeight);
      }
    }
  }

  @override
  void didUpdateWidget(covariant CustomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  void _onItemTapped(int tabIndex, BuildContext context, bool isParent) {
    // The Attendance slot (index 1) is a modal popup, not a route.
    if (tabIndex == 1) {
      AttendancePopupManager.showAttendancePopup(context);
      return;
    }

    final branchIndex = navBranchIndexForTab(
      isParent: isParent,
      tabIndex: tabIndex,
    );
    if (branchIndex == null) return;

    final shell = appNavigationShell(context);
    if (shell != null) {
      // Re-tap on the active tab is a no-op so the user's place inside the
      // branch is preserved. Different branch → IndexedStack swap; state of
      // the outgoing branch is kept alive, the incoming one shows instantly
      // (no transition animation, no rebuild of the bottom bar).
      if (branchIndex == shell.currentIndex) return;
      shell.goBranch(branchIndex);
    } else {
      // Outside the shell (e.g. on an auth screen that still shows the bar):
      // route-level go so we enter the shell at the tab root.
      context.go(branchRootPaths[branchIndex]);
    }
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required int index,
    required int activeTabIndex,
    required BuildContext context,
    required bool isParent,
    required _NavSizes sizes,
  }) {
    final bool isActive = activeTabIndex == index;

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
                  color: Colors.black.withValues(alpha: .35),
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
              SizedBox(height: sizes.iconTextGap),
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

    // Highlight comes from the shell's current branch; falls back to 0
    // when the bar renders outside the shell (e.g. on an auth screen).
    final shell = appNavigationShell(context);
    final activeTabIndex =
        widget.activeTabIndexOverride ??
        (shell == null
            ? 0
            : tabIndexForBranchIndex(
                isParent: isParent,
                branchIndex: shell.currentIndex,
              ));

    Widget item({
      required String icon,
      required String label,
      required int index,
    }) {
      return _buildNavItem(
        icon: icon,
        label: label,
        index: index,
        activeTabIndex: activeTabIndex,
        context: context,
        isParent: isParent,
        sizes: sizes,
      );
    }

    // Bug 1 fix: SafeArea removed entirely. We handle bottom inset manually
    // via mq.viewPadding.bottom inside _NavSizes.barPadding, which works
    // correctly for BOTH iPhone notch/home-bar AND Android gesture nav.
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
                  item(
                    icon: MediaRes.dashboardIcon,
                    label: 'Dashboard',
                    index: 0,
                  ),
                  showParentAttendance
                      ? item(
                          icon: MediaRes.attendanceIcon,
                          label: 'Attendance',
                          index: 1,
                        )
                      : _hiddenNavSlot(),
                  showActivities
                      ? item(
                          icon: MediaRes.activitesIcon,
                          label: 'Activities',
                          index: 2,
                        )
                      : _hiddenNavSlot(),
                  showCommunication
                      ? item(
                          icon: MediaRes.communicationIcon,
                          label: 'Communication',
                          index: 3,
                        )
                      : _hiddenNavSlot(),
                  showBilling
                      ? item(
                          icon: MediaRes.billing_drawer_icon,
                          label: 'Billing',
                          index: 4,
                        )
                      : _hiddenNavSlot(),
                ]
              : [
                  item(
                    icon: MediaRes.dashboardIcon,
                    label: 'Dashboard',
                    index: 0,
                  ),
                  showStaffAdminAttendance
                      ? item(
                          icon: MediaRes.attendanceIcon,
                          label: 'Attendance',
                          index: 1,
                        )
                      : _hiddenNavSlot(),
                  showClassrooms
                      ? item(
                          icon: MediaRes.classroomIcon,
                          label: 'Classrooms',
                          index: 2,
                        )
                      : _hiddenNavSlot(),
                  showActivities
                      ? item(
                          icon: MediaRes.activitesIcon,
                          label: 'Activities',
                          index: 3,
                        )
                      : _hiddenNavSlot(),
                  showCommunication
                      ? item(
                          icon: MediaRes.communicationIcon,
                          label: 'Messages',
                          index: 4,
                        )
                      : _hiddenNavSlot(),
                ],
        ),
      ),
    );
  }
}
