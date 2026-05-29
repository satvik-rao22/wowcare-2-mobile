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
// Responsive sizing — fixed for Bug 3 (iPad split-screen)
// Uses shortestSide to detect a true tablet regardless of split-view width.
// ---------------------------------------------------------------------------
class _NavSizes {
  _NavSizes(BuildContext context) {
    final mq = MediaQuery.of(context);
    // shortestSide is always the physical short dimension even in landscape.
    // ≥600 on shortestSide = a genuine tablet, not an iPhone in landscape.
    final shortest = mq.size.shortestSide;
    final isTablet = shortest >= 600;
    final isLargeTablet = shortest >= 900;

    if (isLargeTablet) {
      iconSize = 30;
      fontSize = 13;
      itemPaddingH = 16;
      itemPaddingV = 12;
      activeRadius = 16;
    } else if (isTablet) {
      iconSize = 26;
      fontSize = 12;
      itemPaddingH = 10;
      itemPaddingV = 10;
      activeRadius = 14;
    } else {
      iconSize = 22;
      fontSize = 10;
      itemPaddingH = 4;
      itemPaddingV = 6;
      activeRadius = 12;
    }

    // Bug 2 fix — Samsung & all Android gesture-nav:
    // viewPadding is the raw inset before system consumption; it reports the
    // correct bottom inset in every Android navigation mode (gesture, 2-button,
    // 3-button) AND on iOS home-bar devices.
    // DO NOT use mq.padding.bottom — it can be 0 in gesture mode on Samsung.
    final bottomInset = mq.viewPadding.bottom;
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
      if (branchIndex == shell.currentIndex) {
        // Already on this branch. If the user is on a sub-route (e.g.
        // /dashboard/student-attendance-tabbed-view), navigate back to the
        // branch root so they return to the dashboard. If already at the
        // branch root, context.canPop() is false and we do nothing —
        // preserving the user's scroll position and state.
        if (context.canPop()) {
          context.go(branchRootPaths[branchIndex]);
        }
        return;
      }
      // Different branch → IndexedStack swap; state of the outgoing branch is
      // kept alive, the incoming one shows instantly (no transition animation).
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
    final activeTabIndex = widget.activeTabIndexOverride ??
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
