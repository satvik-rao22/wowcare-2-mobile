import 'package:flutter/foundation.dart';

/// Global signal fired after any staff-side mutation that invalidates the
/// scheduling screens' cached staff list — profile edits, schedule edits,
/// status changes, and org/school context switches.
///
/// `SchedulingScreen` and `StaffSchedulingScreen` listen to [tick] and compare
/// it against the last revision they handled, then silently re-pull the staff
/// cache on their next frame — no UI loader is shown. Publishers don't need to
/// know who is listening; just call [notifyChanged] after a successful
/// mutation.
///
/// Lives in `core/events/` rather than
/// `presentation/features/scheduling/utils/`, where it was a process-wide bus
/// declared inside one feature — `core/utils/context_switch_cache_cleaner.dart`
/// publishes to it, so core depended on presentation to fire it.
///
/// NOTE: five more buses of exactly this shape sit in `core/utils/*_events.dart`
/// (`AttendanceEvents`, `BillingEvents`, `NotificationEvents`,
/// `SchoolSwitchEvents`, `TabVisibilityEvents`). They belong here too — this is
/// the first one moved into the purpose-named folder, not a second home for
/// them. Consolidating the rest touches several features and is its own pass.
class SchedulingEvents {
  SchedulingEvents._();

  /// Bumped once per successful staff-side mutation.
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);

  /// Fire after a staff profile / schedule / status mutation succeeds.
  static void notifyChanged() => tick.value++;
}
