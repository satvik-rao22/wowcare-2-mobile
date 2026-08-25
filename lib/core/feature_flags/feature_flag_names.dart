/// Feature flag constants for communication and other features.
/// This is the single source of truth for all feature flag names used across the app.
class FeatureFlagNames {
  // Master communication flag
  static const String communicationEnabled = 'communicationEnabled';

  // Communication sub-feature flags
  static const String parentMessagingEnabled = 'parentMessagingEnabled';
  static const String staffMessagingEnabled = 'staffMessagingEnabled';
  static const String adminChatEnabled = 'adminChatEnabled';
  static const String bulkMessagingEnabled = 'bulkMessagingEnabled';
  static const String privateModeEnabled = 'privateModeEnabled';
  static const String realtimeEnabled = 'realtimeEnabled';

  // All communication-related flags (for bulk operations)
  static const List<String> allFlags = [
    communicationEnabled,
    parentMessagingEnabled,
    staffMessagingEnabled,
    adminChatEnabled,
    bulkMessagingEnabled,
    privateModeEnabled,
    realtimeEnabled,
  ];

  // Default values (what state they're in if never set)
  static const Map<String, bool> defaults = {
    communicationEnabled: true, // Master enable/disable
    parentMessagingEnabled: true, // Room Chat + Admin Chat
    staffMessagingEnabled: true, // Staff direct messages
    adminChatEnabled: true, // Admin Chat specifically
    bulkMessagingEnabled: false, // Admin feature, off by default
    privateModeEnabled: true, // Private mode available
    realtimeEnabled: true, // Firebase realtime
  };

  /// Get default value for a flag
  static bool getDefault(String flagName) {
    return defaults[flagName] ?? false;
  }

  /// Check if a flag name is valid (exists in our registry)
  static bool isValidFlag(String flagName) {
    return allFlags.contains(flagName);
  }
}
