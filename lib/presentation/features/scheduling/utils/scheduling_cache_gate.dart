import 'package:flutter/foundation.dart';

/// Process-wide invalidation signal that lets staff-side edits poke the
/// classroom + staff scheduling screens. When [invalidate] is called the
/// notifier bumps; both [SchedulingScreen] and [StaffSchedulingScreen]
/// listen and silently refresh only the staff list cache on their next
/// frame — no UI loader is shown.
///
/// Callers don't need to know who's listening — just call [invalidate]
/// after any successful staff profile / schedule / status mutation.
class SchedulingCacheGate {
  SchedulingCacheGate._();

  /// Increments every time staff-side data changes. Listeners compare the
  /// last value they handled against [revision.value] to decide whether to
  /// re-pull the staff cache.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void invalidate() {
    revision.value++;
  }
}
