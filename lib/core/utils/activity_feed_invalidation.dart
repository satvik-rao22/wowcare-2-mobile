import 'dart:async';

import 'package:wowcare/core/storage/storage_service.dart';

import 'storage_keys.dart';

/// Bumps a global revision and notifies listeners when activity data changes
/// so feed caches are stale and open tabs can refetch.
class ActivityFeedInvalidation {
  ActivityFeedInvalidation._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  /// Subscribe in activity feed tabs to call `_loadDailyFeed` / `_loadRangeFeed` with `refresh: true`.
  static Stream<void> get onInvalidated => _controller.stream;

  static Future<void> invalidate(StorageService storage) async {
    final v = await storage.getInt(StorageKeys.activityFeedCacheRevision) ?? 0;
    await storage.saveInt(StorageKeys.activityFeedCacheRevision, v + 1);
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  /// Revision stored alongside each feed cache entry; must match [currentRevision] to hydrate.
  static Future<int> currentRevision(StorageService storage) async =>
      await storage.getInt(StorageKeys.activityFeedCacheRevision) ?? 0;
}
