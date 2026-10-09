import 'package:flutter/widgets.dart';
import 'package:wowcare/core/observability/app_events.dart';

/// Process-wide signal fired whenever the active organisation/school changes
/// (drawer school picker or an FCM-driven switch).
///
/// The app shell keeps each bottom-nav branch (Dashboard, Classroom, Activity,
/// Messaging, Billing) alive in an `IndexedStack`, so those root screens are
/// NOT rebuilt when the school changes — they would keep showing the previous
/// school's data until a manual pull-to-refresh. Long-lived screens listen to
/// [epoch] and reload themselves (and reset any per-school selection) when it
/// ticks, so a switch lands on fresh data everywhere with no user action.
///
/// Mirrors the existing `BillingEvents` / `ProfilePhotoUploadEvents` pattern.
class SchoolSwitchEvents {
  SchoolSwitchEvents._();

  /// Increments once per completed school switch. Screens compare against the
  /// value they last handled so a rebuild mid-switch doesn't double-reload.
  static final ValueNotifier<int> epoch = ValueNotifier<int>(0);

  /// Call AFTER the new selection is persisted and caches are cleared, so
  /// listeners reload against the new context with empty caches.
  ///
  /// Every switch path ends here, so this is also where the switch is logged.
  static void notifySwitched() {
    AppEvents.succeeded(AppEvent.authSchoolSwitch);
    epoch.value++;
  }
}

/// Drop-in mixin for a long-lived [State] that must reload when the active
/// school changes. Implement [onSchoolSwitched] to re-fetch fresh data and
/// reset any per-school selection. Safe against duplicate fires (tracks the
/// last-handled epoch) and unmount.
mixin SchoolSwitchReloadMixin<T extends StatefulWidget> on State<T> {
  int _lastSchoolEpoch = SchoolSwitchEvents.epoch.value;

  /// Called once per school switch, after [SchoolSwitchEvents.notifySwitched].
  void onSchoolSwitched();

  void _handleSchoolSwitch() {
    if (!mounted) return;
    if (SchoolSwitchEvents.epoch.value == _lastSchoolEpoch) return;
    _lastSchoolEpoch = SchoolSwitchEvents.epoch.value;
    onSchoolSwitched();
  }

  @override
  void initState() {
    super.initState();
    SchoolSwitchEvents.epoch.addListener(_handleSchoolSwitch);
  }

  @override
  void dispose() {
    SchoolSwitchEvents.epoch.removeListener(_handleSchoolSwitch);
    super.dispose();
  }
}
