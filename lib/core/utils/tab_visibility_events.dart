import 'package:flutter/widgets.dart';

/// Process-wide signal fired whenever the user switches TO a different
/// bottom-nav branch (`CustomNavigationBar._performNavigation`'s
/// `shell.goBranch(branchIndex)` tap handling).
///
/// The app shell keeps each bottom-nav branch (Dashboard, Classroom, Activity,
/// Messaging, Billing) alive in an `IndexedStack`, so switching tabs is a pure
/// visibility swap — the outgoing branch's entire widget tree/State persists,
/// the incoming one is simply shown. That means a tab's `initState()` (and
/// any `BlocProvider.create` tied to it) only ever runs ONCE per app
/// session: the very first time that tab is opened. Every later switch back
/// to it shows whatever was last loaded, however stale, because nothing
/// tells it to reload — this is the tab-switch equivalent of
/// [SchoolSwitchEvents] below, for the same underlying IndexedStack reason.
///
/// Mirrors the existing `SchoolSwitchEvents` / `BillingEvents` pattern.
class TabVisibilityEvents {
  TabVisibilityEvents._();

  /// The branch index that just became active, or null before the first
  /// tab switch this session (the very first tab shown loads fresh anyway,
  /// via its own initState — this only covers later revisits).
  static final ValueNotifier<int?> activeBranchIndex = ValueNotifier<int?>(
    null,
  );

  /// Call from the bottom-nav's tap handler right after `shell.goBranch(...)`.
  static void notifyBranchActivated(int branchIndex) {
    // A ValueNotifier ignores a write of the value it already holds, so a
    // re-tap of the active tab (or popping back to it from a drill-down, where
    // the active branch never changed) would never reach the listeners. Clear
    // first so every call is a real change; listeners ignore the null.
    if (activeBranchIndex.value == branchIndex) {
      activeBranchIndex.value = null;
    }
    activeBranchIndex.value = branchIndex;
  }

  /// Index of the shell branch currently on screen, kept up to date by the
  /// shell builder in app_router.dart.
  static int currentShellIndex = 0;
}

/// Signals that the Dashboard is visible again after a full-page route that
/// was sitting on top of it is popped (Android back / app-bar back from a
/// drill-down such as Billing, Staff or Reports, or from a screen pushed over
/// the shell). Popping doesn't change the active branch, so nothing else tells
/// the kept-alive Dashboard to reload.
///
/// Attach one to the Dashboard branch's navigator (`dashboardOnly: false`) and
/// one to the root navigator (`dashboardOnly: true`, which only fires while the
/// shell is showing the Dashboard branch).
class DashboardReturnObserver extends NavigatorObserver {
  DashboardReturnObserver({required this.dashboardOnly});

  final bool dashboardOnly;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Dialogs / bottom sheets are not PageRoutes; only a landing on the
    // navigator's first route means we are back on the Dashboard itself.
    if (route is! PageRoute ||
        previousRoute == null ||
        !previousRoute.isFirst) {
      return;
    }
    if (dashboardOnly && TabVisibilityEvents.currentShellIndex != 0) return;
    TabVisibilityEvents.notifyBranchActivated(0);
  }
}

/// Drop-in mixin for a bottom-nav tab screen's [State] that must reload every
/// time the user switches back to it. Implement [tabBranchIndex] (this tab's
/// position in app_router.dart's shell `branches` list) and
/// [onTabBecameVisible] (the same "load fresh data" call already used for
/// pull-to-refresh). Safe against duplicate fires and unmount.
mixin TabBecameVisibleMixin<T extends StatefulWidget> on State<T> {
  /// This tab's own index within app_router.dart's shell `branches` list
  /// (0 = Dashboard, 1 = Classroom, 2 = Activity Feed, 3 = Messaging,
  /// 4 = Parent Billing, as currently ordered there).
  int get tabBranchIndex;

  /// Called once per switch INTO this tab becoming the active branch.
  void onTabBecameVisible();

  void _handleBranchActivated() {
    if (!mounted) return;
    if (TabVisibilityEvents.activeBranchIndex.value != tabBranchIndex) return;
    onTabBecameVisible();
  }

  @override
  void initState() {
    super.initState();
    TabVisibilityEvents.activeBranchIndex.addListener(_handleBranchActivated);
  }

  @override
  void dispose() {
    TabVisibilityEvents.activeBranchIndex.removeListener(
      _handleBranchActivated,
    );
    super.dispose();
  }
}
