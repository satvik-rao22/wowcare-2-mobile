import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_popup.dart';
import 'package:wowcare/shared/common/app/cubits/bottom_navigation_cubit.dart';
import 'package:wowcare/shared/common/model/bottom_navigation_item.dart';
import 'package:wowcare/core/utils/tab_visibility_events.dart';
import 'package:wowcare/src/app_router.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_haptics.dart';

// ---------------------------------------------------------------------------
// Responsive sizing — fixed for Bug 3 (iPad split-screen)
// Uses shortestSide to detect a true tablet regardless of split-view width.
// ---------------------------------------------------------------------------
class _NavSizes {
  _NavSizes(BuildContext context) {
    // Aspect reads (sizeOf / viewPaddingOf), not MediaQuery.of: a full read
    // subscribes to viewInsets too, which rebuilt this bar on every frame of
    // a keyboard animation for nothing it uses.
    // shortestSide is always the physical short dimension even in landscape.
    // ≥600 on shortestSide = a genuine tablet, not an iPhone in landscape.
    final shortest = MediaQuery.sizeOf(context).shortestSide;
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

    // The pink squircle behind an active glyph. 38x38 round a 22px glyph on
    // a phone, which is the design's `.tabbar__glyph`, and it grows with the
    // glyph on a tablet so the ring of colour round it stays the same width.
    activeTileSize = iconSize + 16;

    // Bug 2 fix — Samsung & all Android gesture-nav:
    // viewPadding is the raw inset before system consumption; it reports the
    // correct bottom inset in every Android navigation mode (gesture, 2-button,
    // 3-button) AND on iOS home-bar devices.
    // DO NOT use padding.bottom — it can be 0 in gesture mode on Samsung.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
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
  late final double activeTileSize;
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

  /// Height this bar renders at for the given [context]'s [MediaQuery],
  /// including the bottom system inset it absorbs (see [_NavSizes.barPadding]).
  ///
  /// Use this when a screen has to reserve space for the bar *before* it has
  /// been laid out: [navBarHeight] only reports a real value once [navBarKey]
  /// is attached to a mounted bar, and it deliberately is not — the shell keeps
  /// every branch alive at once, so a shared [GlobalKey] would collide.
  static double estimatedHeight(BuildContext context) {
    final sizes = _NavSizes(context);
    // Icon, a 3px gap, then a single label line (Inter's default line height).
    const double labelLineHeightFactor = 1.4;
    return sizes.barPadding.top +
        sizes.barPadding.bottom +
        (sizes.itemPaddingV * 2) +
        sizes.iconSize +
        3 +
        (sizes.fontSize * labelLineHeightFactor);
  }

  @override
  _CustomNavigationBarState createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar>
    with SingleTickerProviderStateMixin {
  final GlobalKey _containerKey = GlobalKey();

  // Drives repaints while the shared droplet flight is in the air. The
  // position itself lives in [_DropletFlight], not here: see that class.
  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: AppMotion.droplet,
    value: 1,
  );
  _NavSizes? _dropSizes;
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
      // No _ShellScope ancestor — this screen is one of the top-level
      // routes registered OUTSIDE the StatefulShellRoute (e.g. /admin-chat,
      // openConversation, the notification-deep-link routes), rendered by
      // the root navigator as a sibling of the shell rather than one of its
      // branches. Defaulting to Dashboard here used to actively claim
      // Dashboard was active while viewing a completely different screen —
      // same mistake the branch-0 drill-down case below already avoids.
      // Screens that DO conceptually belong to a tab (e.g. AdminChatHostScreen
      // -> Communication) should pass activeItemOverride explicitly, same
      // pattern as StudentAttendanceProfile does for Attendance.
      item = null;
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
    // The repaint clock and the flight's clock can drift by a frame; keep
    // ticking until the drop has actually landed.
    _drop.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed &&
          mounted &&
          _DropletFlight.inFlight) {
        _drop.forward(from: _DropletFlight.progress);
      }
    });
  }

  @override
  void dispose() {
    _routeInfoProvider?.removeListener(_onRouteChanged);
    _drop.dispose();
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
        // Re-tapping the already-active tab is also a reasonable "give me
        // fresh data" signal (common app convention), and costs nothing extra
        // here since the branch is already visible.
        TabVisibilityEvents.notifyBranchActivated(branchIndex);
        return;
      }
      // Different branch → IndexedStack swap; state of the outgoing branch is
      // kept alive, the incoming one shows instantly (no transition animation).
      shell.goBranch(branchIndex);
      // The incoming branch's initState()/BlocProvider.create already ran
      // once (kept alive, not rebuilt) — this is what tells it to reload
      // fresh data now instead of showing whatever it last had. See
      // TabVisibilityEvents' doc comment for why this is needed at all.
      TabVisibilityEvents.notifyBranchActivated(branchIndex);
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
      // Same as the IndexedStack-swap branch above — this is the path a tap
      // takes when returning from a screen pushed ABOVE the shell (e.g. the
      // Staff/Student Attendance flow opened from the Attendance popup), so
      // it needs the same "you're visible again, reload" signal — this was
      // the actual gap: switching tabs directly already worked, but coming
      // BACK to a tab from one of these pushed screens did not.
      TabVisibilityEvents.notifyBranchActivated(branchIndex);
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

  /// One slot. The base row ([onDroplet] false) is the live, tappable one:
  /// navy glyph, and a label that turns pink as the droplet covers the slot.
  /// The droplet row ([onDroplet] true) is the same slot with a warm-white
  /// glyph and no label; it is drawn clipped to the droplet, so a glyph turns
  /// white exactly where the pink passes under it and nowhere else.
  Widget _buildNavItem({
    required BottomNavigationItem item,
    required BottomNavigationItem? activeItem,
    required bool isParent,
    required _NavSizes sizes,
    required bool onDroplet,
    double coverage = 0,
    int badgeCount = 0,
  }) {
    final Widget slot = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: sizes.itemPaddingH,
        vertical: sizes.itemPaddingV,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: sizes.activeTileSize,
                height: sizes.activeTileSize,
                child: Center(
                  child: AppIcon(
                    _iconFor(item),
                    height: sizes.iconSize,
                    tone: onDroplet ? IconTone.onBrand : IconTone.standard,
                  ),
                ),
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
                      color: AppPalette.brand,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppPalette.textOnDark,
                        width: 1.2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: AppPalette.textOnDark,
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
                color: onDroplet
                    ? AppColors.transparentColor
                    : Color.lerp(
                        AppPalette.textSecondary,
                        AppPalette.brand,
                        coverage,
                      ),
                fontFamily: AppFonts.body,
                fontSize: sizes.fontSize,
                fontWeight: coverage > 0.5
                    ? AppTypeScale.bold
                    : AppTypeScale.semiBold,
              ),
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );

    if (onDroplet) return Expanded(child: slot);
    return Expanded(
      child: InkWell(
        onTap: () {
          if (item != activeItem) AppHaptics.select();
          context.read<BottomNavigationCubit>().selectItem(item);
        },
        // The droplet is the feedback; a grey splash under it only muddies it.
        splashColor: AppColors.transparentColor,
        highlightColor: AppColors.transparentColor,
        child: slot,
      ),
    );
  }

  Widget _hiddenNavSlot() => const Expanded(child: SizedBox.shrink());

  Widget _buildRow({
    required List<BottomNavigationItem> slotOrder,
    required BottomNavigationState navState,
    required BottomNavigationItem? activeItem,
    required _NavSizes sizes,
    required bool onDroplet,
    _Droplet? droplet,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < slotOrder.length; i++)
          if (!navState.visibleItems.contains(slotOrder[i]))
            _hiddenNavSlot()
          else
            _buildNavItem(
              item: slotOrder[i],
              activeItem: activeItem,
              isParent: navState.isParent,
              sizes: sizes,
              onDroplet: onDroplet,
              coverage: droplet?.coverage(i) ?? 0,
              badgeCount: slotOrder[i] == BottomNavigationItem.communication
                  ? navState.unreadBadgeCount
                  : 0,
            ),
      ],
    );
  }

  _Droplet _dropletNow(double slotWidth) => _Droplet(
    t: _DropletFlight.progress,
    from: _DropletFlight.from,
    to: _DropletFlight.to,
    slotWidth: slotWidth,
    tile: _dropSizes!.activeTileSize,
    top: _dropSizes!.itemPaddingV,
    radius: _dropSizes!.activeRadius,
  );

  /// Points the shared droplet at this bar's active slot, if this bar is the
  /// one on screen, and keeps this bar repainting until the flight lands.
  void _syncDroplet(int? slot, {required bool visible}) {
    if (!visible || _DropletFlight.slotWidth == 0) return;
    _DropletFlight.flyTo(slot?.toDouble(), _dropletNow);
    if (_DropletFlight.inFlight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_DropletFlight.inFlight) return;
        // Linear and in step with the flight's own clock, so a bar that
        // appears mid-flight picks the animation up where it is.
        _drop.forward(from: _DropletFlight.progress);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navState = context.watch<BottomNavigationCubit>().state;
    final isParent = navState.isParent;

    final activeItem = widget.highlightNone
        ? null
        : (widget.activeItemOverride ?? navState.selectedItem);

    final sizes = _NavSizes(context);
    final slotOrder = isParent ? _parentSlotOrder : _staffAdminSlotOrder;
    _dropSizes = sizes;

    final int index = activeItem == null ? -1 : slotOrder.indexOf(activeItem);
    final int? activeSlot =
        index >= 0 && navState.visibleItems.contains(activeItem) ? index : null;
    // Depending on TickerMode also rebuilds this bar the moment it comes
    // back on screen (a tab switch, or a route above it popping).
    final bool onScreen = TickerMode.valuesOf(context).enabled;
    _syncDroplet(activeSlot, visible: onScreen);

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
          decoration: AppSurfaces.bar(topRadius: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double slotWidth = constraints.maxWidth / slotOrder.length;
              final bool firstLayout = _DropletFlight.slotWidth == 0;
              _DropletFlight.slotWidth = slotWidth;
              // The very first bar laid out could not aim the drop in build
              // (there was no width to measure it against yet); aim it now.
              if (firstLayout) _syncDroplet(activeSlot, visible: onScreen);
              _Droplet droplet() => _dropletNow(slotWidth);
              return Stack(
                children: [
                  AnimatedBuilder(
                    animation: _drop,
                    builder: (context, _) => _buildRow(
                      slotOrder: slotOrder,
                      navState: navState,
                      activeItem: activeItem,
                      sizes: sizes,
                      onDroplet: false,
                      droplet: droplet(),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _DropletPainter(droplet, repaint: _drop),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipPath(
                        clipper: _DropletClipper(droplet, reclip: _drop),
                        child: _buildRow(
                          slotOrder: slotOrder,
                          navState: navState,
                          activeItem: activeItem,
                          sizes: sizes,
                          onDroplet: true,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The one droplet flight the whole app shares.
///
/// The shell keeps a bar alive per branch, and a pushed screen brings its
/// own, so after a tab switch the bar on screen is usually a different
/// instance from the bar that was tapped. If each bar owned its droplet, the
/// new one would just appear, parked on its own slot. Instead every visible
/// bar points this single flight at its active slot and paints it by the
/// clock, so whichever bar is showing draws the same drop in the same place,
/// and a switch reads as one drop moving across the screen.
abstract final class _DropletFlight {
  static double? from;
  static double? to;
  static Duration? _startedAt;
  static bool _aimed = false;
  static final Stopwatch _clock = Stopwatch()..start();

  /// Every bar in the app is the same width, so the last one laid out
  /// speaks for all of them.
  static double slotWidth = 0;

  static double get progress {
    final Duration? start = _startedAt;
    if (start == null) return 1;
    final double t =
        (_clock.elapsed - start).inMicroseconds /
        AppMotion.droplet.inMicroseconds;
    return t.clamp(0, 1);
  }

  static bool get inFlight => progress < 1;

  /// Sends the drop to [target] (null: nothing active, so it evaporates),
  /// starting from wherever it is now, mid-flight included.
  static void flyTo(double? target, _Droplet Function(double) now) {
    if (_aimed && target == to) return;
    double? start = to;
    if (_aimed && inFlight) {
      final RRect? body = now(slotWidth).body;
      start = body == null ? null : body.center.dx / slotWidth - 0.5;
    }
    _aimed = true;
    from = start;
    to = target;
    _startedAt = _clock.elapsed;
  }
}

/// The active tab's droplet: one pink squircle that travels between slots
/// like a drop of liquid.
///
/// Its leading edge leaves first and its trailing edge catches up late and
/// overshoots, so in flight it stretches into a capsule (and thins, keeping
/// its volume) and on landing it squashes, bulges and settles. A ring
/// splashes out of the slot it lands in. With no active slot the drop
/// evaporates, and it falls back in with a wobble when one returns.
///
/// Positions are slot indices ([from], [to]); the drop's rest shape is the
/// same [AppSurfaces.navActive] squircle a static active tab would show.
class _Droplet {
  const _Droplet({
    required this.t,
    required this.from,
    required this.to,
    required this.slotWidth,
    required this.tile,
    required this.top,
    required this.radius,
  });

  final double t;
  final double? from;
  final double? to;
  final double slotWidth;
  final double tile;
  final double top;
  final double radius;

  double _centreX(double slot) => (slot + 0.5) * slotWidth;

  double get _centreY => top + tile / 2;

  RRect _square(double cx, double size, double r) => RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(cx, _centreY), width: size, height: size),
    Radius.circular(r),
  );

  /// The drop itself, or null when there is nothing to draw.
  RRect? get body {
    final double? from = this.from;
    final double? to = this.to;
    if (from == null && to == null) return null;

    if (from == null || to == null) {
      // Falling in, or evaporating, in place.
      final double s = to != null
          ? Curves.elasticOut.transform(t)
          : 1 - Curves.easeInCubic.transform(t);
      if (s <= 0.01) return null;
      return _square(_centreX((to ?? from)!), tile * s, radius * s);
    }

    final double x0 = _centreX(from);
    final double x1 = _centreX(to);
    final double dir = (x1 - x0).sign;
    if (dir == 0) return _square(x1, tile, radius);

    final double half = tile / 2;
    // The front leaves at once and arrives early; the back waits, then
    // hurries after it. Between them the drop stretches into a capsule.
    final double lead = Curves.easeOutCubic.transform((t / 0.62).clamp(0, 1));
    final double trail = Curves.easeInOutCubic.transform(
      ((t - 0.18) / 0.6).clamp(0, 1),
    );
    final double front = lerpDouble(x0, x1, lead)! + dir * half;
    double back = lerpDouble(x0, x1, trail)! - dir * half;
    // Never stretch past a slot and a bit, however far the jump.
    final double maxLength = tile + slotWidth * 1.1;
    if ((front - back).abs() > maxLength) back = front - dir * maxLength;

    if (t >= 0.78) {
      // Landed: a centred jelly wobble on the slot, damped to rest. Sized to
      // the tile, not to the distance travelled, so a long jump lands no
      // harder than a short one.
      final double p = (t - 0.78) / 0.22;
      final double wobble =
          math.sin(p * math.pi * 2.5) * math.pow(1 - p, 2) * 0.16;
      return RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x1, _centreY),
          width: tile * (1 - wobble),
          height: tile * (1 + wobble * 0.8),
        ),
        Radius.circular(radius),
      );
    }

    final double left = math.min(front, back);
    final double right = math.max(front, back);
    final double width = math.max(right - left, tile);
    final double ratio = width / tile;
    // Thin as it stretches: roughly constant volume.
    final double height = (tile / math.sqrt(ratio)).clamp(tile * 0.72, tile);
    // A stretched drop is a capsule; at rest it is the squircle again.
    final double r = lerpDouble(
      radius,
      height / 2,
      ((ratio - 1) / 0.5).clamp(0, 1),
    )!;
    return RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset((left + right) / 2, _centreY),
        width: width,
        height: height,
      ),
      Radius.circular(r),
    );
  }

  /// The ring that splashes out of the landing slot, fading as it spreads.
  ({RRect ring, double opacity, double stroke})? get splash {
    final double? to = this.to;
    if (to == null || from == to) return null;
    final double p = (t - 0.66) / 0.34;
    if (p <= 0 || p >= 1) return null;
    final double grow = tile * 0.42 * Curves.easeOutCubic.transform(p);
    return (
      ring: _square(_centreX(to), tile, radius).inflate(grow),
      opacity: 0.4 * (1 - p),
      stroke: 2.4 * (1 - p) + 0.6,
    );
  }

  /// How much of slot [i]'s glyph tile the drop covers, from 0 to 1. Only
  /// the slot it left and the slot it is heading for count: a label it merely
  /// passes over does not flash.
  double coverage(int i) {
    if (i != from?.round() && i != to?.round()) return 0;
    final RRect? b = body;
    if (b == null) return 0;
    final double left = _centreX(i.toDouble()) - tile / 2;
    final double overlap =
        math.min(left + tile, b.right) - math.max(left, b.left);
    return (overlap / tile).clamp(0, 1) * (b.height / tile).clamp(0, 1);
  }
}

class _DropletPainter extends CustomPainter {
  _DropletPainter(this.droplet, {required Listenable repaint})
    : super(repaint: repaint);

  final _Droplet Function() droplet;

  @override
  void paint(Canvas canvas, Size size) {
    final _Droplet d = droplet();
    final splash = d.splash;
    if (splash != null) {
      canvas.drawRRect(
        splash.ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = splash.stroke
          ..color = AppPalette.brand.withValues(alpha: splash.opacity),
      );
    }
    final RRect? body = d.body;
    if (body == null) return;
    // The drop is painted with the static active tab's own recipe, so its
    // colour and bevel follow the skin like everything else.
    final Rect rect = body.outerRect;
    final BoxPainter painter = AppSurfaces.navActive(
      radius: body.tlRadiusX,
    ).createBoxPainter();
    painter.paint(canvas, rect.topLeft, ImageConfiguration(size: rect.size));
    painter.dispose();
  }

  @override
  bool shouldRepaint(_DropletPainter oldDelegate) => true;
}

class _DropletClipper extends CustomClipper<Path> {
  _DropletClipper(this.droplet, {required Listenable reclip})
    : super(reclip: reclip);

  final _Droplet Function() droplet;

  @override
  Path getClip(Size size) {
    final RRect? body = droplet().body;
    return body == null ? Path() : (Path()..addRRect(body));
  }

  @override
  bool shouldReclip(_DropletClipper oldClipper) => true;
}
