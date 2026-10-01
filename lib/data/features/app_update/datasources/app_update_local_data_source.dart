import 'package:wowcare/core/storage/storage_service.dart';

/// Remembers the last "Not now" on the optional update banner.
abstract interface class AppUpdateLocalDataSource {
  /// The dismissed build and when, or null if nothing was dismissed.
  Future<({int latestBuild, DateTime at})?> readDismissal();

  Future<void> saveDismissal({required int latestBuild, required DateTime at});
}

class AppUpdateLocalDataSourceImpl implements AppUpdateLocalDataSource {
  AppUpdateLocalDataSourceImpl(this._storage);

  final StorageService _storage;

  static const String _buildKey = 'app_update_dismissed_build';
  static const String _atKey = 'app_update_dismissed_at_ms';

  @override
  Future<({int latestBuild, DateTime at})?> readDismissal() async {
    final int? build = await _storage.getInt(_buildKey);
    final int? atMs = await _storage.getInt(_atKey);
    if (build == null || atMs == null) return null;
    return (latestBuild: build, at: DateTime.fromMillisecondsSinceEpoch(atMs));
  }

  @override
  Future<void> saveDismissal({
    required int latestBuild,
    required DateTime at,
  }) async {
    await _storage.saveInt(_buildKey, latestBuild);
    await _storage.saveInt(_atKey, at.millisecondsSinceEpoch);
  }
}
