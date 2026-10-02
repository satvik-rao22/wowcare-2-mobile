import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/cache/session_local_cache_wiper.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/activity_feed_invalidation.dart';
import 'package:wowcare/core/utils/cache_manager.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/presentation/features/classroom/view/classroom_tab_cards/classroom_students_tab_card.dart';
import 'package:wowcare/core/events/scheduling_events.dart';

/// Clears every cache layer so a school switch OR persona switch starts from
/// a clean slate everywhere — not just the module the user happens to be
/// looking at:
///  1. Persisted `*_cache_*` StorageService entries (repository caches),
///     keeping the auth/session login cache which isn't school/persona-scoped.
///  2. Non-prefs caches — image cache, Isar messaging/conversation
///     collections (both the legacy and v2 schemas), in-flight staff request
///     caches (via [SessionLocalCacheWiper]).
///  3. Process-wide in-memory caches / invalidation gates that open screens
///     listen to (students attendance status, scheduling, activity feed).
///
/// Single source of truth for this sequence — the school-switch path (drawer
/// picker, FCM-driven switch) and the persona-switch path both call this
/// instead of keeping their own copies, so a cache added to one module is
/// covered for both switch kinds automatically.
///
/// Each step is isolated so one failure never blocks the rest of the switch.
/// Callers are responsible for firing [SchoolSwitchEvents.notifySwitched]
/// afterwards so long-lived branch screens (kept alive in the shell's
/// IndexedStack) reload against the now-empty caches.
Future<void> clearAllCachesForContextSwitch(StorageService storage) async {
  try {
    await CacheManager(storage).clearAllStandardCaches(
      protectedKeys: <String>{
        StorageKeys.loginCacheKey,
        StorageKeys.loginCacheTimestamp,
      },
    );
  } catch (_) {}

  try {
    await serviceLocator<SessionLocalCacheWiper>().wipe();
  } catch (_) {}

  try {
    clearClassroomStudentsAttendanceCache();
  } catch (_) {}

  try {
    SchedulingEvents.notifyChanged();
  } catch (_) {}

  try {
    await ActivityFeedInvalidation.invalidate(storage);
  } catch (_) {}
}
