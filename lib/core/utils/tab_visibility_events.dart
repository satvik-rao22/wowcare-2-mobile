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
    activeBranchIndex.value = branchIndex;
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
