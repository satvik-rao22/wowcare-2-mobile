/// Abstract interface for feature flag storage.
/// Implementations use local storage (SharedPreferences, Secure Storage, etc.)
abstract class FeatureFlagLocalDataSource {
  /// Check if a feature flag is enabled for the current user/org/school.
  /// Returns the default value if flag has never been set.
  ///
  /// Example:
  ///   isFeatureEnabled('bulkMessaging') → true/false
  Future<bool> isFeatureEnabled(String flagName);

  /// Set feature flag enabled/disabled state.
  /// Persists to local storage immediately.
  ///
  /// Throws [ArgumentError] if flagName is not valid.
  Future<void> setFeatureEnabled(String flagName, bool enabled);

  /// Get all feature flags and their states as a map.
  /// Used on app startup to load all flags at once.
  ///
  /// Returns: Map<flagName, enabled>
  /// Example:
  ///   {
  ///     'bulkMessaging': false,
  ///     'realtimeMessaging': true,
  ///   }
  Future<Map<String, bool>> getAllFlags();

  /// Clear all feature flag overrides and revert to defaults.
  /// Useful for testing or debugging.
  Future<void> clearAllFlags();

  /// Get flag state scoped to current user/org/school context.
  /// This allows different flag states per organization if needed in future.
  ///
  /// For now, flags are global per app installation, but this method
  /// supports future multi-tenant flag scoping.
  Future<bool> isFlagEnabledForContext({
    required String flagName,
    String? organizationCode,
    String? schoolCode,
    String? userId,
  });
}
