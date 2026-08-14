import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_popup.dart';
import 'package:wowcare/shared/common/app/cubit/bottom_navigation_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/bottom_navigation_item.dart';
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

/// Fixed on-screen slot order per persona — kept as 5 equal-width columns
/// (hidden slots render as an empty [Expanded] rather than being omitted) so
/// the layout never reflows when a module-access gate hides an item.
const List<BottomNavigationItem> _parentSlotOrder = <BottomNavigationItem>[
  BottomNavigationItem.dashboard,
  BottomNavigationItem.attendance,
  BottomNavigationItem.activities,
  BottomNavigationItem.communication,
  BottomNavigationItem.billing,
];

const List<BottomNavigationItem> _staffAdminSlotOrder = <BottomNavigationItem>[
  BottomNavigationItem.dashboard,
  BottomNavigationItem.attendance,
  BottomNavigationItem.classrooms,
  BottomNavigationItem.activities,
  BottomNavigationItem.communication,
];

class CustomNavigationBar extends StatefulWidget {
  const CustomNavigationBar({
    super.key,
    this.activeItemOverride,
    this.highlightNone = false,
  });

  /// Forces a specific bottom-nav slot to render highlighted, regardless of
  /// the shell's current branch. Used by screens that live under another
  /// branch's route but conceptually belong to a non-branch slot — e.g. the
  /// attendance tabbed views (Attendance is a popup slot, and the views are
  /// registered under the dashboard branch).
  final BottomNavigationItem? activeItemOverride;

  /// Forces nothing to render highlighted (e.g. the notification center,
  /// which is a top-level overlay route outside the shell).
  final bool highlightNone;

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
  GoRouteInformationProvider? _routeInfoProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the route-information provider so the highlighted item
    // stays in sync with go_router even when it changes for reasons other
    // than a tap here (back navigation, deep links, the Attendance popup's
    // forced branch switch for parents).
    final provider = GoRouter.of(context).routeInformationProvider;
    if (provider != _routeInfoProvider) {
      _routeInfoProvider?.removeListener(_onRouteChanged);
      _routeInfoProvider = provider;
      _routeInfoProvider!.addListener(_onRouteChanged);
    }
    // Seed the cubit's selectedItem synchronously (before this frame's
    // build() reads it), so the very first render is correct without
    // waiting for a route-change event.
    _syncSelectedItemFromRoute();
  }

  void _onRouteChanged() {
    if (!mounted) return;
    _syncSelectedItemFromRoute();
  }

  /// The full active route path (e.g. `/dashboard/billing`), read from the
  /// router's current configuration so it is independent of where in the
  /// widget tree this bar is mounted. Empty string if the router can't be
  /// resolved (e.g. transiently during teardown).
  String _currentLocationPath(BuildContext context) {
    try {
      return GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    } catch (_) {
      return '';
    }
  }

  /// Derives the highlighted item purely from go_router's current state and
  /// pushes it into [BottomNavigationCubit] — the cubit never touches
  /// go_router itself (MVVM golden rule), so this is the one place that
  /// bridges the two.
  void _syncSelectedItemFromRoute() {
    final cubit = context.read<BottomNavigationCubit>();
    final isParent = cubit.state.isParent;
    final shell = appNavigationShell(context);

    final BottomNavigationItem? item;
    if (shell == null) {
      item = BottomNavigationItem.dashboard;
    } else if (shell.currentIndex == 0) {
      // Branch 0 (the Dashboard branch) also hosts every non-tab drill-down
      // (Billing, Scheduling, Staff, Reports, …). Those screens are NOT
      // bottom-nav tabs, so only the dashboard ROOT should light up the
      // Dashboard slot — on any drill-down we highlight nothing instead of
      // falsely marking Dashboard as active.
      final path = _currentLocationPath(context);
      item = path == AppRoutes.dashboard
          ? BottomNavigationItem.dashboard
          : null;
    } else {
      item = itemForBranchIndex(
        isParent: isParent,
        branchIndex: shell.currentIndex,
      );
    }
    cubit.syncFromRoute(item);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  @override
  void dispose() {
    _routeInfoProvider?.removeListener(_onRouteChanged);
    super.dispose();
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

  /// Performs the actual go_router transition for [item]. This is the View
  /// layer's responsibility (a Cubit must not hold a BuildContext) — invoked
  /// by the `BlocListener` below whenever `BottomNavigationCubit.selectItem`
  /// records a new navigation intent.
  void _performNavigation(
    BuildContext context,
    bool isParent,
    BottomNavigationItem item,
  ) {
    // The Attendance slot is a modal popup, not a route.
    if (item == BottomNavigationItem.attendance) {
      if (isParent) {
        final shell = appNavigationShell(context);
        if (shell != null && shell.currentIndex != 0) {
          shell.goBranch(0);
        }
      }
      AttendancePopupManager.showAttendancePopup(context);
      return;
    }

    final branchIndex = branchIndexForItem(isParent: isParent, item: item);
    if (branchIndex == null) return;

    final shell = appNavigationShell(context);
    if (shell != null) {
      if (branchIndex == shell.currentIndex) {
        // Already on this branch. If the user is on a sub-route or has pushed routes
        // on top of this branch's nested navigator, pop them all to return to the root.
        final router = GoRouter.of(context);
        final navigator = Navigator.of(context);
        while (navigator.canPop()) {
          navigator.pop();
        }
        router.go(branchRootPaths[branchIndex]);
        return;
      }
      // Different branch → IndexedStack swap; state of the outgoing branch is
      // kept alive, the incoming one shows instantly (no transition animation).
      shell.goBranch(branchIndex);
    } else {
      // Outside the shell — either an auth screen that still shows the bar, or a
      // screen pushed ABOVE the shell on the ROOT navigator (e.g. the Staff /
      // Student Attendance profile opened from the Attendance popup). In that
      // case the shell is hidden underneath, so a bare `go` changes the location
      // but the pushed screen still covers it — the tap looks dead. Pop the
      // pushed route(s) back into the shell first, then route to the tab root.
      final router = GoRouter.of(context);
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      // Pop the pushed screen (not `while` — that could over-pop the shell if a
      // login route sits beneath it); one pop returns to the shell.
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      router.go(branchRootPaths[branchIndex]);
    }
  }

  String _iconFor(BottomNavigationItem item) {
    switch (item) {
      case BottomNavigationItem.dashboard:
        return MediaRes.dashboardIcon;
      case BottomNavigationItem.attendance:
        return MediaRes.attendanceIcon;
      case BottomNavigationItem.classrooms:
        return MediaRes.classroomIcon;
      case BottomNavigationItem.activities:
        return MediaRes.activitesIcon;
      case BottomNavigationItem.communication:
        return MediaRes.communicationIcon;
      case BottomNavigationItem.billing:
        return MediaRes.billing_drawer_icon;
    }
  }

  String _labelFor(BottomNavigationItem item, bool isParent) {
    switch (item) {
      case BottomNavigationItem.dashboard:
        return 'Dashboard';
      case BottomNavigationItem.attendance:
        return 'Attendance';
      case BottomNavigationItem.classrooms:
        return 'Classrooms';
      case BottomNavigationItem.activities:
        return 'Activities';
      case BottomNavigationItem.communication:
        return 'Messages';
      case BottomNavigationItem.billing:
        return 'Billing';
    }
  }

  Widget _buildNavItem({
    required BottomNavigationItem item,
    required BottomNavigationItem? activeItem,
    required bool isParent,
    required _NavSizes sizes,
    int badgeCount = 0,
  }) {
    final bool isActive = activeItem == item;

    return Expanded(
      child: InkWell(
        onTap: () => context.read<BottomNavigationCubit>().selectItem(item),
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    _iconFor(item),
                    height: sizes.iconSize,
                    colorFilter: isActive
                        ? const ColorFilter.mode(Colors.white, BlendMode.dstIn)
                        : null,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -5,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _labelFor(item, isParent),
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
    final navState = context.watch<BottomNavigationCubit>().state;
    final isParent = navState.isParent;

    final activeItem = widget.highlightNone
        ? null
        : (widget.activeItemOverride ?? navState.selectedItem);

    final sizes = _NavSizes(context);
    final slotOrder = isParent ? _parentSlotOrder : _staffAdminSlotOrder;

    // Bug 1 fix: SafeArea removed entirely. We handle bottom inset manually
    // via mq.viewPadding.bottom inside _NavSizes.barPadding, which works
    // correctly for BOTH iPhone notch/home-bar AND Android gesture nav.
    return BlocListener<BottomNavigationCubit, BottomNavigationState>(
      listenWhen: (previous, current) =>
          current.pendingNavigationItem != null &&
          current.pendingNavigationSeq != previous.pendingNavigationSeq,
      listener: (context, state) {
        _performNavigation(
          context,
          state.isParent,
          state.pendingNavigationItem!,
        );
      },
      child: ClipRRect(
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
            children: slotOrder.map((item) {
              if (!navState.visibleItems.contains(item)) {
                return _hiddenNavSlot();
              }
              return _buildNavItem(
                item: item,
                activeItem: activeItem,
                isParent: isParent,
                sizes: sizes,
                badgeCount: item == BottomNavigationItem.communication
                    ? navState.unreadBadgeCount
                    : 0,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
