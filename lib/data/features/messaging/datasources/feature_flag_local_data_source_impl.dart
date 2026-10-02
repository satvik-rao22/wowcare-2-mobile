import '../../../../core/feature_flags/feature_flag_names.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/app_time.dart';
import 'feature_flag_local_data_source.dart';

/// Implementation of FeatureFlagLocalDataSource over the app's [StorageService].
/// Feature flags are stored with key prefix 'feature_flag_' for easy identification.
class FeatureFlagLocalDataSourceImpl implements FeatureFlagLocalDataSource {
  final StorageService _storage;

  const FeatureFlagLocalDataSourceImpl(this._storage);

  /// Storage key prefix for feature flags
  static const String _flagPrefix = 'feature_flag_';

  /// Storage key for last sync timestamp (for future backend sync)
  static const String _lastSyncKey = 'feature_flags_last_sync';

  /// Generate storage key for a feature flag
  static String _buildKey(String flagName) => '$_flagPrefix$flagName';

  @override
  Future<bool> isFeatureEnabled(String flagName) async {
    if (!FeatureFlagNames.isValidFlag(flagName)) {
      throw ArgumentError('Invalid feature flag: $flagName');
    }

    final key = _buildKey(flagName);
    final stored = await _storage.getBool(key);

    // Return stored value if set, otherwise return default
    return stored ?? FeatureFlagNames.getDefault(flagName);
  }

  @override
  Future<void> setFeatureEnabled(String flagName, bool enabled) async {
    if (!FeatureFlagNames.isValidFlag(flagName)) {
      throw ArgumentError('Invalid feature flag: $flagName');
    }

    final key = _buildKey(flagName);
    await _storage.saveBool(key, enabled);

    // Update last sync time
    await _storage.saveInt(
      _lastSyncKey,
      AppTime.nowUtc().millisecondsSinceEpoch,
    );
  }

  @override
  Future<Map<String, bool>> getAllFlags() async {
    final flags = <String, bool>{};

    for (final flagName in FeatureFlagNames.allFlags) {
      final enabled = await isFeatureEnabled(flagName);
      flags[flagName] = enabled;
    }

    return flags;
  }

  @override
  Future<void> clearAllFlags() async {
    for (final flagName in FeatureFlagNames.allFlags) {
      final key = _buildKey(flagName);
      await _storage.remove(key);
    }

    // Clear sync timestamp
    await _storage.remove(_lastSyncKey);
  }

  @override
  Future<bool> isFlagEnabledForContext({
    required String flagName,
    String? organizationCode,
    String? schoolCode,
    String? userId,
  }) async {
    // For now, feature flags are global (same for all users/orgs/schools)
    // In future, this can be enhanced to support per-org or per-user flags
    // by storing under different keys:
    //   'feature_flag_{flagName}_{organizationCode}_{schoolCode}_{userId}'

    return isFeatureEnabled(flagName);
  }

  /// Get when flags were last synced from backend.
  /// Returns null if never synced.
  Future<DateTime?> getLastSyncTime() async {
    final timestamp = await _storage.getInt(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
}
